# Una historia en el formato de docs/backlog/: frontmatter con sus propiedades
# y el cuerpo debajo (docs/CLI.md → mt show). Es el mismo formato que acepta la
# escritura (#018, Api::StoryDocument): lo que se lee se puede editar y devolver.
#
# Tras READ_ONLY_MARK añade lo que no se edita: relacionadas, comentarios e
# historial. La escritura ignora todo lo que va después de la marca.
class Api::Markdown::Story
  include Api::Markdown::Formatting

  READ_ONLY_MARK = "<!-- mt: read-only below this line; mt edit ignores it -->".freeze
  HISTORY = 10

  def initialize(story)
    @story = story
  end

  def to_s
    [ frontmatter, @story.body.to_s.strip.presence, read_only ].compact.join("\n\n") + "\n"
  end

  private

  # `milestone` es el título del hito: el código (M2) cambia al reordenar.
  def frontmatter
    <<~YAML.strip
      ---
      number: #{@story.number}
      title: #{scalar(@story.title)}
      milestone: #{scalar(@story.milestone&.title)}
      state: #{@story.state}
      claimed_by: #{@story.claimed_by&.name}
      mockup: #{scalar(@story.mockup)}
      labels: #{list(@story.labels)}
      blocked_by: #{list(@story.blocked_by)}
      ---
    YAML
      .gsub(/ +$/, "")
  end

  def read_only
    [ READ_ONLY_MARK, related, comments, history ].compact.join("\n\n")
  end

  # "Blocked by PG-47 Borradores automáticos (done): no longer blocking."
  def related
    lines = blocked_by.map do |story|
      "Blocked by #{story_label(story)}#{': no longer blocking' if story.done?}."
    end
    lines += @story.blocking.order(:number).map { "Blocks #{story_label(it)}." }
    "## Related\n\n#{lines.join("\n")}" if lines.any?
  end

  def blocked_by = @story.project.stories.where(number: @story.blocked_by).order(:number)

  def story_label(story) = "#{story.reference} #{story.title} (#{state_words(story.state)})"

  def comments
    return if @story.comments.empty?

    items = @story.comments.includes(:actor).map do |comment|
      "#{comment.actor.name} · #{datetime(comment.created_at)}\n#{comment.body.strip}"
    end
    "## Comments · #{items.size}\n\n#{items.join("\n\n")}"
  end

  def history
    events = @story.history.includes(:actor).limit(HISTORY).to_a
    return "## History\n\nNo events yet." if events.empty?

    names = Api::Markdown::EventSentence.milestone_codes(@story.project)
    rows = events.map { [ datetime(it.occurred_at), it.actor.name, Api::Markdown::EventSentence.new(it, names).to_s ] }
    "## History\n\n#{table(rows).join("\n")}"
  end
end
