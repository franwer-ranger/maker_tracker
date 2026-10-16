# Reordenar una historia junto a otra ({ before: 49 } / { after: 49 }), que
# puede estar en otro hito, o llevarla al final de un hito vacío o de la
# bandeja ({ milestone: id | "ideas" }). Motivo opcional en `reason`.
class Stories::PositionsController < ApplicationController
  include ProjectScoped

  def update
    story = @project.stories.find_by!(number: params[:story_number])
    position, milestone = target
    story.reorder!(position: position, milestone: milestone, actor: Current.actor, reason: params[:reason])
    respond_to do |format|
      format.json { head :no_content }
      format.html { redirect_to project_story_path(@project, story) } # selector de hito de la Historia
    end
  rescue Eventable::ReasonRequired, ActiveRecord::RecordInvalid => e
    respond_to do |format|
      format.json { render json: { error: e.message }, status: :unprocessable_entity }
      format.html { redirect_to project_story_path(@project, story), alert: e.message }
    end
  end

  private

  def target
    relation, number = params.slice(:before, :after).to_unsafe_h.first
    if relation
      neighbor = @project.stories.find_by!(number: number)
      [ { relation.to_sym => neighbor }, neighbor.milestone ]
    elsif params[:milestone].present?
      [ :last, params[:milestone] == "ideas" ? nil : @project.milestones.find(params[:milestone]) ]
    else
      raise ActionController::BadRequest, "Falta before, after o milestone"
    end
  end
end
