# Las operaciones de dominio hacen su cambio y registran su evento en la misma
# transacción. Sin callbacks: así se sabe quién y por qué, y las seeds pueden
# crear datos sin ruido.
module Eventable
  extend ActiveSupport::Concern

  # Reordenar como agente sin explicar por qué.
  class ReasonRequired < ArgumentError
    def initialize(msg = "Un agente tiene que dar un motivo para reordenar") = super
  end

  # Público para que las seeds puedan añadir eventos a mano.
  def record_event!(action, actor:, story: nil, data: {}, reason: nil)
    project = is_a?(Project) ? self : self.project
    project.events.create!(action: action, actor: actor, story: story, data: data, reason: reason.presence)
  end

  private

  def require_reason!(actor, reason)
    raise ReasonRequired if actor.agent? && reason.blank?
  end
end
