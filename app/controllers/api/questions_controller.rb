# Preguntas de agentes con opciones (MT-29): `mt ask`, `mt answer` y
# `mt questions`. Una pregunta cuelga de una historia; las abiertas de todos
# los proyectos (o de uno) se listan con `GET /api/questions`.
class Api::QuestionsController < Api::BaseController
  Formatting = Api::Markdown::Formatting

  # `mt questions [--project PG]`: las abiertas, la que más lleva esperando primero.
  def index
    questions = Question.open.includes(:actor, story: :project).oldest_first
    questions = questions.joins(story: :project).where(projects: { key: params[:project].to_s.upcase }) if params[:project].present?
    questions = questions.to_a
    summary = "#{Formatting.plural(questions.size, 'open question')}."
    render_ok({ questions: questions.map { Formatting.question_data(it) }, markdown: list_markdown(summary, questions) },
      summary: summary, breadcrumbs: questions.first(3).map { "mt show #{it.story.reference}" }.uniq)
  end

  # `mt ask PG-49 "¿…?" --option … --recommend 2 [--reversible] [--no-bloqueante]`
  def create
    options = Array(params[:options]).map(&:to_s)
    question = story.ask!({ title: params.require(:title), context: params[:context].to_s, options: options,
                            recommended: integer_param(:recommended), reversible: boolean_param(:reversible),
                            blocking: params.key?(:blocking) ? boolean_param(:blocking) : true }, actor: Current.actor)
    render_ok({ question: Formatting.question_data(question), story: Formatting.story_data(story.reload) },
      status: :created, summary: asked_summary(question), breadcrumbs: asked_breadcrumbs(question))
  rescue ActiveRecord::RecordInvalid => e
    raise Api::Error.validation("#{e.record.errors.full_messages.to_sentence}.", details: e.record.errors.to_hash(true),
      hint: "mt ask #{story.reference} \"…\" --option \"…\" --option \"…\" [--recommend 2] (--recommend is required with --no-bloqueante).")
  end

  # `mt answer PG-49 2 [--note "…"] [--question 12] [--decide]`
  def answer
    question = find_question
    option = integer_param(:option) || raise(Api::Error.validation("missing the number of the option.",
      hint: "mt answer #{story.reference} <option> (1 to #{question.options.size}). See the options with mt show #{story.reference}."))
    story.answer_question!(question, option: option, note: params[:note], actor: Current.actor, decide: boolean_param(:decide) == true)
    render_ok({ question: Formatting.question_data(question.reload), story: Formatting.story_data(story.reload) },
      summary: answered_summary(question), breadcrumbs: answered_breadcrumbs)
  end

  private

  # La pregunta que se contesta: la indicada con `question` o, si la historia
  # solo tiene una abierta, esa.
  def find_question
    if params[:question].present?
      id = Integer(params[:question].to_s.delete_prefix("Q").delete_prefix("q"), exception: false)
      question = story.questions.find_by(id: id) ||
        raise(Api::Error.not_found("#{story.reference} has no question #{params[:question]}.", hint: "see them with mt show #{story.reference}."))
      raise Question::AlreadyAnswered, question if question.answered?

      return question
    end

    open = story.questions.open.to_a
    return open.first if open.one?

    if open.empty?
      raise Api::Error.not_found("#{story.reference} has no open questions.", hint: "see the open ones with mt questions.")
    end
    ids = open.map(&:reference)
    raise Api::Error.validation("#{story.reference} has #{open.size} open questions: #{ids.join(', ')}.",
      hint: "choose one with --question <id>: mt answer #{story.reference} <option> --question #{open.first.id}")
  end

  def asked_summary(question)
    human = Actor.human.name
    head = "#{question.reference} asked on #{story.reference} by #{Current.actor.name}."
    if question.blocking?
      released = story.events.recent_first.first(2).any? { it.action == "story.state_changed" && it.data["released"] }
      "#{head} #{story.reference}#{' is released and' if released} waits for #{human}."
    else
      "#{head} It does not block: carry on with option #{question.recommended} (#{question.recommended_text}) unless #{human} says otherwise."
    end
  end

  def asked_breadcrumbs(question)
    question.blocking? ? [ "mt next", "mt show #{story.reference}" ] : [ "mt show #{story.reference}", "mt questions" ]
  end

  def answered_summary(question)
    parts = [ "#{question.reference} answered on #{story.reference} by #{Current.actor.name}: #{question.answer} · #{question.answer_text}." ]
    decision = story.events.recent_first.find { it.action == "question.answered" }&.data&.dig("decision")
    parts << "Recorded as D-#{decision}." if decision
    waiting = story.reload.blocking_questions
    parts << (waiting.any? ? "#{story.reference} still waits for #{Formatting.plural(waiting.size, 'blocking question')}." : "#{story.reference} has no blocking questions left.") if question.blocking?
    parts.join(" ")
  end

  def answered_breadcrumbs = [ "mt show #{story.reference}", "mt next", "mt questions" ]

  def integer_param(name)
    return unless params.key?(name) && params[name].present?

    Integer(params[name].to_s, exception: false) ||
      raise(Api::Error.validation("#{name} must be a whole number, not #{params[name]}.", hint: "options are numbered from 1."))
  end

  # true/false; nulo si no viene.
  def boolean_param(name)
    return unless params.key?(name)

    ActiveModel::Type::Boolean.new.cast(params[name])
  end

  # PG-50  Q12  ¿Qué redes…?       codex  40 min  blocking
  #        1 X y LinkedIn
  #        2 Todas las conectadas (recommended)
  def list_markdown(summary, questions)
    return "#{summary}\n" if questions.empty?

    rows = questions.map { [ it.story.reference, it.reference, it.title, it.actor.name, Formatting.waiting(it.created_at), Formatting.question_traits(it).join(", ") ] }
    items = Formatting.table(rows, min: [ 0, 0, Formatting::TITLE_WIDTH ]).zip(questions).map do |line, question|
      options = question.options.each_with_index.map { |text, i| "#{' ' * 7}#{i + 1} #{text}#{' (recommended)' if i + 1 == question.recommended}" }
      [ line, *options ].join("\n")
    end
    "#{summary}\n\n#{items.join("\n")}\n"
  end
end
