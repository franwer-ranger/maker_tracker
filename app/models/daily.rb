# La daily de un actor en un proyecto (MT-42): el estado del proyecto para
# retomar sin abrir nada. Maker Tracker da los datos; el resumen y las
# propuestas los pone el agente.
#
# La «última daily» de un actor es su último evento `daily.held` en el
# proyecto: no hay tabla ni estado aparte, y la daily de un agente no mueve la
# de otro. Los evolutivos que propone entran como ideas (D-44), nunca en el
# roadmap, y son como mucho MAX_IDEAS por daily.
class Daily
  MAX_IDEAS = 3
  # Sin daily anterior (o sin fecha) se cuenta desde hace esto.
  DEFAULT_WINDOW = 7.days
  # Una historia en Definiendo parada más de esto se considera esperando a Fran.
  STALE_DEFINING = 3.days

  class IdeaLimit < StandardError; end
  class NotHeld < StandardError; end

  attr_reader :project, :actor, :since, :previous

  def self.last_held(project, actor)
    project.events.where(action: "daily.held", actor: actor).recent_first.first
  end

  # `since`: instante explícito; sin él, la última daily del actor o, si no la
  # hay, DEFAULT_WINDOW.
  def initialize(project, actor, since: nil)
    @project = project
    @actor = actor
    @previous = self.class.last_held(project, actor)
    @explicit_since = since.present?
    @since = since || previous&.occurred_at || DEFAULT_WINDOW.ago
  end

  def first? = previous.nil?

  def explicit_since? = @explicit_since

  def activity = @activity ||= Activity.new(project, since: since)

  # Las historias en curso, en el orden del roadmap.
  def in_progress
    @in_progress ||= project.stories.in_progress.includes(:claimed_by, :milestone).to_a
      .sort_by { [ it.milestone ? 0 : 1, it.milestone&.position.to_i, it.position ] }
  end

  # Las que no hechas esperan a otras historias.
  def blocked
    @blocked ||= begin
      done = done_numbers
      project.stories.where.not(state: "done").includes(:milestone).select { it.blocked?(done_numbers: done) }
        .sort_by { [ it.milestone ? 0 : 1, it.milestone&.position.to_i, it.position ] }
    end
  end

  # Lo que espera a Fran: historias en Definiendo sin criterios, con preguntas
  # abiertas o paradas, y las historias vivas cuyo último comentario es de un
  # agente (puede ser una pregunta). Cada entrada, con el porqué.
  def waiting_for_human
    @waiting_for_human ||= begin
      human_ids = Actor.human_kind.ids
      stories = project.stories.where.not(state: "done").includes(:milestone, comments: :actor).to_a
      stories.filter_map do |story|
        reasons = []
        if story.defining?
          reasons << "no criteria" if story.missing_criteria?
          reasons << "open questions" if story.open_questions?
          reasons << "defining for #{stale_days(story)} days" if reasons.empty? && stale?(story)
        end
        last = story.comments.last
        reasons << "#{last.actor.name} commented #{last.created_at.localtime.strftime('%Y-%m-%d %H:%M')} and nobody replied" if last && human_ids.exclude?(last.actor_id)
        [ story, reasons ] if reasons.any?
      end.sort_by { |story, _| [ story.milestone ? 0 : 1, story.milestone&.position.to_i, story.position ] }
    end
  end

  def next_story = @next_story ||= project.next_story

  def ready_count = project.stories.ready.count

  # Registra que el actor ha hecho su daily: desde ahora, la siguiente cuenta
  # desde aquí. Es el único efecto de leerla.
  def hold!
    project.record_event!("daily.held", actor: actor, data: { since: since.utc.iso8601, first: first? })
  end

  # Ideas que este actor ha propuesto desde su última daily.
  def ideas
    held = self.class.last_held(project, actor)
    return [] unless held

    project.events.where(action: "story.created", actor: actor).where("occurred_at >= ?", held.occurred_at)
      .recent_first.includes(:story).select { it.data["daily"] }.map(&:story).reverse
  end

  # Una idea en la bandeja, a nombre del actor y marcada como de la daily.
  # Falla si no ha hecho su daily o si ya lleva MAX_IDEAS.
  def propose_idea!(title, why: nil)
    raise NotHeld unless self.class.last_held(project, actor)
    raise IdeaLimit if ideas.size >= MAX_IDEAS

    body = Story::BODY_TEMPLATE
    body = body.sub("## Contexto\n", "## Contexto\n\n#{why.strip}\n") if why.present?
    project.create_story!({ title: title, body: body, state: "idea", milestone: nil }, actor: actor, data: { daily: true })
  end

  private

  def done_numbers = @done_numbers ||= project.stories.done.pluck(:number)

  def stale?(story) = story.updated_at < STALE_DEFINING.ago

  def stale_days(story) = ((Time.current - story.updated_at) / 1.day).floor
end
