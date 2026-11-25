# `mt doc lint` (MT-123): lo que la web verá de una página, sin abrirla. Lee
# el cuerpo con el mismo `Page::Reading` que la página de la capacidad y dice
# si tiene frase, cuántas reglas y preguntas reconoce, qué secciones de «Cómo
# funciona» o «¿Qué pasa si…?» se quedan como prosa, qué decisiones e
# historias citadas no existen (o están sustituidas) y qué imágenes no cargan
# o no son adjuntos de la página.
#
# Cada hallazgo es un error (algo que impide leerla bien: sin frase, una cita
# o una imagen rota) o un aviso (se lee, pero es mejorable).
class Page::Lint
  IMAGE = /!\[([^\]]*)\]\(\s*<?([^)\s>]*)>?(?:\s+"[^"]*")?\s*\)/
  DECISION_REF = /(?<![\w-])D-(\d+)\b/
  BLOB_PATH = %r{\A/rails/active_storage/(?:blobs|representations)/(?:redirect/|proxy/)?([^/]+)/}

  Finding = Data.define(:level, :message) do
    def error? = level == :error
  end

  attr_reader :page, :reading, :findings

  def initialize(page)
    @page = page
    @findings = []
    @reading = read
    return unless @reading

    check_lead
    check_prose_sections
    check_decisions
    check_stories
    check_images
  end

  def errors = findings.select(&:error?)
  def warnings = findings.reject(&:error?)
  def rules = reading&.rules.to_a
  def questions = reading&.questions.to_a

  def to_h
    { slug: page.slug, title: page.title, lead: reading&.lead, rules: rules.size, questions: questions.size,
      errors: errors.map(&:message), warnings: warnings.map(&:message) }
  end

  private

  def text = @text ||= page.body.to_s.gsub("\r\n", "\n").gsub(Page::Reading::FENCE, "")
  def attachments = @attachments ||= page.ordered_attachments.to_a

  def read
    Page::Reading.new(page.body, attachments: page.screenshots.map { Attachable.path(it) })
  rescue StandardError => error
    error!("the page cannot be read (#{error.class}: #{error.message.truncate(120)}): the web would fail to show it.")
    nil
  end

  def check_lead
    return if reading.lead.present?

    error!("no opening sentence: start the page with a paragraph (before any ##), or with the first one of «## Qué hace hoy».")
  end

  # «Cómo funciona» o «¿Qué pasa si…?» que no se dejan partir en entradas (los de más, también).
  def check_prose_sections
    reading.sections.each do |section|
      title = section[:title].to_s
      kind = if title.match?(Page::Reading::RULES) then "rules"
      elsif title.match?(Page::Reading::QUESTIONS) then "questions"
      end
      next unless kind

      again = (kind == "rules" ? reading.rules : reading.questions)
      warning!(again ? "«#{title}» will show as prose: there is already one, only the first counts as #{kind}." :
        "«#{title}» will show as prose, not as #{kind}: it must have only ### entries (from its first line) or only bullets, with no intro, closing, code or empty ###.")
    end
  end

  def check_decisions
    numbers = text.scan(DECISION_REF).flatten.map(&:to_i).uniq
    return if numbers.empty?

    found = page.project.decisions.where(number: numbers).includes(:superseded_by).index_by(&:number)
    numbers.each do |number|
      decision = found[number]
      if decision.nil?
        error!("D-#{number} does not exist in #{page.project.key}.")
      elsif decision.superseded_by
        warning!("D-#{number} is superseded by #{decision.superseded_by.reference}.")
      end
    end
  end

  def check_stories
    key = page.project.key
    numbers = text.scan(/(?<![\w-])#{Regexp.escape(key)}-(\d+)\b/).flatten.map(&:to_i).uniq
    existing = page.project.stories.where(number: numbers).pluck(:number)
    (numbers - existing).each { error!("#{key}-#{it} does not exist.") }
  end

  def check_images
    text.scan(IMAGE).uniq.each do |alt, url|
      name = alt.presence || url.split("/").last.to_s
      problem, level = image_problem(url.gsub("%28", "(").gsub("%29", ")"))
      findings << Finding.new(level: level, message: "image #{name} #{problem}") if problem
    end
  end

  # [qué le pasa, :error | :warning], o nil si es un adjunto de la página.
  def image_problem(url)
    if url.start_with?("attachment:")
      filename = url.delete_prefix("attachment:")
      return if attachments.any? { it.filename.to_s == filename }

      return [ "does not load: the page has no attachment named #{filename} (upload it with mt attach #{page.slug} #{filename}).", :error ]
    end

    uri = URI.parse(url) rescue nil
    path = uri&.path.to_s
    unless path.start_with?("/rails/active_storage/")
      return [ "is not an attachment of the page (#{url.truncate(60)}): lint cannot tell if it loads; attach it with mt attach #{page.slug} <file>.", :warning ] if uri&.host

      return [ "does not load: #{url.presence || 'the link is empty'} is not an attachment link (use the one mt attach prints).", :error ]
    end

    return if attachments.any? { Attachable.path(it) == path }

    signed_id = path[BLOB_PATH, 1]
    blob = signed_id && ActiveStorage::Blob.find_signed(signed_id)
    return [ "does not load: its link is broken or cut short (copy the one mt doc #{page.slug} lists under Attachments).", :error ] unless blob
    return if attachments.any? { it.blob_id == blob.id }

    [ "is not an attachment of the page (it is #{blob.filename}, attached somewhere else): attach it here with mt attach #{page.slug} <file>.", :warning ]
  end

  def error!(message) = findings << Finding.new(level: :error, message: message)
  def warning!(message) = findings << Finding.new(level: :warning, message: message)
end
