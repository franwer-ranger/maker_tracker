# Envía un aviso a un dispositivo (MT-47). Un job por suscripción y aviso, sin
# reintentos: si se pierde, la pantalla de Actividad sigue siendo la fuente de
# verdad. Una suscripción caducada (410) o desconocida (404) se borra; el resto
# de errores se registran y ya está.
class Push::DeliverJob < ApplicationJob
  discard_on ActiveJob::DeserializationError # la suscripción se borró entre medias

  def perform(subscription, payload)
    WebPush.payload_send(message: payload.to_json, endpoint: subscription.endpoint, p256dh: subscription.p256dh,
      auth: subscription.auth, vapid: Push.vapid, ttl: 1.day.to_i, urgency: "high")
    subscription.update_column(:last_sent_at, Time.current)
  rescue WebPush::ExpiredSubscription, WebPush::InvalidSubscription
    subscription.destroy
  rescue => e # WebPush::Unauthorized (claves cambiadas), errores del servicio, red…
    Rails.error.report(e, handled: true, context: { push_host: URI.parse(subscription.endpoint).host })
  end
end
