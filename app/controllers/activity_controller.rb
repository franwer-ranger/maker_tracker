# La portada: lo que le toca a Fran en todos los proyectos (MT-30).
class ActivityController < ApplicationController
  layout "project"

  def show
    return redirect_to projects_path if Project.none?

    @project = current_project
    @cards = Activity.for_you
    @activity = Activity.new
    @in_progress = @activity.in_progress
    @qa = @activity.qa_pending
    @qa_undeployed = @activity.qa_undeployed_count
    @ready_work = ReadyWork.all.values
    @recent = @activity.recent_events if @cards.empty?
    @away = visit_home
  end

  private

  # Abrir la portada es mirarla (MT-31): se marca la visita y se enseña lo
  # cambiado desde la anterior.
  def visit_home
    now = Time.current
    since = Visit.open!(now: now, mark: !prefetch?)
    WhileAway.home(since: since || now, now: now)
  end

  # El de la barra lateral: el último que visitó o, si no, el más antiguo.
  def current_project
    Project.find_by(slug: session[:project_slug]) || Project.order(:created_at).first
  end
end
