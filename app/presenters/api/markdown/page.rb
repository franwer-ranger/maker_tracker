# Una página de la documentación (`mt doc tablero`, docs/CLI.md): frontmatter
# con sus propiedades y el cuerpo debajo. Es el formato que acepta `mt doc edit`
# (Api::PageDocument): lo que se lee se puede editar y devolver. Tras la marca de
# solo lectura, las decisiones vigentes que la rigen (MT-90) y su historial, que
# también registra las ya sustituidas.
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
    [ frontmatter, @page.body.to_s.strip.presence, READ_ONLY_MARK, decisions, history ].compact.join("\n\n") + "\n"
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
    items = decisions.map do |decision|
      why = decision_why(decision)
      "#{decision.reference} · #{decision.actor.name} · #{date(decision.created_at)} · #{decision.title}#{"\n#{indent}Why: #{why}" if why}"
    end
    "## Decisions in force\n\n#{items.join("\n")}"
  end

  def history
    events = @page.history.includes(:actor).limit(HISTORY).to_a
    return "## History\n\nNo events yet." if events.empty?

    names = Api::Markdown::EventSentence.milestone_codes(@page.project)
    rows = events.map { [ datetime(it.occurred_at), it.actor.name, Api::Markdown::EventSentence.new(it, names).to_s ] }
    "## History\n\n#{table(rows).join("\n")}"
  end
end
