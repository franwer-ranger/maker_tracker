# Cambiar de estado una historia: arrastrando en el Tablero (JSON) o con el
# selector de estado de la Historia (HTML).
class Stories::StatesController < ApplicationController
  include ProjectScoped

  def update
    story = @project.stories.find_by!(number: params[:story_number])
    story.move_to!(params.expect(:state), actor: Current.actor)
    respond_to do |format|
      format.json { head :no_content }
      format.html { redirect_to project_story_path(@project, story) }
    end
  rescue Story::ClaimedByOther, ArgumentError => e
    respond_to do |format|
      format.json { render json: { error: e.message }, status: :unprocessable_entity }
      format.html { redirect_to project_story_path(@project, story), alert: e.message }
    end
  end
end
