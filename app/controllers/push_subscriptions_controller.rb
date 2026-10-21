# Activar y desactivar los avisos push en un dispositivo (MT-47). Lo llama el
# controlador Stimulus `push` con JSON; el navegador solo conoce el `endpoint`,
# así que se guarda y se borra por él. Sin login: la suscripción es del actor
# humano.
#
# Guardar una que ya existe solo vale si trae las mismas claves (el navegador
# la vuelve a mandar en cada carga): quien conozca un `endpoint` no puede
# cambiarle las claves para leer sus avisos. Si el navegador renueva la
# suscripción, trae otro `endpoint`.
class PushSubscriptionsController < ApplicationController
  def create
    keys = params.expect(keys: %i[p256dh auth])
    subscription = PushSubscription.find_or_initialize_by(endpoint: params.expect(:endpoint))
    if subscription.persisted? && (subscription.p256dh != keys[:p256dh] || subscription.auth != keys[:auth])
      return render json: { error: "Esa suscripción ya existe con otras claves." }, status: :conflict
    end

    subscription.update!(actor: Current.actor, p256dh: keys[:p256dh], auth: keys[:auth], user_agent: request.user_agent)
    head :no_content
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.record.errors.full_messages.to_sentence }, status: :unprocessable_entity
  end

  def destroy
    PushSubscription.where(endpoint: params.expect(:endpoint)).destroy_all
    head :no_content
  end
end
