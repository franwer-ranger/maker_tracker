# Reordenar un hito junto a otro: { before: id } o { after: id }, con motivo opcional.
class Milestones::PositionsController < ApplicationController
  include ProjectScoped

  def update
    milestone = @project.milestones.find(params[:milestone_id])
    relation, id = params.slice(:before, :after).to_unsafe_h.first
    raise ActionController::BadRequest, "Falta before o after" unless relation

    milestone.reorder!(position: { relation.to_sym => @project.milestones.find(id) }, actor: Current.actor, reason: params[:reason])
    head :no_content
  rescue Eventable::ReasonRequired, ActiveRecord::RecordInvalid => e
    render json: { error: e.message }, status: :unprocessable_entity
  end
end
