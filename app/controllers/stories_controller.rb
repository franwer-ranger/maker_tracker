class StoriesController < ApplicationController
  include ProjectScoped

  before_action :set_story, only: %i[show edit update]

  def show
  end

  def edit
  end

  # Título, cuerpo y propiedades, con Story#edit! (deja story.edited).
  def update
    @story.edit!(story_params, actor: Current.actor)
    redirect_to project_story_path(@project, @story)
  rescue ActiveRecord::RecordInvalid
    render :edit, status: :unprocessable_entity
  end

  # "+ Nueva idea" del Tablero y del Roadmap: solo el título, en el hito o en la bandeja.
  def create
    milestone = @project.milestones.find_by(id: params.dig(:story, :milestone_id))
    @project.create_story!({ title: params.expect(story: [ :title ])[:title], milestone: milestone }, actor: Current.actor)
    redirect_back_or_to project_path(@project)
  rescue ActiveRecord::RecordInvalid => e
    redirect_back_or_to project_path(@project), alert: e.record.errors.full_messages.join(". ")
  end

  private

  def set_story
    @story = @project.stories.find_by!(number: params[:number])
  end

  def story_params
    params.expect(story: %i[title body mockup labels blocked_by])
  end
end
