# La daily de un actor en un proyecto (MT-42): el estado del proyecto para
# retomar sin abrir nada. Maker Tracker da los datos; el resumen y las
# propuestas los pone el agente.
#
# La «última daily» de un actor es su último evento `daily.held` en el
# proyecto: no hay tabla ni estado aparte, y la daily de un agente no mueve la
# de otro. Solo avanza al lanzar la daily; si se pierde, se recupera con
# `since:`. Los evolutivos que propone entran como ideas (D-44), nunca en el
# roadmap, y son como mucho MAX_IDEAS por daily (D-55: contadas también en las
# últimas 24 h, para que repetir la daily no reinicie el tope).
class Daily
  MAX_IDEAS = 3
  IDEAS_WINDOW = 24.hours
  # Sin daily anterior (o sin fecha) se cuenta desde hace esto.
  DEFAULT_WINDOW = 7.days
  # Una historia en Definiendo parada más de esto se considera esperando a Fran.
  STALE_DEFINING = 3.days

  class IdeaLimit < StandardError; end
  class NotHeld < StandardError; end

  attr_reader :project, :actor, :since, :previous, :now

  def self.last_held(project, actor)
    project.events.where(action: "daily.held", actor: actor).recent_first.first
  end

  # `since`: instante explícito; sin él, la última daily del actor o, si no la
  # hay, DEFAULT_WINDOW. `now` se fija al empezar: lo que se lee llega hasta
  # ahí y la daily se registra en ese instante, así que nada se cuela entre
  # una cosa y la otra.
  def initialize(project, actor, since: nil, now: Time.current)
    @project = project
    @actor = actor
    @now = now
    @previous = self.class.last_held(project, actor)
    @explicit_since = since.present?
    @since = since || previous&.occurred_at || (now - DEFAULT_WINDOW)
  end

  def first? = previous.nil?

  def explicit_since? = @explicit_since

  def changes = @changes ||= Changes.new(project, since: since, until_time: now)

  # Las historias en curso, en el orden del roadmap.
  def in_progress
    @in_progress ||= roadmap_order(project.stories.in_progress.includes(:claimed_by, :milestone).to_a)
  end

  # Las no hechas que esperan a otras historias o a una respuesta, con por qué:
  # [[story, ["PG-45", ...], [preguntas]]].
  def blocked
    @blocked ||= begin
      stories = project.stories.where.not(state: "done").includes(:milestone, :questions).where(<<~SQL.squish).to_a
        json_array_length(COALESCE(json_extract(stories.properties, '$.blocked_by'), '[]')) > 0
        OR EXISTS (SELECT 1 FROM questions WHERE questions.story_id = stories.id AND questions.answered_at IS NULL AND questions.blocking)
      SQL
      roadmap_order(stories.select { it.blocked?(done_numbers: done_numbers) }).map do |story|
        [ story, story.pending_blockers(done_numbers: done_numbers), story.blocking_questions ]
      end
    end
  end

  # Lo que espera a Fran, con el porqué: preguntas abiertas (bloqueantes o no),
  # historias en Definiendo sin criterios o paradas, y las Definiendo o Listas
  # cuyo último comentario es de un agente. [[story, [motivos]]].
  def waiting_for_human
    @waiting_for_human ||= begin
      reasons = Hash.new { |hash, story| hash[story] = [] }
      project.questions.open.includes(:actor, story: :milestone).where.not(stories: { state: "done" }).order(:created_at, :id).each do |question|
        reasons[question.story] << "open question #{question.reference} from #{question.actor.name} (#{question.blocking? ? 'blocking' : 'not blocking'})"
      end
      project.stories.where(state: %w[defining ready]).includes(:milestone).each do |story|
        if story.defining? && reasons[story].empty?
          reasons[story] << "no criteria" if story.missing_criteria?
          reasons[story] << "open questions in the body" if story.open_questions?
          reasons[story] << "defining for #{stale_days(story)} days" if reasons[story].empty? && stale?(story)
        end
        last = last_comments[story.id]
        reasons[story] << "#{last.actor.name} commented #{last.created_at.localtime.strftime('%Y-%m-%d %H:%M')} and nobody replied" if last
      end
      roadmap_order(reasons.keys.select { reasons[it].any? }).map { [ it, reasons[it] ] }
    end
  end

  def next_story = @next_story ||= project.next_story

  def ready_count = project.stories.ready.count

  def done_numbers = @done_numbers ||= project.stories.done.pluck(:number)

  # Registra que el actor ha hecho su daily: desde `now`, la siguiente cuenta
  # desde aquí. Es el único efecto de leerla.
  def hold!
    project.record_event!("daily.held", actor: actor, occurred_at: now, data: { since: since.utc.iso8601, first: first? })
  end

  # Ideas que este actor ha propuesto desde su última daily o en las últimas
  # 24 h (lo que llegue más atrás), de la más antigua a la más reciente.
  def ideas
    held = self.class.last_held(project, actor)
    return [] unless held

    from = [ held.occurred_at, Time.current - IDEAS_WINDOW ].min
    project.events.where(action: "story.created", actor: actor).where("occurred_at >= ?", from)
      .recent_first.includes(:story).select { it.data["daily"] }.map(&:story).reverse
  end

  # Una idea en la bandeja, a nombre del actor y marcada como de la daily.
  # Falla si no ha hecho su daily o si ya lleva MAX_IDEAS.
  def propose_idea!(title, why: nil)
    raise NotHeld unless self.class.last_held(project, actor)
    raise IdeaLimit if ideas.size >= MAX_IDEAS

    body = Story::BODY_TEMPLATE
    # Con bloque: el replacement como cadena interpretaría las barras del texto.
    body = body.sub("## Contexto\n") { "## Contexto\n\n#{why.strip}\n" } if why.present?
    project.create_story!({ title: title, body: body, state: "idea", milestone: nil }, actor: actor, data: { daily: true })
  end

  private

  def roadmap_order(stories)
    stories.sort_by { [ it.milestone ? 0 : 1, it.milestone&.position.to_i, it.position ] }
  end

  # El último comentario de cada historia en Definiendo o Lista, si es de un
  # agente: una consulta para los ids y otra para esos comentarios.
  def last_comments
    @last_comments ||= begin
      story_ids = project.stories.where(state: %w[defining ready]).select(:id)
      ids = Comment.where(story_id: story_ids).group(:story_id).maximum(:id).values
      Comment.where(id: ids).includes(:actor).select { it.actor.agent? }.index_by(&:story_id)
    end
  end

  def stale?(story) = story.updated_at < STALE_DEFINING.ago

  def stale_days(story) = ((Time.current - story.updated_at) / 1.day).floor
end
