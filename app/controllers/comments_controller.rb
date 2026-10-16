class CommentsController < ApplicationController
  include ProjectScoped

  def create
    story = @project.stories.find_by!(number: params[:story_number])
    story.add_comment!(params.expect(comment: [ :body ])[:body], actor: Current.actor)
    redirect_to project_story_path(@project, story, anchor: "comentarios")
  rescue ActiveRecord::RecordInvalid => e
    redirect_to project_story_path(@project, story, anchor: "comentarios"), alert: e.record.errors.full_messages.join(". ")
  end
end
