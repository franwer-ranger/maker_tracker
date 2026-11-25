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
# historia, deja de estarlo; la ventana real es de 60 a 61 s por el barrido) se
# emiten como un `refresh` de Turbo a `[project, :live]` y a `:live` (la
# portada): la página que lo mira se vuelve a pintar con morph (MT-38). La
# emisión es en diferido y agrupada, y la presencia nunca rompe una petición:
# si algo falla, se reporta y sigue.
#
# «Escribiendo» dura WINDOW desde la última escritura (`wrote_at`): un agente
# que escribe y luego solo lee la misma historia vuelve a «leyendo» al pasar
# la ventana, aunque siga activo (con wflow puede trabajar horas).
#
# «En edición» (MT-100) es más corto: EDITING desde la última escritura, lo que
# la web v1 pinta en naranja (marco, pestaña y contorno). El barrido lo apaga y
# emite solo al stream de la presencia (`live_streams`); además la página recibe cuánto le queda y lo apaga sola aunque la
# emisión no llegue.
module Presence
  WINDOW = 60.seconds
  EDITING = 5.seconds
  SWEEP_EVERY = 1 # segundos: «en edición» no puede quedarse pintado más de la cuenta
  MODES = %i[reading writing].freeze

  # Datos planos (sin objetos de ActiveRecord, que no se comparten entre hilos).
  # `target`: la historia (MT-36) o la entidad (milestone M2, brief…) que toca;
  # `detail`: la última escritura; `project_id`: nil si la petición no es de un
  # proyecto (p. ej. listar proyectos); `since`: desde cuándo está activo sin
  # cortes (la «sesión» de MT-38); `wrote_at`: su última escritura.
  # `actor_kind`: "agent" o "human"; `editing`: si la última escritura sigue en
  # EDITING (lo baja el barrido).
  Entry = Data.define(:actor_id, :actor_name, :actor_kind, :project_id, :project_key, :target, :mode, :detail, :seen_at, :since, :wrote_at, :editing) do
    def reading? = mode == :reading
    def writing? = mode == :writing
    def active?(now = Time.current) = seen_at > now - WINDOW
    def wrote_recently?(now = Time.current) = wrote_at.present? && wrote_at > now - WINDOW
    def agent? = actor_kind == "agent"

    # Lo que le queda «en edición», en segundos (0 si ya no lo está).
    def editing_left(now = Time.current) = editing && wrote_at ? [ wrote_at + EDITING - now, 0 ].max.to_f : 0.0
    def editing_now?(now = Time.current) = editing_left(now).positive?
  end

  REGISTRY = Concurrent::Map.new
  PENDING = Concurrent::Map.new # lo que falta por emitir: id de proyecto o :all
  LAST_SENT = Concurrent::Map.new # cuándo se emitió por última vez cada clave (reloj monotónico)
  THROTTLE = 1.5 # segundos entre emisiones de la misma clave
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
      record(event.actor, event.project_id, event.project.key, written_target(event), :writing, event.action, keep_target: true)
    rescue => e
      Rails.error.report(e, handled: true)
    end

    # Los actores activos ahora, los últimos primero; de un proyecto o de todos.
    def active(project_id: nil)
      now = Time.current
      REGISTRY.values.select { it.active?(now) && (project_id.nil? || it.project_id == project_id) }.sort_by(&:seen_at).reverse
    end

    # Quién está editando algo del proyecto ahora mismo (MT-100), lo último primero.
    def editing(project_id:)
      now = Time.current
      active(project_id: project_id).select { it.editing_now?(now) }.sort_by(&:wrote_at).reverse
    end

    # Dónde escucha la página: `turbo_stream_from(*Presence.stream(project))`,
    # o `Presence.stream(:all)` en la portada. Event emite al mismo sitio.
    def stream(key)
      return [ :live ] if key == :all

      [ key.is_a?(Project) ? key : Project.new(id: key), :live ]
    end

    # Los streams de la prop `presence` de la web v1: los del proyecto (cada
    # escritura) y el suyo (el fin de «en edición», que no recarga nada más).
    def live_streams(project) = [ project, [ project, :presence ] ]

    def reset!
      REGISTRY.clear
      PENDING.clear
      LAST_SENT.clear
    end

    # Para el barrido y el hilo de emisión. Lo llama config/initializers/presence.rb
    # antes de cada recarga de código en desarrollo, para no dejar los viejos vivos.
    def shutdown!
      @sweeper&.shutdown
      EXECUTOR.shutdown
    end

    # Retira a quien lleva más de WINDOW sin peticiones, pasa a «leyendo» a
    # quien lleva más de WINDOW sin escribir y emite el cambio.
    def sweep
      now = Time.current
      REGISTRY.each_pair do |id, entry|
        if !entry.active?(now)
          enqueue(entry.project_id) if REGISTRY.delete_pair(id, entry)
        elsif entry.editing && !entry.editing_now?(now)
          enqueue(entry.project_id, only_editing: true) if REGISTRY.replace_pair(id, entry, entry.with(editing: false))
        elsif entry.writing? && !entry.wrote_recently?(now)
          enqueue(entry.project_id) if REGISTRY.replace_pair(id, entry, entry.with(mode: :reading, detail: nil))
        end
      end
    end

    private

    def record(actor, project_id, project_key, target, mode, detail, keep_target: false)
      start_sweeper
      changed = false
      REGISTRY.compute(actor.id) do |old|
        now = Time.current
        old = nil if old && !old.active?(now)
        target ||= old&.target if keep_target
        writes = mode == :writing
        wrote_at = writes ? now : old&.wrote_at
        same = same_target?(old&.target, target)
        if old && !writes && old.writing? && same
          mode, detail, target = old.mode, old.detail, old.target
        end
        editing = writes || (old&.editing_now?(now) && same) || false
        entry = Entry.new(actor_id: actor.id, actor_name: actor.name, actor_kind: actor.kind.to_s, project_id: project_id, project_key: project_key,
          target: target, mode: mode, detail: detail, seen_at: now, since: old&.since || now, wrote_at: wrote_at, editing: editing)
        changed = old.nil? || visible(old) != visible(entry)
        enqueue(old.project_id) if old && old.project_id != project_id
        entry
      end
      enqueue(project_id) if changed
    end

    # ¿La petición toca lo mismo que la anterior? Un destino genérico ("page", "decision") cuenta como el
    # concreto que se escribió ("page:revelarlo"): editar una página y releerla por la API (`mt page show`,
    # que no da el slug) no la saca de «en edición» ni la devuelve al destino genérico.
    def same_target?(old_target, target)
      old_target == target || (target.present? && old_target.to_s.start_with?("#{target}:"))
    end

    # Lo escrito, con el mismo formato que el destino de la petición: la
    # historia (PG-51), el hito (PG M2) o el brief; si no se sabe, el anterior.
    def written_target(event)
      return event.story.reference if event.story
      return "brief" if event.action == "brief.edited"
      return "page:#{event.data['slug']}" if event.action.start_with?("page.") && event.data["slug"].present?
      return "page" if event.action.start_with?("page.")
      return "decision:#{event.data['number']}" if event.action == "decision.recorded" && event.data["number"]
      return "decision" if event.action == "decision.recorded"

      number = Milestone.where(id: event.data["milestone_id"]).pick(:number) if event.action.start_with?("milestone.")
      "#{event.project.key} M#{number}" if number
    end

    # Lo que la UI enseña de una entrada: si cambia, se emite. Que siga activo,
    # cuándo escribió por última vez o el detalle no cambian lo que se ve.
    def visible(entry) = [ entry.project_id, entry.target, entry.mode, entry.editing ]

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

    # Emite en otro hilo, agrupa y limita a una emisión cada THROTTLE por
    # proyecto: la primera sale al momento y lo que llega mientras tanto, en una
    # sola al final de la ventana (p. ej. un agente que escribe muy seguido).
    # `only_editing`: solo se apagó «en edición», que solo pinta la web v1: va
    # al stream de la presencia, sin repintar la UI antigua ni recargar las
    # demás live props. Si en la misma ventana llega otro cambio, sale entero.
    def enqueue(project_id, only_editing: false)
      kind = only_editing ? :editing : :full
      [ project_id, (:all unless only_editing) ].compact.each do |key|
        loop do
          pending = PENDING.put_if_absent(key, kind)
          break schedule(key) if pending.nil?
          break if pending == :full || pending == kind
          break if PENDING.replace_pair(key, pending, :full) # si ya salió, la vuelta siguiente la programa
        end
      end
    end

    def schedule(key)
      delay = [ LAST_SENT.fetch(key, -THROTTLE) + THROTTLE - clock, 0 ].max
      Concurrent::ScheduledTask.execute(delay, executor: EXECUTOR) do
        kind = PENDING.delete(key)
        LAST_SENT[key] = clock
        Rails.application.executor.wrap { broadcast(key, kind) }
      rescue => e
        Rails.error.report(e, handled: true)
      end
    end

    def clock = Process.clock_gettime(Process::CLOCK_MONOTONIC)

    # Vuelve a pintar las páginas del proyecto o la portada (MT-38). La prop
    # `presence` de la web v1 escucha el stream del proyecto y el suyo
    # (`live_streams`): con `:editing`, solo el suyo.
    def broadcast(key, kind)
      return InertiaRails.broadcast([ Project.new(id: key), :presence ]) if kind == :editing

      Turbo::StreamsChannel.broadcast_refresh_to(*stream(key))
      InertiaRails.broadcast(Project.new(id: key)) unless key == :all # la portada v1 (MT-99)
    end
  end
end
