# Cambiar de estado una historia (arrastrar entre columnas del Tablero).
class Stories::StatesController < ApplicationController
  include ProjectScoped

  def update
    story = @project.stories.find_by!(number: params[:story_number])
    story.move_to!(params.expect(:state), actor: Current.actor)
    head :no_content
  rescue Story::ClaimedByOther, ArgumentError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end
end
