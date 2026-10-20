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
# historia, deja de estarlo; la ventana real es de 60 a 65 s por el barrido) se emiten por Turbo Streams a `[project, :presence]`
# y `:presence` (la portada). La emisión es en diferido y agrupada, y la
# presencia nunca rompe una petición: si algo falla, se reporta y sigue.
module Presence
  WINDOW = 60.seconds
  SWEEP_EVERY = 5 # segundos
  MODES = %i[reading writing].freeze

  # Datos planos (sin objetos de ActiveRecord, que no se comparten entre hilos).
  # `target`: la historia (MT-36) o la entidad (milestone M2, brief…) que toca;
  # `detail`: la última escritura; `project_id`: nil si la petición no es de un
  # proyecto (p. ej. listar proyectos).
  Entry = Data.define(:actor_id, :actor_name, :project_id, :project_key, :target, :mode, :detail, :seen_at) do
    def reading? = mode == :reading
    def writing? = mode == :writing
    def active?(now = Time.current) = seen_at > now - WINDOW
  end

  REGISTRY = Concurrent::Map.new
  PENDING = Concurrent::Map.new # lo que falta por emitir: id de proyecto o :all
  EXECUTOR = Concurrent::SingleThreadExecutor.new

  class << self
    # Una petición del actor. Una lectura no pisa a una escritura reciente de la
    # misma historia (un agente que escribe y relee sigue «escribiendo»).
    def touch(actor, project: nil, project_key: nil, target: nil, mode:, detail: nil)
      raise ArgumentError, "mode: #{mode}" unless MODES.include?(mode)

      record(actor, project&.id, project_key, target, mode, detail)
    rescue => e
      Rails.error.report(e, handled: true)
    end

    # Una escritura ya hecha por el actor de la petición: dice qué ha cambiado.
    def wrote(event)
      record(event.actor, event.project_id, event.project.key, event.story&.reference, :writing, event.action, keep_target: true)
    rescue => e
      Rails.error.report(e, handled: true)
    end

    # Los actores activos ahora, los últimos primero; de un proyecto o de todos.
    def active(project_id: nil)
      now = Time.current
      REGISTRY.values.select { it.active?(now) && (project_id.nil? || it.project_id == project_id) }.sort_by(&:seen_at).reverse
    end

    def reset!
      REGISTRY.clear
      PENDING.clear
    end

    # Para el barrido y el hilo de emisión. Lo llama config/initializers/presence.rb
    # antes de cada recarga de código en desarrollo, para no dejar los viejos vivos.
    def shutdown!
      @sweeper&.shutdown
      EXECUTOR.shutdown
    end

    # Retira a quien lleva más de WINDOW sin peticiones y emite el cambio.
    def sweep
      now = Time.current
      REGISTRY.each_pair do |id, entry|
        enqueue(entry.project_id) if !entry.active?(now) && REGISTRY.delete_pair(id, entry)
      end
    end

    private

    def record(actor, project_id, project_key, target, mode, detail, keep_target: false)
      start_sweeper
      changed = false
      REGISTRY.compute(actor.id) do |old|
        old = nil if old && !old.active?
        target ||= old&.target if keep_target
        if old && mode == :reading && old.writing? && old.target == target
          mode, detail = old.mode, old.detail
        end
        entry = Entry.new(actor_id: actor.id, actor_name: actor.name, project_id: project_id, project_key: project_key,
          target: target, mode: mode, detail: detail, seen_at: Time.current)
        changed = old.nil? || old.with(seen_at: nil) != entry.with(seen_at: nil)
        enqueue(old.project_id) if old && old.project_id != project_id
        entry
      end
      enqueue(project_id) if changed
    end

    # Un único barrido periódico, arrancado al primer uso en cada proceso.
    def start_sweeper
      return if @sweeper&.running?

      (@mutex ||= Mutex.new).synchronize do
        @sweeper ||= Concurrent::TimerTask.new(execution_interval: SWEEP_EVERY, run_now: false) do
          Rails.application.executor.wrap { sweep }
        rescue => e
          Rails.error.report(e, handled: true)
        end
        @sweeper.execute unless @sweeper.running?
      end
    end

    # Emite en otro hilo y agrupa: varios cambios seguidos del mismo proyecto
    # (p. ej. el de la petición y el de su evento) son una sola emisión.
    def enqueue(project_id)
      [ project_id, :all ].compact.each do |key|
        next if PENDING.put_if_absent(key, true)

        EXECUTOR.post do
          PENDING.delete(key)
          Rails.application.executor.wrap { broadcast(key) }
        rescue => e
          Rails.error.report(e, handled: true)
        end
      end
    end

    # Reemplaza la lista de presencia del proyecto o la de la portada.
    def broadcast(key)
      if key == :all
        Turbo::StreamsChannel.broadcast_replace_to(:presence, target: "presence",
          partial: "presences/presence", locals: { entries: active })
      else
        Turbo::StreamsChannel.broadcast_replace_to([ Project.new(id: key), :presence ], target: "presence",
          partial: "presences/presence", locals: { entries: active(project_id: key) })
      end
    end
  end
end
