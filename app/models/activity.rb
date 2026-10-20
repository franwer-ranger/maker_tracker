# La portada (MT-30): lo que solo puede hacer Fran en todos los proyectos y lo
# que está en marcha. Se calcula al consultar, sin tabla propia: son preguntas,
# historias y proyectos que ya existen.
#
# «Te toca» son tarjetas (`Card`) con una fecha desde la que esperan; salen
# ordenadas por ella, la que más lleva esperando primero. Los bloques que lleguen
# después (QA pendiente, trabajo listo…) añaden su método a `for_you` y su
# partial en `app/views/activity/`; el contador de la barra es el número de tarjetas.
class Activity
  # Una historia en Definiendo está parada tras tanto tiempo sin cambios: el mismo umbral que el daily.
  STALLED_AFTER = Daily::STALE_DEFINING
  # Cuántas historias en Definiendo se ofrecen en la tarjeta de un proyecto sin trabajo.
  SUGGESTIONS = 2
  RECENT = 5

  # kind: :question | :definition | :no_work. `since`: desde cuándo espera.
  # `story` y `question` según el tipo; `reason` de :definition (:questions o
  # :stalled); `options` de :no_work: sus historias en Definiendo y cuántas hay.
  Card = Data.define(:kind, :project, :story, :question, :reason, :since, :options, :defining_count) do
    def initialize(kind:, project:, since:, story: nil, question: nil, reason: nil, options: [], defining_count: 0) = super
    def partial = "activity/#{kind}"
    def question? = kind == :question
  end

  # Memoizado por petición: la barra lateral y la pantalla lo piden a la vez.
  def self.for_you
    Current.activity_for_you ||= new.for_you
  end

  def for_you
    cards = question_cards + definition_cards + no_work_cards
    cards.each_with_index.sort_by { |card, index| [ card.since, index ] }.map(&:first)
  end

  # Historias En curso de todos los proyectos, la que lleva más tiempo primero.
  def in_progress
    Story.in_progress.includes(:project, :claimed_by).order(:claimed_at, :id).to_a
  end

  # Lo último que ha pasado, de todos los proyectos.
  def recent_events(limit = RECENT)
    Event.includes(:project, :story, :actor).recent_first.limit(limit).to_a
  end

  private

  # Las abiertas, bloqueen o no (una que no bloquea también espera su respuesta).
  def question_cards
    Question.open.includes(:actor, story: [ :project, :questions ]).oldest_first.map do |question|
      Card.new(kind: :question, project: question.story.project, story: question.story, question: question, since: question.created_at)
    end
  end

  # En Definiendo con preguntas abiertas en el cuerpo, o paradas. Espera desde
  # su último cambio: su `updated_at` o su último evento, lo más reciente.
  def definition_cards
    stories = Story.defining.includes(:project).to_a
    last_events = Event.where(story_id: stories.map(&:id)).group(:story_id).maximum(:occurred_at)
    stories.filter_map do |story|
      since = [ story.updated_at, last_events[story.id] ].compact.max
      reason = if story.open_questions? then :questions
      elsif since <= STALLED_AFTER.ago then :stalled
      end
      Card.new(kind: :definition, project: story.project, story: story, reason: reason, since: since) if reason
    end
  end

  # Proyectos con trabajo pendiente en algún hito abierto pero sin ninguna
  # historia Lista que un agente pueda coger: se han quedado sin trabajo. Espera
  # desde su último evento. Un proyecto terminado (todo Hecho o con los hitos
  # cerrados) no cuenta, ni el que tiene Listas paradas solo por preguntas que
  # ya salen en «Te toca». Todo en un puñado de consultas para todos los proyectos.
  def no_work_cards
    projects = Project.order(:created_at).to_a
    stories = Story.where(project_id: projects.map(&:id), milestone_id: Milestone.open.select(:id)).where.not(state: :done)
      .includes(:milestone, :questions).order(:position).to_a
    done = Story.done.pluck(:project_id, :number).group_by(&:first).transform_values { |rows| rows.map(&:last) }
    last_events = Event.group(:project_id).maximum(:occurred_at)
    by_project = stories.group_by(&:project_id)

    projects.filter_map do |project|
      pending = by_project[project.id].to_a
      next if pending.empty?

      ready = pending.select(&:ready?)
      # Libre, o parada solo por una pregunta que ya espera a Fran.
      next if ready.any? { it.pending_blockers(done_numbers: done[project.id].to_a).empty? }

      defining = pending.select(&:defining?).sort_by { [ it.milestone.position, it.position ] }
      Card.new(kind: :no_work, project: project, since: last_events[project.id] || project.created_at,
        options: defining.first(SUGGESTIONS), defining_count: defining.size)
    end
  end
end
