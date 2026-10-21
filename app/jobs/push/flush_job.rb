# El resumen al cerrar la ventana de un proyecto (MT-47): lo que se aplazó
# dentro de los 10 minutos no sale suelto, sale un solo aviso al final con lo
# aplazado que aún espera a Fran (`Push::Notifier.summary`).
#
# Active Job va con el adaptador `:async`, en el proceso de Puma: si se
# reinicia entre medias se pierde el resumen, y es aceptable. Por eso también
# basta con recordar en memoria lo aplazado de cada proyecto; el primero que se
# aplaza programa el resumen, uno por ventana.
class Push::FlushJob < ApplicationJob
  DEFERRED = Concurrent::Map.new # id del proyecto → avisos aplazados
  LOCK = Mutex.new

  def self.defer(project, notice, at:)
    first = LOCK.synchronize do
      list = DEFERRED[project.id]
      DEFERRED[project.id] = [ *list, notice ]
      list.nil?
    end
    return unless first

    begin
      set(wait_until: at + 1.second).perform_later(project)
    rescue
      LOCK.synchronize { DEFERRED.delete(project.id) } # el siguiente aplazado lo vuelve a programar
      raise
    end
  end

  discard_on ActiveJob::DeserializationError

  def perform(project)
    deferred = LOCK.synchronize { DEFERRED.delete(project.id) } or return
    notice = Push::Notifier.summary(project, deferred) or return
    if Push.claim_window(project)
      Push.deliver(project, notice)
    else # justo antes salió otro aviso: lo aplazado espera a la ventana siguiente
      deferred.each { self.class.defer(project, it, at: project.reload.last_pushed_at + Push::WINDOW) }
    end
  rescue => e
    Rails.error.report(e, handled: true)
  end
end
