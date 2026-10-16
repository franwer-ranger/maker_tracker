# `mt roadmap [--closed]`: generado en vivo desde los hitos y sus historias.
class Api::RoadmapsController < Api::BaseController
  def show
    roadmap = Api::Markdown::Roadmap.new(project, closed: ActiveModel::Type::Boolean.new.cast(params[:closed]))
    done = roadmap.done_numbers
    milestones = roadmap.milestones.map do |milestone|
      { code: milestone.code, title: milestone.title, goal: milestone.goal, closed: milestone.closed?,
        stories: milestone.stories.map { Api::Markdown::Formatting.story_data(it, done_numbers: done) } }
    end
    render_ok({ milestones: milestones, ideas: roadmap.ideas.map { Api::Markdown::Formatting.story_data(it, done_numbers: done) },
                markdown: roadmap.to_s },
      summary: "Roadmap of #{project.name}: #{Api::Markdown::Formatting.plural(milestones.size, 'milestone')}.",
      breadcrumbs: [ "mt next", *("mt show #{roadmap.next_story.reference}" if roadmap.next_story) ])
  end
end
