class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :set_current_actor

  private

  # Sin login: todo lo que pasa en la UI se atribuye al actor humano.
  def set_current_actor
    Current.actor = Actor.human
  end
end
