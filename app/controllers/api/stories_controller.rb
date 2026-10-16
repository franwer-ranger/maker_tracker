class Api::StoriesController < Api::BaseController
  CREATABLE_STATES = %w[idea defining ready].freeze

  # `mt list`: filtros state, milestone (M2, su título o inbox), label y
  # claimed_by (un nombre o "me"). Las columnas, como en docs/CLI.md.
  def index
    stories = project.stories.includes(:milestone, :claimed_by, :project)
    if params[:state].present?
      raise Api::Error.validation("unknown state: #{params[:state]}.", hint: "the states are #{Story.states.keys.join(', ')}.") unless Story.states.key?(params[:state])

      stories = stories.where(state: params[:state])
    end
    stories = filter_by_milestone(stories) if params[:milestone].present?
    stories = filter_by_claimed_by(stories) if params[:claimed_by].present?
    stories = stories.select { it.labels.include?(params[:label]) } if params[:label].present?
    stories = stories.to_a.sort_by { [ it.milestone ? it.milestone.position : Float::INFINITY, it.position ] }

    done = project.stories.done.pluck(:number)
    summary = list_summary(stories.size)
    render_ok({ stories: stories.map { Api::Markdown::Formatting.story_data(it, done_numbers: done) },
                markdown: [ summary, list_lines(stories).join("\n").presence ].compact.join("\n\n") + "\n" },
      summary: summary)
  end

  # `mt show PG-49`: la historia en el formato de docs/backlog/.
  def show
    render_ok({ story: Api::Markdown::Formatting.story_data(story, done_numbers: project.stories.done.pluck(:number)),
                markdown: Api::Markdown::Story.new(story).to_s },
      summary: "#{story.reference} · #{story.title} (#{state_words(story.state)})",
      breadcrumbs: story_breadcrumbs)
  end

  # `mt create "Título" [--milestone M2] [--state …] [--number 14] [--file f.md]`:
  # con campos o con `markdown` en el formato de ver. Nace como Idea y en la
  # bandeja si no se dice otra cosa; sin cuerpo, con la plantilla. Con `number`
  # (#025, para migrar un backlog) usa ese número si está libre.
  def create
    attributes = story_attributes
    number = requested_number(attributes.delete("number"))
    state = attributes.delete("state").presence || "idea"
    unless CREATABLE_STATES.include?(state)
      raise Api::Error.validation("a new story starts as #{CREATABLE_STATES.to_sentence(two_words_connector: ' or ', last_word_connector: ' or ')}, not #{state}.",
        hint: "create it and then use mt start or mt done.")
    end
    milestone = attributes.key?("milestone") ? milestone_or_inbox(attributes.delete("milestone")) : nil
    attributes.delete("body") if attributes["body"].blank?

    created = project.create_story!(attributes.merge("state" => state, "milestone" => milestone, "number" => number).compact, actor: Current.actor)
    render_ok({ story: Api::Markdown::Formatting.story_data(created) },
      status: :created, warnings: created.ready? ? Api::Markdown::Formatting.readiness_warnings(created) : [],
      summary: "#{created.reference} created as #{state_words(created.state)} in #{Api::Markdown::Formatting.milestone_label(created.milestone)}.",
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
      warnings: story.ready? ? Api::Markdown::Formatting.readiness_warnings(story) : [],
      summary: changed ? "#{story.reference} edited: #{fields.join(', ')}." : "#{story.reference} did not change.",
      breadcrumbs: [ "mt show #{story.reference}" ])
  end

  # `mt move PG-49 ready`. Pasar a Lista sin cumplir la regla es un warning.
  def move
    state = params.require(:state).to_s
    raise Api::Error.validation("unknown state: #{state}.", hint: "the states are #{Story.states.keys.join(', ')}.") unless Story.states.key?(state)
    raise Story::ClaimedByOther, story if Current.actor.agent? && story.in_progress? && story.claimed_by && story.claimed_by != Current.actor

    changed = story.move_to!(state, actor: Current.actor, reason: params[:reason])
    warnings = state == "ready" ? Api::Markdown::Formatting.readiness_warnings(story) : []
    breadcrumbs = if warnings.any? then [ "mt edit #{story.reference} --file <f.md>", "mt next" ]
    elsif state == "ready" then [ "mt show #{story.reference}", "mt next" ]
    else [ "mt show #{story.reference}", "mt roadmap" ]
    end
    render_ok({ story: Api::Markdown::Formatting.story_data(story) }, warnings: warnings,
      summary: changed ? "#{story.reference} moved to #{state_words(state)}." : "#{story.reference} was already #{state_words(state)}.",
      breadcrumbs: breadcrumbs)
  end

  # `mt reorder PG-49 --position 1 [--milestone M3] --reason "…"`. Las
  # posiciones se cuentan desde 1; sin posición, va al final del hito.
  def reorder
    milestone = params.key?(:milestone) ? milestone_or_inbox(params[:milestone]) : story.milestone
    raise Api::Error.validation("reordering needs a position or a milestone.", hint: "mt reorder #{story.reference} --position 1 --reason \"why it goes first\"") unless params.key?(:position) || params.key?(:milestone)

    changed = story.reorder!(position: position_param, milestone: milestone, actor: Current.actor, reason: params[:reason])
    render_ok({ story: Api::Markdown::Formatting.story_data(story), position: story.position },
      summary: changed ? "#{story.reference} is now number #{story.position} in #{Api::Markdown::Formatting.milestone_label(story.milestone)}." : "#{story.reference} was already there.",
      breadcrumbs: [ "mt roadmap" ])
  end

  private

  # Atributos desde `markdown` (formato de ver), desde campos sueltos o ambos.
  def story_attributes
    fields = params.permit(:number, :title, :milestone, :state, :body, :mockup, :blocked_by, :labels, labels: [], blocked_by: []).to_h
    return fields if params[:markdown].blank?

    # Los campos sueltos mandan sobre el documento: mt create --file f.md --milestone M2.
    Api::StoryDocument.parse(params[:markdown]).except("claimed_by").merge(fields)
  end

  # El número pedido al crear, si está libre. Editar lo ignora.
  def requested_number(value)
    return if value.blank?

    number = Integer(value.to_s, exception: false)
    raise Api::Error.validation("number must be a whole number from 1, not #{value}.", hint: "leave it out to get the next one.") unless number&.positive?

    if project.stories.exists?(number: number)
      raise Api::Error.validation("#{project.key}-#{number} already exists.",
        hint: "leave number out to get the next one (#{project.key}-#{project.last_story_number + 1}), or see it with mt show #{project.key}-#{number}.")
    end
    number
  end

  def reject_fact_changes!(attributes)
    if attributes.key?("state") && attributes["state"].to_s != story.state
      raise Api::Error.validation("editing does not change the state.", hint: "mt move #{story.reference} #{attributes['state']}")
    end
    if attributes.key?("milestone") && milestone_or_inbox(attributes["milestone"]) != story.milestone
      target = milestone_or_inbox(attributes["milestone"])&.code || "inbox"
      raise Api::Error.validation("editing does not change the milestone.", hint: "mt reorder #{story.reference} --milestone #{target} --reason \"why it goes there\"")
    end
  end

  def milestone_or_inbox(value)
    value.blank? || value.to_s.casecmp?("inbox") ? nil : find_milestone(value)
  end

  def position_param
    return :last unless params.key?(:position)

    position = Integer(params[:position].to_s, exception: false)
    raise Api::Error.validation("position must be a number from 1.", hint: "--position 1 puts it first.") unless position&.positive?

    position
  end

  # "3 ready stories", "6 stories in M3 with label ui"
  def list_summary(count)
    noun = count == 1 ? "story" : "stories"
    noun = "#{state_words(params[:state])} #{noun}" if params[:state].present?
    parts = [ "#{count} #{noun}" ]
    parts << "in #{params[:milestone].to_s.casecmp?('inbox') ? 'the inbox' : find_milestone(params[:milestone]).code}" if params[:milestone].present?
    parts << "with label #{params[:label]}" if params[:label].present?
    parts << "claimed by #{params[:claimed_by].casecmp?('me') ? Current.actor.name : params[:claimed_by].downcase}" if params[:claimed_by].present?
    parts.join(" ")
  end

  # PG-49  Plantillas de post reutilizables            M2  editor, ui
  # Con --state no hace falta la columna del estado.
  def list_lines(stories)
    rows = stories.map do |story|
      [ (state_words(story.state) unless params[:state].present?), story.reference, story.title,
        story.milestone&.code || "inbox", story.labels.join(", ") ].compact
    end
    min = params[:state].present? ? [ 0, Api::Markdown::Formatting::TITLE_WIDTH ] : [ Api::Markdown::Roadmap::STATE_WIDTH, 0, Api::Markdown::Formatting::TITLE_WIDTH ]
    Api::Markdown::Formatting.table(rows, min: min)
  end

  def state_words(state) = Api::Markdown::Formatting.state_words(state)

  def reason_required_error
    hint = [ "mt reorder #{story.reference}", ("--position #{params[:position]}" if params.key?(:position)),
             ("--milestone #{params[:milestone]}" if params.key?(:milestone)),
             "--reason \"#{params[:position].to_s == '1' ? 'why it goes first' : 'why it goes there'}\"" ].compact.join(" ")
    reason_error("reordering", hint)
  end

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
