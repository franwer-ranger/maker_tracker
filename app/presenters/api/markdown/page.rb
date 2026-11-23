# Una página de la documentación (`mt doc tablero`, docs/CLI.md): frontmatter
# con sus propiedades y el cuerpo debajo. Es el formato que acepta `mt doc edit`
# (Api::PageDocument): lo que se lee se puede editar y devolver. Tras la marca de
# solo lectura, su historial.
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
    [ frontmatter, @page.body.to_s.strip.presence, READ_ONLY_MARK, history ].compact.join("\n\n") + "\n"
  end

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

  def history
    events = @page.history.includes(:actor).limit(HISTORY).to_a
    return "## History\n\nNo events yet." if events.empty?

    names = Api::Markdown::EventSentence.milestone_codes(@page.project)
    rows = events.map { [ datetime(it.occurred_at), it.actor.name, Api::Markdown::EventSentence.new(it, names).to_s ] }
    "## History\n\n#{table(rows).join("\n")}"
  end
end
