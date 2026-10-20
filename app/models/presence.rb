# Quién está trabajando ahora (historia MT-36, D-46). Estado efímero: no es una
# tabla ni genera eventos. Cada petición autenticada a la API apunta aquí a su
# actor; un actor cuenta como activo WINDOW desde su última petición y deja de
# estarlo solo, sin señal de fin.
#
# Vive en memoria del proceso: leer no escribe en SQLite y, si el servidor se
# reinicia, se pierde sin daño (a los 60 s ya no valdría). Maker Tracker corre
# en un solo proceso de Puma; con varios workers cada uno vería solo a sus
# actores y habría que mover el registro a una caché compartida.
#
# Los cambios (empieza a estar activo, pasa de leer a escribir, cambia de
# historia, deja de estarlo) y cada escritura se emiten por Turbo Streams a
# `[project, :presence]` y `:presence` (la portada).
module Presence
  WINDOW = 60.seconds
  MODES = %i[reading writing].freeze

  # Detalle público de un actor activo. `target`: la historia (MT-36) o la
  # entidad (milestone M2, brief…) que toca; `detail`: la última escritura.
  Entry = Data.define(:actor, :project_key, :target, :mode, :detail, :seen_at) do
    def project = Project.find_by(key: project_key)
    def reading? = mode == :reading
    def writing? = mode == :writing
    def active?(now = Time.current) = seen_at > now - WINDOW
  end

  REGISTRY = Concurrent::Map.new
  TIMERS = Concurrent::Map.new

  class << self
    # Una petición del actor. Una lectura no pisa a una escritura reciente de la
    # misma historia (un agente que escribe y relee sigue «escribiendo»).
    def touch(actor, project_key:, target: nil, mode:, detail: nil)
      raise ArgumentError, "mode: #{mode}" unless MODES.include?(mode)

      previous = current(actor)
      if previous && mode == :reading && previous.writing? && previous.target == target
        mode, detail = previous.mode, previous.detail
      end
      entry = Entry.new(actor: actor, project_key: project_key, target: target, mode: mode, detail: detail, seen_at: Time.current)
      REGISTRY[actor.id] = entry
      schedule_expiry(entry)
      broadcast_presence(entry.project) if changed?(previous, entry)
      entry
    end

    # Una escritura ya hecha por el actor de la petición: dice qué ha cambiado.
    def wrote(event)
      previous = current(event.actor)
      target = event.story&.reference || previous&.target
      entry = Entry.new(actor: event.actor, project_key: event.project.key, target: target, mode: :writing, detail: event.action, seen_at: Time.current)
      REGISTRY[event.actor.id] = entry
      schedule_expiry(entry)
      broadcast_presence(event.project)
    end

    # Los actores activos ahora, los últimos primero; de un proyecto o de todos.
    def active(project: nil)
      now = Time.current
      REGISTRY.values.select { it.active?(now) && (project.nil? || it.project_key == project.key) }.sort_by(&:seen_at).reverse
    end

    def current(actor)
      entry = REGISTRY[actor.id]
      entry if entry&.active?
    end

    def reset!
      TIMERS.values.each(&:cancel)
      TIMERS.clear
      REGISTRY.clear
    end

    private

    def changed?(previous, entry)
      previous.nil? || previous.project_key != entry.project_key || previous.target != entry.target ||
        previous.mode != entry.mode || previous.detail != entry.detail
    end

    # Al cumplirse la ventana sin más peticiones, se retira y se avisa. Un único
    # temporizador por actor: cada petición lo sustituye.
    def schedule_expiry(entry)
      TIMERS[entry.actor.id]&.cancel
      TIMERS[entry.actor.id] = Concurrent::ScheduledTask.execute(WINDOW.to_f + 0.5) { expire(entry.actor.id) }
    end

    def expire(actor_id)
      entry = REGISTRY[actor_id]
      return if entry.nil? || entry.active?

      REGISTRY.delete(actor_id)
      TIMERS.delete(actor_id)
      broadcast_presence(entry.project)
    rescue => e
      Rails.error.report(e, handled: true)
    end

    # Reemplaza la lista de presencia del proyecto y la de la portada.
    def broadcast_presence(project)
      if project
        Turbo::StreamsChannel.broadcast_replace_to([ project, :presence ], target: "presence",
          partial: "presences/presence", locals: { entries: active(project: project) })
      end
      Turbo::StreamsChannel.broadcast_replace_to(:presence, target: "presence",
        partial: "presences/presence", locals: { entries: active })
    end
  end
end
