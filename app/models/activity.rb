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
  # Cuántas historias en Definiendo se ofrecen en la tarjeta de un proyecto con poco trabajo.
  SUGGESTIONS = 2
  RECENT = 5

  # kind: :question | :definition | :low_work. `since`: desde cuándo espera.
  # `story` y `question` según el tipo; `reason` de :definition (:questions o
  # :stalled); `options` de :low_work: sus historias en Definiendo, cuántas hay y cuántas Listas quedan.
  Card = Data.define(:kind, :project, :story, :question, :reason, :since, :options, :defining_count, :ready_count) do
    def initialize(kind:, project:, since:, story: nil, question: nil, reason: nil, options: [], defining_count: 0, ready_count: 0) = super
    def partial = "activity/#{kind}"
    def question? = kind == :question
  end

  # Una historia Hecha que Fran aún no ha probado (MT-32). `done_at` y `done_by`
  # salen de su evento de Hecha; `url`, de la línea «Dónde se prueba» del brief.
  QaCard = Data.define(:story, :project, :done_at, :done_by, :commits, :url, :criteria) do
    def host = (URI.parse(url).host if url)
  end

  # Memoizado por petición: la barra lateral y la pantalla lo piden a la vez.
  def self.for_you
    Current.activity_for_you ||= new.for_you
  end

  def for_you
    cards = question_cards + definition_cards + low_work_cards
    cards.each_with_index.sort_by { |card, index| [ card.since, index ] }.map(&:first)
  end

  # QA pendiente de todos los proyectos (MT-32): no cuenta en «Te toca» ni en el
  # contador. Las que llevan más tiempo hechas, primero. Tres consultas en total
  # (historias con su proyecto, y sus eventos de Hecha con su actor), no una por proyecto.
  def qa_pending
    stories = Story.qa_pending.includes(:project, :milestone).to_a
    return [] if stories.empty?

    done = Event.where(story_id: stories.map(&:id), action: "story.state_changed").includes(:actor).order(:occurred_at, :id)
      .select { it.data["to"] == "done" }.index_by(&:story_id) # el último gana
    stories.map do |story|
      event = done[story.id]
      QaCard.new(story: story, project: story.project, done_at: event&.occurred_at || story.updated_at, done_by: event&.actor,
        commits: event&.commits || [], url: story.project.qa_url, criteria: story.criteria_list)
    end.sort_by { [ it.done_at, it.story.id ] }
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

  # Proyectos a los que les queda poco trabajo (MT-33): dos Listas y desbloqueadas
  # o menos en los hitos abiertos, con 0 como caso extremo (MT-30: se han quedado
  # sin trabajo). Sale de `ReadyWork`, la misma cuenta que enseñan el bloque de
  # Actividad y las cabeceras. Espera desde su último evento.
  def low_work_cards
    summaries = ReadyWork.all.values.select(&:low?)
    return [] if summaries.empty?

    last_events = Event.group(:project_id).maximum(:occurred_at)
    summaries.map do |summary|
      project = summary.project
      Card.new(kind: :low_work, project: project, since: last_events[project.id] || project.created_at,
        options: summary.defining.first(SUGGESTIONS), defining_count: summary.defining_count, ready_count: summary.ready)
    end
  end
end
