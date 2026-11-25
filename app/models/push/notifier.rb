# Decide si un hecho avisa (MT-47, D-66). Lo llama `Event` al crearse (después
# del commit) y no hace nada más que decidir: el envío va en un job.
#
# Avisan solo los hechos de agentes: una pregunta bloqueante y un proyecto que
# entra en poco trabajo (`ReadyWork`, que se comprueba en `Push::ReadyWorkJob`).
# Lo que hay que probar ya no avisa: la QA es de Relay (MT-98, D-97).
# Como mucho un aviso por proyecto cada `Push::WINDOW`: el primero sale al
# momento y lo demás espera al resumen de `Push::FlushJob`.
class Push::Notifier
  # Los hechos que pueden cambiar cuántas Listas libres tiene un proyecto.
  READY_WORK_ACTIONS = /\A(story|question|milestone)\./

  def self.call(event) = new(event).call

  # El resumen al cerrar la ventana: solo lo que se aplazó dentro de ella
  # (`deferred`, los avisos que no salieron sueltos), y de eso, lo que
  # `Activity` aún tiene pendiente en ese momento: si Fran ya lo resolvió, no
  # cuenta. Nil si no queda nada.
  def self.summary(project, deferred)
    ids = ->(kind) { deferred.select { it.kind == kind }.flat_map(&:ids).uniq }
    cards = Activity.new.for_you.select { it.project == project }
    questions = cards.count { it.question? && it.question.id.in?(ids.(:question)) }
    low_work = deferred.any? { it.kind == :low_work } && cards.any? { it.kind == :low_work }

    parts = []
    parts << (questions == 1 ? "1 pregunta" : "#{questions} preguntas") if questions.positive?
    parts << "poco trabajo listo" if low_work
    total = questions + (low_work ? 1 : 0)
    return if total.zero?

    Push::Notice.new(title: "#{project.key} · #{total == 1 ? '1 cosa te toca' : "#{total} cosas te tocan"}",
      body: parts.join(", ").upcase_first, path: "/")
  end

  def initialize(event)
    @event = event
  end

  # Poco trabajo: avisa una vez al entrar y se rearma al salir. La marca
  # (`ready_low_notified_at`) se pone también cuando entra por algo que hizo
  # Fran (`notify: false`), para no avisar luego de ello. Lo llama
  # `Push::ReadyWorkJob`, un momento después del hecho (ver allí por qué).
  def self.check_ready_work(project, notify:)
    summary = ReadyWork.for(project)
    if !summary.low?
      project.update_column(:ready_low_notified_at, nil) if project.ready_low_notified_at
    elsif project.ready_low_notified_at.nil? &&
          Project.where(id: project.id, ready_low_notified_at: nil).update_all(ready_low_notified_at: Time.current) == 1 && notify
      send_or_defer(project, Push::Notice.new(title: low_work_title(project, summary.ready), body: "Abre Maker Tracker para definir las siguientes", path: "/", kind: :low_work))
    end
  end

  def self.low_work_title(project, ready)
    case ready
    when 0 then "A #{project.key} no le quedan historias Listas"
    when 1 then "A #{project.key} le queda 1 historia Lista"
    else "A #{project.key} le quedan #{ready} historias Listas"
    end
  end

  # El primero de la ventana sale ya; lo demás espera al resumen.
  def self.send_or_defer(project, notice)
    if Push.claim_window(project)
      Push.deliver(project, notice)
    else
      Push::FlushJob.defer(project, notice, at: project.reload.last_pushed_at + Push::WINDOW)
    end
  end

  def call
    return unless Push.configured? && PushSubscription.exists?

    project = event.project
    # También con lo que hace Fran: así se marca y no se avisa después de algo que hizo él.
    Push::ReadyWorkJob.schedule(project, notify: event.actor.agent?) if event.action.match?(READY_WORK_ACTIONS)
    return unless event.actor.agent?

    notice = question_notice
    self.class.send_or_defer(project, notice) if notice
  rescue => e
    Rails.error.report(e, handled: true) # avisar no puede romper el hecho que lo provocó
  end

  private

  attr_reader :event

  def question_notice
    return unless event.action == "question.asked" && event.data["blocking"] && event.story

    Push::Notice.new(title: "#{event.story.reference} · pregunta de #{event.actor.name}", body: event.data["title"].to_s, path: story_path(event.story),
      kind: :question, ids: [ event.data["question_id"] ])
  end

  def story_path(story) = Rails.application.routes.url_helpers.project_story_path(story.project, story)
end
