# «Ya está al día» de una historia con documentación pendiente (MT-91): Fran
# da por actualizadas las páginas que quedaron sin enlazar al cerrarla. Los
# agentes lo resuelven editándolas y con `mt done` otra vez.
class Stories::DocumentationsController < ApplicationController
  include ProjectScoped

  def create
    story = @project.stories.find_by!(number: params[:story_number])
    pages = story.document!(actor: Current.actor, marked: true)
    notice = pages.any? ? "#{story.reference}: documentación al día (#{pages.map(&:slug).join(', ')})." : "#{story.reference} no tenía documentación pendiente."
    redirect_back_or_to project_story_path(@project, story), notice: notice, status: :see_other
  end
end
