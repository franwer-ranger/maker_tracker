# Hitos por la API (#018): crear, editar título y objetivo, reordenar (con
# motivo), cerrar y reabrir. Se citan por su código (M2) o su título.
class Api::MilestonesController < Api::BaseController
  def create
    milestone = project.create_milestone!(params.permit(:title, :goal).to_h.with_defaults("title" => nil), actor: Current.actor)
    render_ok(milestone_data(milestone), status: :created,
      summary: "#{label(milestone)} created at the end of the roadmap.",
      breadcrumbs: [ "mt milestone reorder #{milestone.code} --position 1 --reason \"…\"", "mt roadmap" ])
  end

  def update
    changed = milestone.edit!(params.permit(:title, :goal).to_h, actor: Current.actor)
    render_ok(milestone_data(milestone), summary: changed ? "#{label(milestone)} edited." : "#{label(milestone)} did not change.",
      breadcrumbs: [ "mt roadmap" ])
  end

  def reorder
    position = Integer(params.require(:position).to_s, exception: false)
    raise Api::Error.validation("position must be a number from 1.", hint: "--position 1 puts it first.") unless position&.positive?

    from = milestone.code
    changed = milestone.reorder!(position: position, actor: Current.actor, reason: params[:reason])
    render_ok(milestone_data(milestone),
      summary: changed ? "#{from} is now #{label(milestone)}." : "#{label(milestone)} was already there.",
      breadcrumbs: [ "mt roadmap" ])
  end

  def close
    changed = milestone.close!(actor: Current.actor)
    render_ok(milestone_data(milestone), summary: changed ? "#{label(milestone)} closed." : "#{label(milestone)} was already closed.",
      breadcrumbs: [ "mt roadmap", "mt milestone reopen #{milestone.code}" ])
  end

  def reopen
    changed = milestone.reopen!(actor: Current.actor)
    render_ok(milestone_data(milestone), summary: changed ? "#{label(milestone)} reopened." : "#{label(milestone)} was already open.",
      breadcrumbs: [ "mt roadmap" ])
  end

  private

  def milestone = @milestone ||= find_milestone(params[:code])

  def label(milestone) = Api::Markdown::Formatting.milestone_label(milestone)

  def reason_required_error
    reason_error("reordering", "mt milestone reorder #{milestone.code} --position #{params[:position]} --reason \"why it goes there\"")
  end

  def milestone_data(milestone)
    { milestone: { code: milestone.code, title: milestone.title, goal: milestone.goal, closed: milestone.closed? } }
  end
end
