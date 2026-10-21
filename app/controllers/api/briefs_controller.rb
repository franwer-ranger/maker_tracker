# `mt brief [--file f.md]`: el brief del proyecto en markdown. Se lee con su
# versión en un frontmatter (`---\nversion: 3\n---`) y se escribe con él: si el
# brief cambió entretanto, CONFLICT (MT-37). Sin frontmatter no se comprueba.
class Api::BriefsController < Api::BaseController
  VERSION_HEADER = /\A---[ \t]*\r?\nversion:[ \t]*(\d+)[ \t]*\r?\n---[ \t]*(?:\r?\n)*/

  def show
    render_ok({ markdown: "---\nversion: #{project.brief_version}\n---\n\n#{project.brief}", version: project.brief_version },
      summary: "Brief of #{project.name}.", breadcrumbs: [ "mt brief --file <f.md>" ])
  end

  def update
    text = params.require(:markdown).to_s
    version = params[:version].presence&.to_i
    if (match = text.match(VERSION_HEADER))
      version ||= match[1].to_i
      text = match.post_match
    end
    text = project.brief if text.strip == project.brief.strip # solo espacios: no cuenta
    changed = project.edit_brief!(text, actor: Current.actor, version: version)
    render_ok({ version: project.brief_version }, summary: changed ? "Brief of #{project.name} edited by #{Current.actor.name}." : "The brief did not change.",
      breadcrumbs: [ "mt context" ])
  end
end
