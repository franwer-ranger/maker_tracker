# `mt check` (MT-79): los candidatos con los que contrastar una propuesta antes
# de construirla o proponerla. Busca en las decisiones (vigentes y sustituidas),
# las historias de cualquier estado (título, cuerpo y comentarios) y los
# fragmentos del brief. El juicio (¿lo contradice?, ¿ya está hecho?) es del
# agente: aquí solo se ordenan los candidatos por relevancia.
#
# Usa FTS5 de SQLite sobre un índice en memoria que se construye en cada
# consulta: un proyecto tiene cientos de documentos, no millones, y así no hay
# tabla que mantener al día ni migración, y el brief se lee por Project#brief
# (sea cual sea su almacenamiento).
class ProposalCheck
  LIMIT = 10
  MAX_TERMS = 40
  # Lo que pesa cada columna en bm25: el título manda, los comentarios menos.
  WEIGHTS = { title: 4.0, body: 1.0, extra: 0.5 }.freeze
  # Los fragmentos del brief que más chocan con una propuesta.
  KEY_SECTIONS = /principio|principle|fuera de alcance|out of scope|non.goals|no es\b/i
  # Por debajo de esta fracción de la puntuación del primero, no se devuelve:
  # pocos resultados y densos, no un volcado.
  CUTOFF = 0.15

  STOPWORDS = %w[
    a al algo algun alguna algunas alguno algunos ante antes asi aun bien cada como con contra cual cuando de del desde donde dos e el ella
    ellas ello ellos en entre era es esa esas ese eso esos esta estas este esto estos fue ha hace hacer haga hay la las le les lo los mas me
    mi mis mucho muy nada ni no nos nuestra nuestro o otra otro para pero poco por porque pueda puede que queremos quien quiero se sea ser si
    sin sobre solo son su sus tambien tan tanto te tener tiene todo todos tu un una unas uno unos y ya yo
    an and are as at be but by can do for from has have how i if in into is it its make not of on or so that the their them then there these
    this to want we what when where which with without would you your
  ].to_set.freeze

  Term = Data.define(:word, :stem)
  Document = Data.define(:kind, :record, :section, :title, :body, :extra, :boost)
  Result = Data.define(:document, :score, :matches, :fields, :excerpt)

  # El texto sin tildes y en minúscula, como lo tokeniza FTS5 (unicode61 remove_diacritics 2).
  def self.normalize(text) = text.to_s.unicode_normalize(:nfkd).gsub(/\p{Mn}/, "").downcase

  def self.words(text) = normalize(text).scan(/[\p{L}\p{N}]+/)

  # Una raíz para buscar por prefijo: quita plurales, género e infinitivo
  # («listas» → «list», «avisar» → «avis»), sin dejar menos de 4 letras.
  def self.stem(word)
    return word if word.match?(/\d/)

    cut = ->(w, suffix) { w.end_with?(suffix) && w.length - suffix.length >= 4 ? w.delete_suffix(suffix) : w }
    word = cut.(cut.(word, "es"), "s")
    word = %w[a e o].reduce(word) { |w, vowel| cut.(w, vowel) }
    %w[ar er ir].reduce(word) { |w, suffix| cut.(w, suffix) }
  end

  attr_reader :project, :text

  def initialize(project, text)
    @project = project
    @text = text.to_s
  end

  # Las palabras de la propuesta que cuentan, sin repetir raíz. El nombre del
  # proyecto no cuenta: sale en todas partes.
  def terms
    @terms ||= self.class.words(text).reject { ignored.include?(it) || (it.length < 2 && !it.match?(/\d/)) }
      .map { Term.new(it, self.class.stem(it)) }.uniq(&:stem).first(MAX_TERMS)
  end

  def results
    @results ||= terms.empty? ? [] : search
  end

  private

  def ignored = @ignored ||= STOPWORDS | self.class.words(project.name)

  def search
    docs = documents
    db = SQLite3::Database.new(":memory:")
    db.execute("CREATE VIRTUAL TABLE docs USING fts5(id UNINDEXED, title, body, extra, tokenize = 'unicode61 remove_diacritics 2')")
    db.transaction do
      docs.each_with_index { |doc, i| db.execute("INSERT INTO docs (id, title, body, extra) VALUES (?, ?, ?, ?)", [ i, doc.title, doc.body, doc.extra ]) }
    end
    rows = db.execute(<<~SQL, [ match_query ])
      SELECT id, bm25(docs, 0, #{WEIGHTS.values.join(', ')}), snippet(docs, 2, '', '', '…', 24), snippet(docs, 3, '', '', '…', 24)
      FROM docs WHERE docs MATCH ? ORDER BY 2 LIMIT #{LIMIT * 5}
    SQL
    ranked = rows.map { |id, rank, body_snippet, extra_snippet| result(docs[id], -rank, body_snippet, extra_snippet) }.sort_by { -it.score }
    top = ranked.first&.score.to_f
    ranked.select { it.score >= top * CUTOFF }.first(LIMIT)
  ensure
    db&.close
  end

  # "list"* OR "avis"* …: cada raíz por prefijo; bm25 premia lo que coincide en más.
  def match_query = terms.map { %("#{it.stem}"*) }.join(" OR ")

  # La relevancia de bm25, por el peso del tipo y por cuántas palabras de la
  # propuesta coinciden (una que coincide en todas va antes que una que repite una).
  def result(doc, relevance, body_snippet, extra_snippet)
    fields = { title: doc.title, body: doc.body, extra: doc.extra }.filter_map do |field, value|
      matched = matched_terms(value)
      [ field, matched ] if matched.any?
    end.to_h
    matches = terms.select { |term| fields.values.any? { it.include?(term) } }
    coverage = matches.size.fdiv(terms.size)
    excerpt = if fields[:body] then body_snippet
    elsif fields[:extra] then extra_snippet
    end
    Result.new(doc, relevance * doc.boost * (0.5 + coverage), matches.map(&:word), fields.keys, excerpt&.squish)
  end

  def matched_terms(text)
    words = self.class.words(text).uniq
    terms.select { |term| words.any? { it.start_with?(term.stem) } }
  end

  def documents = decision_documents + story_documents + brief_documents

  # Las sustituidas pesan algo menos: valen para saber por qué se cambió.
  def decision_documents
    project.decisions.includes(:actor, :story, :superseded_by).map do |decision|
      Document.new(:decision, decision, nil, decision.title, decision.body.to_s, "", decision.superseded_by ? 0.7 : 1.0)
    end
  end

  def story_documents
    project.stories.includes(:milestone, :comments).map do |story|
      body = story.body.to_s.gsub(/<!--.*?-->/m, "")
      Document.new(:story, story, nil, story.title, body, story.comments.map(&:body).join("\n\n"), 1.0)
    end
  end

  # Un fragmento por párrafo o por elemento de lista, con su sección.
  def brief_documents
    project.brief.to_s.gsub(/<!--.*?-->/m, "").split(/^(?=## )/).flat_map do |chunk|
      section = chunk[/\A## (.+)$/, 1]&.strip
      content = section ? chunk.sub(/\A## .+\n?/, "") : chunk.sub(/\A# .+\n?/, "")
      boost = section&.match?(KEY_SECTIONS) ? 1.5 : 1.0
      content.split(/\n\s*\n/).flat_map { it.split(/\n(?=[ ]{0,3}(?:[-*+]|\d+\.)\s)/) }.map(&:strip).reject(&:blank?).map do |fragment|
        Document.new(:brief, nil, section, section.to_s, fragment, "", boost)
      end
    end
  end
end
