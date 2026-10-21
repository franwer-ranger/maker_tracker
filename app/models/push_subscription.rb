# Un dispositivo con los avisos push activados (MT-47). Cuelga del actor humano
# (no hay login); el navegador la identifica por su `endpoint`, la URL del
# servicio de push (Apple, Google, Mozilla) a la que se envía.
class PushSubscription < ApplicationRecord
  belongs_to :actor

  normalizes :user_agent, with: -> { it.to_s.first(255).presence }

  # Solo HTTPS: el servidor hace una petición a esta URL y no debe poder apuntar a la red interna en claro.
  validates :endpoint, presence: true, uniqueness: true, format: { with: %r{\Ahttps://\S+\z} }
  validates :p256dh, :auth, presence: true
end
