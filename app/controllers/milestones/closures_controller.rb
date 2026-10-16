# Cerrar (create) o reabrir (destroy) un hito.
class Milestones::ClosuresController < ApplicationController
  include ProjectScoped

  def create
    milestone.close!(actor: Current.actor)
    redirect_to project_roadmap_path(@project)
  end

  def destroy
    milestone.reopen!(actor: Current.actor)
    redirect_to project_roadmap_path(@project)
  end

  private

  def milestone = @project.milestones.find(params[:milestone_id])
end
