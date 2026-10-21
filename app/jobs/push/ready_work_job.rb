# Comprueba si un proyecto entra en poco trabajo (MT-47) un momento después de
# los hechos que pueden cambiarlo. Dos motivos para no hacerlo en el momento:
# una operación suele dejar varios hechos seguidos (`mt ask` suelta la historia
# y luego pregunta), y la pregunta tiene que avisar antes que el poco trabajo
# que deja; y así `ReadyWork` no se calcula dentro de la petición. Los hechos
# de un mismo proyecto en ese momento se comprueban una sola vez.
class Push::ReadyWorkJob < ApplicationJob
  DELAY = 3.seconds
  # Proyecto → si algún hecho de la tanda fue de Fran (entonces no avisa). En
  # memoria, como `Push::FlushJob`: con el adaptador `:async`, un solo proceso.
  PENDING = Concurrent::Map.new

  def self.schedule(project, notify:)
    human = !notify
    first = PENDING.put_if_absent(project.id, human).nil?
    PENDING[project.id] = true if human && !first
    set(wait: DELAY).perform_later(project) if first
  end

  discard_on ActiveJob::DeserializationError

  def perform(project)
    human = PENDING.delete(project.id)
    Push::Notifier.check_ready_work(project, notify: !human)
  rescue => e
    Rails.error.report(e, handled: true)
  end
end
