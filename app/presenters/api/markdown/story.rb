# Una historia en el formato de docs/backlog/: frontmatter con sus propiedades
# y el cuerpo debajo. Es el mismo formato que acepta la escritura (#018,
# Api::StoryDocument): lo que se lee se puede editar y devolver.
#
# Tras READ_ONLY_MARK añade lo que no se edita: bloqueos, comentarios e
# historial. La escritura ignora todo lo que va después de la marca.
class Api::Markdown::Story
  include Api::Markdown::Formatting

  READ_ONLY_MARK = "<!-- mt: lo que sigue es solo lectura; mt edit lo ignora -->".freeze

  def initialize(story)
    @story = story
  end

  def to_s
    [ frontmatter, @story.body.to_s.strip, read_only ].compact.join("\n\n") + "\n"
  end

  private

  def frontmatter
    <<~YAML.strip
      ---
      number: #{@story.number}
      title: #{scalar(@story.title)}
      milestone: #{@story.milestone&.code}
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
    sections = [ READ_ONLY_MARK ]
    sections << "**Bloqueada por** #{sentence(blockers)}" if blockers.any?
    sections << "**Ya no la bloquean** (hechas): #{sentence(resolved_blockers)}" if resolved_blockers.any?
    sections << "**Bloquea a** #{sentence(blocking)}" if blocking.any?
    sections << comments if @story.comments.any?
    sections << history
    sections.join("\n\n")
  end

  # "PG-47 (ready)"
  def blockers
    @blockers ||= begin
      pending = @story.pending_blockers
      @story.project.stories.where(number: pending).order(:number).map { "#{it.reference} (#{it.state})" }
    end
  end

  def resolved_blockers
    @resolved_blockers ||= (@story.blocked_by - @story.pending_blockers).sort.map { "#{@story.project.key}-#{it}" }
  end

  def blocking
    @blocking ||= @story.blocking.order(:number).map { "#{it.reference} (#{it.state})" }
  end

  def comments
    items = @story.comments.includes(:actor).map do |comment|
      "**#{comment.actor.name}** · #{datetime(comment.created_at)}\n\n#{comment.body.strip}"
    end
    "## Comentarios\n\n#{items.join("\n\n---\n\n")}"
  end

  def history
    helpers = ApplicationController.helpers
    events = @story.history.includes(:actor).limit(10).map do |event|
      sentence = helpers.event_sentence(event)
      sentence = "#{event.actor.name} · #{sentence}" unless sentence.start_with?("#{event.actor.name} ")
      reason = event.reason ? " · motivo: #{event.reason}" : ""
      "- #{datetime(event.occurred_at)} · #{sentence}#{reason}"
    end
    "## Historial\n\n#{events.presence&.join("\n") || 'Sin eventos.'}"
  end
end
