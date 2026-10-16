class ProjectsController < ApplicationController
  def index
    @projects = Project.order(:created_at)
    redirect_to project_path(@projects.first) if request.path == root_path && @projects.one?
    @project = Project.new
  end

  def create
    @project = Project.create_with_event!(project_params, actor: Current.actor)
    redirect_to project_brief_path(@project)
  rescue ActiveRecord::RecordInvalid => e
    @project = e.record
    @projects = Project.order(:created_at)
    render :index, status: :unprocessable_entity
  end

  private

  def project_params
    params.expect(project: %i[name key])
  end
end
