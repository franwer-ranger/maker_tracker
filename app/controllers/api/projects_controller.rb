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

  # `mt project create "Postgram" --key PG` (#027): un agente puede crear
  # proyectos. El brief nace con su plantilla.
  def create
    attributes = params.permit(:name, :key).to_h.with_defaults("name" => nil, "key" => nil)
    key = attributes["key"].to_s.strip.upcase
    if key.present? && Project.exists?(key: key)
      raise Api::Error.validation("project #{key} already exists.", hint: "pick another key, or use mt init #{key} if it is yours.")
    end

    project = begin
      Project.create_with_event!(attributes, actor: Current.actor)
    rescue ActiveRecord::RecordInvalid => e
      raise Api::Error.validation("#{e.record.errors.full_messages.to_sentence}.", details: e.record.errors.to_hash(true),
        hint: "mt project create \"Name\" --key PG (the key has 2 to 5 letters and names the stories: PG-49).")
    end
    render_ok({ project: { key: project.key, name: project.name } }, status: :created,
      summary: "#{project.key} · #{project.name} created by #{Current.actor.name}.",
      breadcrumbs: [ "mt init #{project.key} --claude", "mt brief --file <f.md>" ])
  end
end
