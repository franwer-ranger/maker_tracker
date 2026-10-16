class Api::StoriesController < Api::BaseController
  CREATABLE_STATES = %w[idea defining ready].freeze

  # `mt list`: filtros state, milestone (M2, su título o inbox), label y
  # claimed_by (un nombre o "me").
  def index
    stories = project.stories.includes(:milestone, :claimed_by, :project)
    stories = stories.where(state: params[:state]) if params[:state].present?
    stories = filter_by_milestone(stories) if params[:milestone].present?
    stories = filter_by_claimed_by(stories) if params[:claimed_by].present?
    stories = stories.select { it.labels.include?(params[:label]) } if params[:label].present?
    stories = stories.to_a.sort_by { [ it.milestone ? it.milestone.position : Float::INFINITY, it.position ] }

    done = project.stories.done.pluck(:number)
    markdown = stories.map { Api::Markdown::Formatting.story_line(it, done_numbers: done, show_milestone: params[:milestone].blank?) }.join("\n")
    render_ok({ stories: stories.map { Api::Markdown::Formatting.story_data(it, done_numbers: done) }, markdown: markdown.presence || "_Ninguna historia con esos filtros._" },
      summary: "#{stories.size} #{stories.size == 1 ? 'historia' : 'historias'}#{" (#{filters})" if filters.present?}",
      breadcrumbs: stories.first(3).map { "mt show #{it.reference}" })
  end

  # `mt show PG-49`: la historia en el formato de docs/backlog/.
  def show
    render_ok({ story: Api::Markdown::Formatting.story_data(story, done_numbers: project.stories.done.pluck(:number)),
                markdown: Api::Markdown::Story.new(story).to_s },
      summary: "#{story.reference} · #{story.title} (#{story.human_state})",
      breadcrumbs: story_breadcrumbs)
  end

  # `mt create "Título" [--milestone M2] [--state …] [--file f.md]`: con
  # campos o con `markdown` en el formato de ver. Nace como Idea y en la bandeja
  # si no se dice otra cosa; sin cuerpo, con la plantilla.
  def create
    attributes = story_attributes
    state = attributes.delete("state").presence || "idea"
    unless CREATABLE_STATES.include?(state)
      raise Api::Error.validation("Una historia nueva nace en #{CREATABLE_STATES.join(', ')}, no en #{state}",
        hint: "Créala y después usa mt start o mt done")
    end
    milestone = attributes.key?("milestone") ? milestone_or_inbox(attributes.delete("milestone")) : nil
    attributes.delete("body") if attributes["body"].blank?

    created = project.create_story!(attributes.merge("state" => state, "milestone" => milestone), actor: Current.actor)
    render_ok({ story: Api::Markdown::Formatting.story_data(created) },
      status: :created, warnings: created.ready? ? created.readiness_issues : [],
      summary: "#{created.reference} creada en #{Api::Markdown::Formatting.milestone_label(created.milestone)} (#{created.human_state})",
      breadcrumbs: [ "mt show #{created.reference}", "mt edit #{created.reference} --file <f.md>" ])
  end

  # `mt edit PG-49 --file f.md`: título, cuerpo y propiedades con Story#edit!.
  # Estado e hito son hechos con su propia operación: si cambian, error.
  def update
    attributes = story_attributes
    reject_fact_changes!(attributes)
    attributes = attributes.slice(*Story::Operations::EDITABLE_FIELDS)
    attributes.delete("body") if attributes.key?("body") && attributes["body"].to_s.strip == story.body.to_s.strip

    changed = story.edit!(attributes, actor: Current.actor)
    fields = changed ? story.history.first.data["fields"] : []
    render_ok({ story: Api::Markdown::Formatting.story_data(story), fields: fields },
      warnings: story.ready? ? story.readiness_issues : [],
      summary: changed ? "#{story.reference} editada: #{fields.join(', ')}" : "#{story.reference} sin cambios",
      breadcrumbs: [ "mt show #{story.reference}" ])
  end

  # `mt move PG-49 ready`. Pasar a Lista sin cumplir la regla es un warning.
  def move
    state = params.require(:state).to_s
    raise Api::Error.validation("Estado desconocido: #{state}", hint: "Los estados son #{Story.states.keys.join(', ')}") unless Story.states.key?(state)
    raise Story::ClaimedByOther, story if Current.actor.agent? && story.in_progress? && story.claimed_by && story.claimed_by != Current.actor

    changed = story.move_to!(state, actor: Current.actor, reason: params[:reason])
    warnings = state == "ready" ? story.readiness_issues : []
    render_ok({ story: Api::Markdown::Formatting.story_data(story) }, warnings: warnings,
      summary: changed ? "#{story.reference} pasa a #{story.human_state}" : "#{story.reference} ya estaba en #{story.human_state}",
      breadcrumbs: [ "mt show #{story.reference}", "mt roadmap" ])
  end

  # `mt reorder PG-49 --position 1 [--milestone M3] --reason "…"`. Las
  # posiciones se cuentan desde 1; sin posición, va al final del hito.
  def reorder
    milestone = params.key?(:milestone) ? milestone_or_inbox(params[:milestone]) : story.milestone
    raise Api::Error.validation("Falta position o milestone", hint: "mt reorder PG-49 --position 1 --reason \"…\"") unless params.key?(:position) || params.key?(:milestone)

    changed = story.reorder!(position: position_param, milestone: milestone, actor: Current.actor, reason: params[:reason])
    render_ok({ story: Api::Markdown::Formatting.story_data(story), position: story.position },
      summary: changed ? "#{story.reference} en la posición #{story.position} de #{Api::Markdown::Formatting.milestone_label(story.milestone)}" : "#{story.reference} ya estaba ahí",
      breadcrumbs: [ "mt roadmap" ])
  end

  private

  # Atributos desde `markdown` (formato de ver), desde campos sueltos o ambos.
  def story_attributes
    fields = params.permit(:title, :milestone, :state, :body, :mockup, :blocked_by, :labels, labels: [], blocked_by: []).to_h
    return fields if params[:markdown].blank?

    # Los campos sueltos mandan sobre el documento: mt create --file f.md --milestone M2.
    Api::StoryDocument.parse(params[:markdown]).except("number", "claimed_by").merge(fields)
  end

  def reject_fact_changes!(attributes)
    if attributes.key?("state") && attributes["state"].to_s != story.state
      raise Api::Error.validation("El estado no se cambia editando", hint: "Usa mt move #{story.reference} #{attributes['state']}")
    end
    if attributes.key?("milestone") && attributes["milestone"].to_s.presence != story.milestone&.code &&
        milestone_or_inbox(attributes["milestone"]) != story.milestone
      raise Api::Error.validation("El hito no se cambia editando", hint: "Usa mt reorder #{story.reference} --milestone #{attributes['milestone'].presence || 'inbox'} --reason \"…\"")
    end
  end

  def milestone_or_inbox(value)
    value.blank? || value.to_s.casecmp?("inbox") ? nil : find_milestone(value)
  end

  def position_param
    return :last unless params.key?(:position)

    position = Integer(params[:position].to_s, exception: false)
    raise Api::Error.validation("position tiene que ser un número desde 1", hint: "--position 1 la pone la primera") unless position&.positive?

    position
  end

  def filters = params.permit(:state, :milestone, :label, :claimed_by).to_h.map { |k, v| "#{k}: #{v}" }.join(", ")

  def filter_by_milestone(stories)
    value = params[:milestone].to_s
    return stories.where(milestone: nil) if value.casecmp?("inbox")

    stories.where(milestone: find_milestone(value))
  end

  def filter_by_claimed_by(stories)
    name = params[:claimed_by].casecmp?("me") ? Current.actor.name : params[:claimed_by].downcase
    stories.where(claimed_by: Actor.find_by(name: name))
  end

  def story_breadcrumbs
    case story.state
    when "ready" then [ "mt start #{story.reference}" ]
    when "in_progress" then story.claimed_by == Current.actor ? [ "mt done #{story.reference} --commit <sha>", "mt comment #{story.reference} \"…\"" ] : [ "mt next" ]
    when "idea", "defining" then [ "mt edit #{story.reference} --file <f.md>", "mt move #{story.reference} ready" ]
    else [ "mt next" ]
    end
  end
end
