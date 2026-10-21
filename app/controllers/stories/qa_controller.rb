# «Probada» y «Falla» de la QA pendiente (MT-32), desde Actividad o desde la
# historia. Como en la API, la UI es siempre el actor humano.
class Stories::QaController < ApplicationController
  include ProjectScoped

  def create
    story = @project.stories.find_by!(number: params[:story_number])
    unless %w[ok fail].include?(params[:result])
      return redirect_back_or_to project_story_path(@project, story), alert: "Elige «Probada» o «Falla».", status: :see_other
    end

    notice = if params[:result] == "fail"
      fix = story.qa_fail!(note: params[:note], actor: Current.actor)
      "#{story.reference} falla: #{fix.reference} queda en Definiendo."
    else
      story.qa_pass!(actor: Current.actor, note: params[:note])
      "#{story.reference} probada."
    end
    redirect_back_or_to project_story_path(@project, story), notice: notice, status: :see_other
  rescue Story::Qa::NotPending, Story::Qa::NoteRequired => e
    redirect_back_or_to project_story_path(@project, story), alert: e.message, status: :see_other
  end
end
