class MilestonesController < ApplicationController
  include ProjectScoped

  def create
    @project.create_milestone!(params.expect(milestone: %i[title goal]), actor: Current.actor)
    redirect_to project_roadmap_path(@project)
  rescue ActiveRecord::RecordInvalid => e
    redirect_to project_roadmap_path(@project), alert: e.record.errors.full_messages.join(". ")
  end
end
