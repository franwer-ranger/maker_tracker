# Hitos por la API (#018): crear, editar título y objetivo, reordenar (con
# motivo), cerrar y reabrir. Se citan por su código (M2) o su título.
class Api::MilestonesController < Api::BaseController
  def create
    milestone = project.create_milestone!(params.permit(:title, :goal).to_h.with_defaults("title" => nil), actor: Current.actor)
    render_ok(milestone_data(milestone), status: :created,
      summary: "#{milestone.code} · #{milestone.title} creado al final del roadmap",
      breadcrumbs: [ "mt milestone reorder #{milestone.code} --position 1 --reason \"…\"", "mt roadmap" ])
  end

  def update
    changed = milestone.edit!(params.permit(:title, :goal).to_h, actor: Current.actor)
    render_ok(milestone_data(milestone), summary: changed ? "#{milestone.code} editado" : "#{milestone.code} sin cambios", breadcrumbs: [ "mt roadmap" ])
  end

  def reorder
    position = Integer(params.require(:position).to_s, exception: false)
    raise Api::Error.validation("position tiene que ser un número desde 1", hint: "--position 1 lo pone el primero") unless position&.positive?

    from = milestone.code
    changed = milestone.reorder!(position: position, actor: Current.actor, reason: params[:reason])
    render_ok(milestone_data(milestone),
      summary: changed ? "#{from} pasa a ser #{milestone.code} · #{milestone.title}" : "#{milestone.code} ya estaba ahí",
      breadcrumbs: [ "mt roadmap" ])
  end

  def close
    changed = milestone.close!(actor: Current.actor)
    render_ok(milestone_data(milestone), summary: changed ? "#{milestone.code} cerrado" : "#{milestone.code} ya estaba cerrado",
      breadcrumbs: [ "mt roadmap", "mt milestone reopen #{milestone.code}" ])
  end

  def reopen
    changed = milestone.reopen!(actor: Current.actor)
    render_ok(milestone_data(milestone), summary: changed ? "#{milestone.code} reabierto" : "#{milestone.code} ya estaba abierto",
      breadcrumbs: [ "mt roadmap" ])
  end

  private

  def milestone = @milestone ||= find_milestone(params[:code])

  def milestone_data(milestone)
    { milestone: { code: milestone.code, title: milestone.title, goal: milestone.goal, closed: milestone.closed? } }
  end
end
