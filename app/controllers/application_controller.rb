class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :set_current_actor

  private

  # Turbo precarga al pasar el ratón por un enlace: eso no es mirar (MT-31).
  def prefetch? = request.headers["X-Sec-Purpose"] == "prefetch"

  # Sin login: todo lo que pasa en la UI se atribuye al actor humano.
  def set_current_actor
    Current.actor = Actor.human
  end
end
