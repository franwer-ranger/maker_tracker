# Reordenar una historia dentro de su hito, junto a otra: { before: 49 } o { after: 49 }.
class Stories::PositionsController < ApplicationController
  include ProjectScoped

  def update
    story = @project.stories.find_by!(number: params[:story_number])
    story.reorder!(position: target_position, actor: Current.actor, reason: params[:reason])
    head :no_content
  rescue Eventable::ReasonRequired, ActiveRecord::RecordInvalid => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def target_position
    relation, number = params.slice(:before, :after).to_unsafe_h.first
    raise ActionController::BadRequest, "Falta before o after" unless relation

    { relation.to_sym => @project.stories.find_by!(number: number) }
  end
end
