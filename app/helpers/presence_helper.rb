# Agentes trabajando (MT-38): lo que la UI enseña de la presencia de MT-36.
# Todo sale de `Presence` (memoria del proceso) al pintar la página; cuando
# cambia, la página se vuelve a pintar sola (refresh de Turbo con morph), así
# que aquí no hay estado en el navegador. Sin agentes activos no se pinta nada.
module PresenceHelper
  # Cuántos eventos enseña «Esta sesión».
  SESSION_EVENTS = 5

  # Los agentes activos en el proyecto: los que escriben primero y, dentro,
  # los más recientes. Una vez por petición y proyecto.
  def agents_at_work(project)
    (@agents_at_work ||= {})[project.id] ||= begin
      entries = Presence.active(project_id: project.id)
      agents = entries.any? ? Actor.agent.where(id: entries.map(&:actor_id)).pluck(:id) : []
      entries.select { agents.include?(it.actor_id) }.sort_by { [ writing?(it) ? 0 : 1, -it.seen_at.to_f ] }
    end
  end

  # Escribiendo de verdad: con una escritura en la ventana (el barrido la baja a «leyendo»).
  def writing?(entry) = entry.writing? && entry.wrote_recently?

  # El borde de la ventana: solo con escrituras recientes en el proyecto que se mira.
  def agents_writing?(project) = agents_at_work(project).any? { writing?(it) }

  # El agente que está escribiendo `target` ("PG-51", "PG M2", "brief"), o nil.
  def agent_writing(project, target) = agents_at_work(project).find { writing?(it) && it.target == target }

  # El agente activo de un actor, o nil.
  def agent_at_work(project, actor) = agents_at_work(project).find { it.actor_id == actor.id }

  # La sección de la navegación que toca: una historia es del Tablero; un hito
  # o el roadmap, del Roadmap; el brief, las decisiones o el contexto, del Brief.
  def agent_section(entry)
    case entry.target.to_s
    when /\A[A-Z0-9]+-\d+\z/ then :board
    when /\A[A-Z0-9]+ M\d+\z/, "milestone", "roadmap", "next_story" then :roadmap
    when "brief", "decision", "context" then :brief
    end
  end

  def agent_sections(project) = agents_at_work(project).filter_map { agent_section(it) }.uniq

  # "PG-51", "M2", "el brief"… o nil si no toca nada concreto.
  def agent_subject(entry)
    case (target = entry.target.to_s)
    when /\A[A-Z0-9]+-\d+\z/ then target
    when /\A[A-Z0-9]+ (M\d+)\z/ then $1
    when "brief", "context" then "el brief"
    when "decision" then "las decisiones"
    when "milestone", "roadmap", "next_story" then "el roadmap"
    end
  end

  # Cabecera: "Editando PG-51" o "Leyendo PG-51".
  def agent_doing(entry)
    verb = writing?(entry) ? "Editando" : "Leyendo"
    [ verb, agent_subject(entry) ].compact.join(" ")
  end

  # Barra lateral: "escribiendo #51", "en #45", "escribiendo M2", "en el brief".
  def agent_place(entry)
    subject = agent_subject(entry)&.sub(/\A[A-Z0-9]+-(\d+)\z/, '#\1')
    writing?(entry) ? [ "escribiendo", subject ].compact.join(" ") : [ "en", subject || "el proyecto" ].join(" ")
  end

  # «Esta sesión»: lo que el agente ha hecho en el proyecto desde que está activo.
  # La fila «ahora» es lo que hace; si su última escritura es una edición de lo
  # mismo, dice qué cambió («Editando PG-51 · criterios») y no se repite abajo.
  AgentSession = Data.define(:entry, :now, :events)

  def agent_session(project, entry)
    events = project.events.where(actor_id: entry.actor_id, occurred_at: entry.since..).where.not(action: "usage.reported")
                           .includes(:story).recent_first.limit(SESSION_EVENTS + 1).to_a
    now = agent_doing(entry)
    if writing?(entry) && (last = events.first) && last.action == "story.edited" && last.story&.reference == entry.target
      now = "#{now} · #{edited_what(last)}"
      events.shift
    end
    AgentSession.new(entry: entry, now: now, events: events.first(SESSION_EVENTS))
  end

  EDITED_SHORT = { "title" => "título", "body" => "cuerpo", "mockup" => "mockup", "labels" => "labels", "blocked_by" => "bloqueos" }.freeze

  # "criterios" si marcó o desmarcó criterios; si no, los campos: "título y cuerpo".
  def edited_what(event)
    criteria = event.data["criteria"]
    return "criterios" if criteria && (criteria["checked"].to_i + criteria["unchecked"].to_i).positive?

    y_sentence(Array(event.data["fields"]).map { EDITED_SHORT.fetch(it, it) })
  end

  # Una fila de «Esta sesión», en pasado: "Creó PG-55 · Avisar antes de publicar".
  def session_event_text(event)
    data = event.data
    ref = event.story&.reference
    case event.action
    when "story.created" then "Creó #{ref} · #{event.story.title}"
    when "story.edited" then "Editó #{ref} · #{edited_what(event)}"
    when "story.state_changed" then "Pasó #{ref} a #{Story.human_state(data['to'])}"
    when "story.claimed" then "Empezó #{ref}"
    when "story.released" then "Soltó #{ref}"
    when "story.moved" then "Movió #{ref} · #{milestone_name(data.dig('to', 'milestone_id'))}"
    when "story.reordered" then "Reordenó #{ref}"
    when "comment.added" then "Comentó en #{ref}"
    when "question.asked" then "Preguntó en #{ref} · #{data['title']}"
    when "decision.recorded" then [ "Registró D-#{data['number']}", decision_title(event) ].compact.join(" · ")
    when "brief.edited" then "Editó el brief"
    when "milestone.created" then "Creó el hito #{data['title']}"
    when "milestone.edited" then "Editó #{milestone_event_ref(event)}"
    when "milestone.closed" then "Cerró #{milestone_event_ref(event)}"
    when "milestone.reopened" then "Reabrió #{milestone_event_ref(event)}"
    when "milestone.reordered" then "Reordenó #{milestone_event_ref(event)}"
    else [ ref, event_sentence(event) ].compact.join(" · ")
    end
  end

  # Recién creado por un agente que sigue activo: se resalta un momento y lleva «nueva».
  def fresh_from_agent?(project, record)
    return false unless record.created_at > Presence::WINDOW.ago && agents_at_work(project).any?

    actor_id = record.respond_to?(:actor_id) ? record.actor_id : project.events.where(story: record, action: "story.created").pick(:actor_id)
    agents_at_work(project).any? { it.actor_id == actor_id }
  end

  # La etiqueta «editando» con la matriz pequeña (tarjeta, fila, hito, brief).
  def agent_editing_label(entry)
    tag.span class: "flex shrink-0 items-center gap-1.5", title: "#{entry.actor_name} está editando" do
      safe_join([ agent_dots(size: :sm), tag.span("editando", class: "font-mono text-xs text-text-muted") ])
    end
  end
end
