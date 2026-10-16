# `mt comment PG-49 "…"`: preguntas y avances en la historia, en markdown.
class Api::CommentsController < Api::BaseController
  def create
    story.add_comment!(params.require(:body), actor: Current.actor)
    render_ok({ story: story.reference }, status: :created,
      summary: "#{Current.actor.name} commented on #{story.reference}.",
      breadcrumbs: [ "mt show #{story.reference}" ])
  end
end
