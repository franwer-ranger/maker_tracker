# Un dispositivo con los avisos push activados (MT-47). Cuelga del actor humano
# (no hay login); el navegador la identifica por su `endpoint`, la URL del
# servicio de push (Apple, Google, Mozilla, Microsoft) a la que se envía.
#
# El servidor hace una petición a ese `endpoint`, así que solo se aceptan los
# servicios de push conocidos, por HTTPS y en el puerto 443: nadie puede hacer
# que el servidor llame a otra máquina (de la tailnet o de fuera).
class PushSubscription < ApplicationRecord
  # Hosts exactos y sufijos (`.dominio`) de los servicios de push de los navegadores.
  # jmt17.google.com es el de Chromium sin marca (el que usan las pruebas con Playwright).
  PUSH_HOSTS = %w[fcm.googleapis.com jmt17.google.com web.push.apple.com].freeze
  PUSH_HOST_SUFFIXES = %w[.push.services.mozilla.com .notify.windows.com].freeze
  # Como mucho tantos dispositivos: es una sola persona.
  LIMIT = 50
  BASE64URL = /\A[A-Za-z0-9_-]+={0,2}\z/

  belongs_to :actor

  normalizes :user_agent, with: -> { it.to_s.first(255).presence }

  validates :endpoint, presence: true, uniqueness: true, length: { maximum: 2048, message: "es demasiado largo" }
  validates :p256dh, presence: true, length: { maximum: 100, message: "es demasiado largo" }, format: { with: BASE64URL }
  validates :auth, presence: true, length: { maximum: 30, message: "es demasiado largo" }, format: { with: BASE64URL }
  validate :endpoint_is_a_push_service
  validate :under_the_limit, on: :create

  def self.push_service?(endpoint)
    uri = URI.parse(endpoint.to_s)
    host = uri.host.to_s.downcase
    uri.is_a?(URI::HTTPS) && uri.userinfo.nil? && uri.port == 443 &&
      (PUSH_HOSTS.include?(host) || PUSH_HOST_SUFFIXES.any? { host.end_with?(it) && host.length > it.length })
  rescue URI::InvalidURIError
    false
  end

  # Las claves del navegador se pueden leer como un punto de la curva P-256. Si
  # no, la suscripción nunca podrá recibir nada.
  def keys_valid?
    group = OpenSSL::PKey::EC::Group.new("prime256v1")
    OpenSSL::PKey::EC::Point.new(group, OpenSSL::BN.new(Base64.urlsafe_decode64(p256dh), 2))
    Base64.urlsafe_decode64(auth).bytesize == 16
  rescue ArgumentError, OpenSSL::PKey::EC::Point::Error, OpenSSL::PKey::ECError, OpenSSL::BNError
    false
  end

  private

  def endpoint_is_a_push_service
    errors.add(:endpoint, "no es de un servicio de push conocido") unless self.class.push_service?(endpoint)
  end

  def under_the_limit
    errors.add(:base, "Ya hay #{LIMIT} dispositivos con avisos: desactiva alguno") if self.class.count >= LIMIT
  end
end
