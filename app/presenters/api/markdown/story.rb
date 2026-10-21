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
      version: #{@story.version}
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
    [ READ_ONLY_MARK, related, qa, questions, comments, history ].compact.join("\n\n")
  end

  # Solo si espera QA o ya la tuvo (MT-32). Lo que se prueba son los criterios de aceptación.
  #   ## QA · pending
  #   Test it at https://testing.postgram.app. mt qa PG-49 ok | mt qa PG-49 fail --note "…"
  def qa
    return unless @story.qa

    url = @story.project.qa_url
    case @story.qa
    when "pending"
      return waiting_for_deploy if @story.qa_awaiting_deploy?

      where = url ? "Test it at #{url}." : "There is no \"Dónde se prueba\" line in the brief to say where."
      "## QA · pending\n\n#{where} #{@story.reference} is done and does not block anything. Waiting for #{Actor.human.name}: mt qa #{@story.reference} ok | mt qa #{@story.reference} fail --note \"…\"."
    else
      "## QA · #{@story.qa}"
    end
  end

  # MT-46: la historia está hecha pero aún no se ha desplegado. `mt qa ok|fail` sigue funcionando.
  def waiting_for_deploy
    "## QA · waiting for deploy\n\n#{@story.reference} is done but not deployed yet: it shows up in mt qa when mt deployed marks it. #{Actor.human.name} can still pass or fail it already: mt qa #{@story.reference} ok | mt qa #{@story.reference} fail --note \"…\"."
  end

  # "Blocked by PG-47 Borradores automáticos (done): no longer blocking."
  def related
    lines = blocked_by.map do |story|
      "Blocked by #{story_label(story)}#{': no longer blocking' if story.done?}."
    end
    lines += @story.blocking.order(:number).map { "Blocks #{story_label(it)}." }
    lines += question_blockers
    "## Related\n\n#{lines.join("\n")}" if lines.any?
  end

  # "Blocked by fran: Q12 from codex, asked 2026-10-21 10:12. Answer it with mt answer PG-49 <option>."
  def question_blockers
    @story.blocking_questions.map do |question|
      "Blocked by #{Actor.human.name}: #{question.reference} from #{question.actor.name}, asked #{datetime(question.created_at)}. Answer it with #{answer_command(question, '<option>')}."
    end
  end

  def blocked_by = @story.project.stories.where(number: @story.blocked_by).order(:number)

  def story_label(story) = "#{story.reference} #{story.title} (#{state_words(story.state)})"

  # Las preguntas de la historia (tabla `questions`, no el cuerpo): abiertas primero.
  #   Q12 · open · asked by codex 2026-10-21 10:12 · blocking, reversible
  def questions
    return if @story.questions.empty?

    open, answered = @story.questions.includes(:actor, :answered_by).partition(&:open?)
    counts = [ ("#{open.size} open" if open.any?), ("#{answered.size} answered" if answered.any?) ].compact.join(", ")
    "## Questions · #{counts}\n\n#{(open + answered).map { question_block(it) }.join("\n\n")}"
  end

  def question_block(question)
    status = question.open? ? "open" : "answered by #{question.answered_by.name} #{datetime(question.answered_at)}"
    lines = [ "#{question.reference} · #{status} · asked by #{question.actor.name} #{datetime(question.created_at)} · #{question_traits(question).join(', ')}", question.title ]
    lines << question.context if question.context.present?
    question.options.each_with_index do |text, i|
      number = i + 1
      marks = [ ("recommended" if number == question.recommended), ("chosen" if number == question.answer) ].compact
      lines << "  #{number} #{text}#{" (#{marks.join(', ')})" if marks.any?}"
    end
    lines << "  #{question.free_answer? ? 'Free answer' : 'Note'}: #{question.answer_note}" if question.answer_note.present?
    lines << "  #{answer_command(question, question.recommended || '<option>')}" if question.open?
    lines.join("\n")
  end

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
