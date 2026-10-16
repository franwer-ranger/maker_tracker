# Brief (5.5): la visión del proyecto en markdown y sus decisiones.
class BriefsController < ApplicationController
  include ProjectScoped

  before_action :set_decisions, only: %i[show edit update]

  def show
  end

  def edit
  end

  def update
    @project.edit_brief!(params.expect(project: [ :brief ])[:brief], actor: Current.actor)
    redirect_to project_brief_path(@project)
  rescue ActiveRecord::RecordInvalid
    render :edit, status: :unprocessable_entity
  end

  private

  def set_decisions
    @decisions = @project.decisions.reorder(number: :desc).includes(:actor, :story, :supersedes, :superseded_by)
    @last_edit = @project.events.where(action: "brief.edited").maximum(:occurred_at)
  end
end
