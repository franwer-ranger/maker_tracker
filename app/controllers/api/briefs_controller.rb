# `mt brief [--file f.md]`: el brief del proyecto en markdown.
class Api::BriefsController < Api::BaseController
  def show
    render_ok({ markdown: project.brief }, summary: "Brief de #{project.name}", breadcrumbs: [ "mt brief --file <f.md>" ])
  end

  def update
    text = params.require(:markdown).to_s
    changed = text.strip != project.brief.strip && project.edit_brief!(text, actor: Current.actor)
    render_ok({}, summary: changed ? "Brief de #{project.name} editado" : "El brief no cambia", breadcrumbs: [ "mt context" ])
  end
end
