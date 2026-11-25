# Las decisiones solo se añaden: no hay editar ni borrar.
class DecisionsController < ApplicationController
  include ProjectScoped

  def create
    attributes = params.expect(decision: %i[title body story_number supersedes_id])
    story = @project.stories.find_by(number: attributes.delete(:story_number).presence)
    supersedes_id = attributes.delete(:supersedes_id).presence
    supersedes = supersedes_id && @project.decisions.find_by(id: supersedes_id)
    return redirect_to(project_brief_path(@project), alert: "La decisión que sustituye no existe.") if supersedes_id && !supersedes

    @project.record_decision!(attributes.merge(story: story, supersedes: supersedes), actor: Current.actor)
    redirect_to project_brief_path(@project)
  rescue ActiveRecord::RecordInvalid => e
    redirect_to project_brief_path(@project), alert: e.record.errors.full_messages.join(". ")
  end
end
