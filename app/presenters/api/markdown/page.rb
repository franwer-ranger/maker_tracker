# Una página de la documentación (`mt doc tablero`, docs/CLI.md): frontmatter
# con sus propiedades y el cuerpo debajo. Es el formato que acepta `mt doc edit`
# (Api::PageDocument): lo que se lee se puede editar y devolver. Tras la marca de
# solo lectura, las decisiones vigentes que la rigen (MT-90), cómo ha cambiado
# con las historias que la cambiaron (MT-91) y su historial, que también
# registra las decisiones ya sustituidas.
class Api::Markdown::Page
  include Api::Markdown::Formatting

  READ_ONLY_MARK = "<!-- mt: read-only below this line; mt doc edit ignores it -->".freeze
  HISTORY = 10

  # En la prosa y en el índice: "capability", "cross-cutting", "cover".
  def self.kind_words(kind) = kind.to_s == "crosscutting" ? "cross-cutting" : kind.to_s

  def initialize(page)
    @page = page
  end

  def to_s
    [ frontmatter, @page.body.to_s.strip.presence, READ_ONLY_MARK, attachments_section(@page), decisions, changes, history ].compact.join("\n\n") + "\n"
  end

  # Las vigentes que rigen la página, por número (la portada no tiene: es el brief).
  def self.decisions_in_force(page) = page.decisions.in_force.reorder(:number).includes(:actor, :superseded_by)

  private

  def frontmatter
    <<~YAML.strip
      ---
      slug: #{@page.slug}
      version: #{@page.version}
      type: #{@page.kind}
      title: #{scalar(@page.title)}
      icon: #{scalar(@page.icon)}
      area: #{scalar(@page.area)}
      ---
    YAML
      .gsub(/ +$/, "")
  end

  #   D-14 · claude · 2026-10-16 · PDFs con Prawn, sin servicios externos
  #        Why: autoalojado y sin coste por documento.
  def decisions
    return if @page.cover?

    decisions = self.class.decisions_in_force(@page).to_a
    return "## Decisions in force\n\nNone yet: mt decide \"…\" --why \"…\" --capability #{@page.slug}." if decisions.empty?

    indent = " " * (decisions.map { it.reference.length }.max + 1)
    "## Decisions in force\n\n#{decisions.map { decision_line(it, indent) }.join("\n")}"
  end

  # Las historias que la cambiaron al cerrarse (MT-91), con la versión que dejaron:
  #   2026-11-24 10:12  claude  PG-49 Plantillas de post reutilizables  version 3
  def changes
    return if @page.cover?

    events = @page.story_changes.includes(:actor, :story).limit(HISTORY).to_a
    return "## How it has changed\n\nNo story has changed it yet: a story lists it under capabilities: and mt done links its update." if events.empty?

    rows = events.map do |event|
      doc = Array(event.data["docs"]).find { it["page_id"] == @page.id }
      [ datetime(event.occurred_at), event.actor.name, "#{event.story.reference} #{event.story.title}", ("version #{doc['version']}" if doc&.dig("version")) ]
    end
    "## How it has changed\n\n#{table(rows).join("\n")}"
  end

  def history
    events = @page.history.includes(:actor).limit(HISTORY).to_a
    return "## History\n\nNo events yet." if events.empty?

    names = Api::Markdown::EventSentence.milestone_codes(@page.project)
    rows = events.map { [ datetime(it.occurred_at), it.actor.name, Api::Markdown::EventSentence.new(it, names).to_s ] }
    "## History\n\n#{table(rows).join("\n")}"
  end
end
