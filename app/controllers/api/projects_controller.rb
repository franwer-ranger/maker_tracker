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
    markdown = data.map do |p|
      milestone = p[:current_milestone] ? "#{p[:current_milestone][:code]} #{p[:current_milestone][:title]}" : "sin hitos abiertos"
      "- **#{p[:key]}** #{p[:name]} · #{milestone} · #{p[:in_progress]} en curso"
    end.join("\n")

    render_ok({ projects: data, markdown: markdown },
      summary: "#{data.size} #{data.size == 1 ? 'proyecto' : 'proyectos'}",
      breadcrumbs: data.first(3).map { "mt init #{it[:key]}" })
  end
end
