class StoriesController < ApplicationController
  include ProjectScoped

  def show
    @story = @project.stories.find_by!(number: params[:number])
  end

  # "+ Nueva idea" del Tablero: solo el título, en el hito filtrado o en la bandeja.
  def create
    milestone = @project.milestones.find_by(id: params.dig(:story, :milestone_id))
    @project.create_story!({ title: params.expect(story: [ :title ])[:title], milestone: milestone }, actor: Current.actor)
    redirect_back_or_to project_path(@project)
  rescue ActiveRecord::RecordInvalid => e
    redirect_back_or_to project_path(@project), alert: e.record.errors.full_messages.to_sentence
  end
end
