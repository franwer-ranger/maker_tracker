# Una historia leída como documento (MT-104, «v1 · 4 · Historia»): su cuerpo
# partido en las piezas que pinta la UI.
#
# - `sentence`: el primer párrafo de «## Historia» (la historia en una frase).
# - `changes`: «## Qué cambia del producto», por capacidad (las de
#   `capabilities`). Una línea con `+` añade y con `=` no cambia; sin marca,
#   añade. Un `###` o una línea en negrita con el título o el slug de una
#   capacidad abre su bloque; con una sola capacidad, todo es suyo. Lo que no
#   cae en ninguna va en `changes_text`, para no perder texto.
# - `criteria`: «## Criterios de aceptación», en orden: las casillas
#   (`check`, con las líneas que las continúan), los subtítulos que las agrupan
#   (`heading`: un `###`, una línea en negrita o una línea corta sin punto
#   final) y el resto del texto (`paragraph`).
# - `out_of_scope`: «## Fuera de alcance» en una línea.
# - `context`: lo demás, en orden y tal cual (lo que se pliega).
#
# Nunca pierde texto: los títulos propios se reconocen sin mirar tildes ni
# mayúsculas, solo se usa la primera sección de cada uno (las repetidas van al
# contexto) y una sección que no se puede partir sin perder algo (código en los
# criterios, una intro en «Fuera de alcance») va entera al contexto como prosa.
# Lo mismo el preámbulo antes del primer `##` y los párrafos de «Historia» a
# partir del segundo. Solo se quitan los comentarios HTML, que no se ven.
class Story::Reading
  OWN = { "historia" => :sentence, "criterios de aceptacion" => :criteria,
          "que cambia del producto" => :changes, "fuera de alcance" => :out_of_scope }.freeze
  CHECKBOX = /\A\s*[-*+]\s+\[([ xX])\]\s+(.*)\z/
  BULLET = /\A\s*(?:[-*+]|\d+[.)])\s+/
  HEADING = /\A(?:###+\s+(.+)|\*\*([^*]+)\*\*:?)\z/
  FENCE = Page::Reading::FENCE
  FENCE_MARK = /(\d+)/

  attr_reader :sentence, :criteria, :out_of_scope, :context, :changes, :changes_text

  def initialize(story)
    @fences = []
    @criteria = []
    @out_of_scope = []
    @changes_source = nil
    rest = []
    used = {}

    preamble, sections = split_sections(story.body)
    rest << [ nil, preamble ] if preamble.present?
    sections.each do |title, content|
      kind = OWN[normalize(title)]
      if kind.nil? || used[kind]
        rest << [ title, content ]
        next
      end

      used[kind] = true
      leftover = read(kind, content, story)
      rest << [ title, leftover ] if leftover.present?
    end

    @changes, @changes_text = changes_in(@changes_source, story.changed_capabilities.to_a)
    @context = context_in(rest)
  end

  private

  # [preámbulo, [[título, texto]]], sin comentarios HTML y sin partir dentro del código cercado.
  def split_sections(body)
    text = body.to_s.gsub("\r\n", "\n").gsub(/<!--.*?-->/m, "").gsub(FENCE) { mask(it) }
    preamble, *chunks = text.split(/^## +/)
    sections = chunks.map { |chunk| chunk.split("\n", 2).then { |title, content| [ title.strip, unmask(content.to_s.strip) ] } }
    [ unmask(preamble.to_s.strip), sections ]
  end

  def mask(code)
    @fences << code
    "#{@fences.size - 1}"
  end

  def unmask(text) = text.gsub(FENCE_MARK) { @fences[$1.to_i] }

  # «Criterios de aceptacion:» y «Criterios de aceptación» son la misma sección.
  def normalize(title)
    title.unicode_normalize(:nfd).gsub(/\p{Mn}/, "").downcase.squish.delete_suffix(":").strip
  end

  # Lee una sección propia y devuelve lo que no se ha usado (va al contexto con su título).
  def read(kind, content, story)
    case kind
    when :sentence
      first, rest = content.split(/\n\s*\n/, 2)
      return content if first.blank? || first.match?(/\A\s*([-*+] |\d+\. |#|```|>|\|)/)

      @sentence = first.squish
      rest.to_s.strip
    when :criteria
      items = criteria_in(content) or return content
      @criteria = items
      nil
    when :out_of_scope
      items = out_of_scope_in(content) or return content
      @out_of_scope = items
      nil
    when :changes
      @changes_source = content
      nil
    end
  end

  # Las casillas, sus subtítulos y el texto suelto, en orden; nil si hay código (entonces va entera como prosa).
  def criteria_in(text)
    return nil if text.match?(FENCE)

    text.split(/\n\s*\n/).flat_map { criteria_chunk(it) }
  end

  def criteria_chunk(chunk)
    items = []
    loose = []
    flush = -> { items << { type: "paragraph", text: loose.join("\n") } if loose.any?; loose = [] }
    chunk.lines.map(&:rstrip).reject(&:blank?).each do |line|
      if (match = line.match(CHECKBOX))
        flush.()
        items << { type: "check", text: match[2].strip, done: match[1] != " " }
      elsif items.last&.dig(:type) == "check" && loose.empty? && line.match?(/\A\s+\S/) && !line.match?(BULLET)
        items.last[:text] = "#{items.last[:text]} #{line.strip}".strip
      elsif (title = heading(line, chunk))
        flush.()
        items << { type: "heading", text: title }
      else
        loose << line.strip
      end
    end
    flush.()
    items
  end

  # Un subtítulo: `### …`, `**…**` solo en su línea o, si va justo encima de las casillas, una línea corta sin punto final.
  def heading(line, chunk)
    if (match = line.strip.match(HEADING))
      return (match[1] || match[2]).strip.delete_suffix(":")
    end

    first, second = chunk.lines.map(&:strip).reject(&:blank?)
    line.strip if line.strip == first && second&.match?(CHECKBOX) && line.length <= 80 && !line.match?(/[.:;!?,]\s*\z|\A\s*[-*+>|#]/)
  end

  # Viñetas (con sus líneas de continuación) o un solo párrafo; nil si hay algo más (va entera como prosa).
  def out_of_scope_in(text)
    chunks = text.split(/\n\s*\n/).map(&:strip).compact_blank
    return [] if chunks.empty?
    return [ chunks.first.squish ] if chunks.one? && !chunks.first.match?(BULLET) && !chunks.first.match?(FENCE)
    return nil unless chunks.all? { it.match?(BULLET) && !it.match?(FENCE) && !it.match?(/^###/) }

    chunks.flat_map { it.split(/^\s*(?:[-*+]|\d+[.)])\s+/).drop(1).map(&:squish).compact_blank }
  end

  # El resto, troceado en bloques como el cuerpo de una página, sin reconocer frase, reglas ni preguntas.
  def context_in(rest)
    rest.flat_map do |title, content|
      Page::Reading.new(content, plain: true).sections.map.with_index do |section, index|
        { title: index.zero? ? title : section[:title], blocks: section[:blocks] }
      end
    end.reject { it[:blocks].empty? }
  end

  def changes_in(text, pages)
    blocks = pages.map { { slug: it.slug, capability: it.title, icon: it.icon, adds: [], keeps: [] } }
    current = blocks.one? ? blocks.first : nil
    loose = []
    text.to_s.lines.map(&:strip).compact_blank.each do |line|
      if (heading = line[/\A###+\s+(.+)\z/, 1] || line[/\A\*\*([^*]+)\*\*:?\z/, 1])
        found = blocks.find { |block| [ block[:slug], block[:capability].downcase ].include?(heading.strip.delete_suffix(":").downcase) }
        next current = found if found
      end
      item = line.sub(BULLET, "")
      mark, rest = item.match(/\A([+=])\s*(.*)\z/)&.captures
      if current
        (mark == "=" ? current[:keeps] : current[:adds]) << (rest || item)
      else
        loose << line
      end
    end
    [ blocks, loose.join("\n").presence ]
  end
end
