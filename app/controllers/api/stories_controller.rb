class Api::StoriesController < Api::BaseController
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

  private

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
