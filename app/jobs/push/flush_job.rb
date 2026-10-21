# El resumen al cerrar la ventana de un proyecto (MT-47): lo que pasó dentro de
# los 10 minutos no sale suelto, sale un solo aviso calculado al final con lo
# que aún espera a Fran (`Push::Notifier.summary`).
#
# Active Job va con el adaptador `:async`, en el proceso de Puma: si se
# reinicia entre medias se pierde el resumen, y es aceptable. Por eso también
# basta con recordar en memoria qué proyectos tienen ya su resumen programado.
class Push::FlushJob < ApplicationJob
  SCHEDULED = Concurrent::Set.new

  # Programa el resumen del proyecto si no lo está ya: uno por ventana.
  def self.schedule(project, at:)
    set(wait_until: at + 1.second).perform_later(project) if SCHEDULED.add?(project.id)
  end

  discard_on ActiveJob::DeserializationError

  def perform(project)
    SCHEDULED.delete(project.id)
    notice = Push::Notifier.summary(project) or return
    Push.deliver(project, notice) if Push.claim_window(project)
  rescue => e
    Rails.error.report(e, handled: true)
  end
end
