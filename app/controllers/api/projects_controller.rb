class Api::ProjectsController < Api::BaseController
  def index
    projects = Project.order(:name)
    in_progress = Story.in_progress.group(:project_id).count
    data = projects.map do |project|
      milestone = project.current_milestone
      { key: project.key, name: project.name,
        current_milestone: milestone && { code: milestone.code, title: milestone.title },
        in_progress: in_progress.fetch(project.id, 0) }
    end
    rows = data.map do |p|
      milestone = p[:current_milestone] ? "#{p[:current_milestone][:code]} · #{p[:current_milestone][:title]}" : "no open milestone"
      [ p[:key], p[:name], milestone, "#{p[:in_progress]} in progress" ]
    end
    summary = "#{Api::Markdown::Formatting.plural(data.size, 'project')}."

    markdown = [ summary, Api::Markdown::Formatting.table(rows).join("\n").presence ].compact.join("\n\n")

    render_ok({ actor: Current.actor.name, projects: data, markdown: markdown },
      summary: summary,
      breadcrumbs: data.first(3).map { "mt init #{it[:key]}" })
  end
end
