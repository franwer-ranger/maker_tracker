module StoriesHelper
  EDITED_FIELDS = {
    "title" => "el título", "body" => "el cuerpo", "mockup" => "el mockup",
    "labels" => "las labels", "blocked_by" => "los bloqueos"
  }.freeze

  # Un evento del historial en lenguaje natural: "Pasa a Lista", "claude edita el cuerpo y el mockup".
  def event_sentence(event)
    data = event.data
    case event.action
    when "story.created" then "Creada como #{Story.human_state(data['state'] || 'idea').downcase}"
    when "story.state_changed" then "Pasa a #{Story.human_state(data['to'])}"
    when "story.edited" then "#{event.actor.name} edita #{y_sentence(Array(data['fields']).map { EDITED_FIELDS.fetch(it, it) })}"
    when "story.claimed" then "#{event.actor.name} la reclama"
    when "story.released" then data["from"] ? "Se libera (la tenía #{data['from']})" : "Se libera"
    when "story.reordered" then "Cambia de posición en su hito"
    when "story.moved" then "Pasa a #{milestone_name(data.dig('to', 'milestone_id'))}"
    when "comment.added" then "#{event.actor.name} comenta"
    when "decision.recorded" then "Se decide D-#{data['number']}"
    else event.action
    end
  end

  # Marca lateral del evento: el color del estado al que pasa, o border-strong.
  def event_marker_class(event)
    state = event.data["to"] if event.action == "story.state_changed"
    {
      "idea" => "shadow-[inset_2px_0_0_var(--color-state-idea)]",
      "defining" => "shadow-[inset_2px_0_0_var(--color-state-defining)]",
      "ready" => "shadow-[inset_2px_0_0_var(--color-state-ready)]",
      "in_progress" => "shadow-[inset_2px_0_0_var(--color-accent)]",
      "done" => "shadow-[inset_2px_0_0_var(--color-state-done)]"
    }.fetch(state, "shadow-[inset_2px_0_0_var(--color-border-strong)]")
  end

  # Qué significa el estado actual, debajo del selector.
  def state_explanation(story, next_story)
    case story.state
    when "idea" then "Una idea sin definir. Pásala a Definiendo cuando empieces a darle forma."
    when "defining" then "Se está definiendo. Pásala a Lista cuando un agente pueda construirla sin preguntar."
    when "ready"
      if story == next_story
        "Siguiente en el roadmap. El primer agente que pregunte «¿qué es lo siguiente?» la cogerá."
      elsif (blockers = story.pending_blockers).any?
        "Lista, pero no saldrá hasta que estén hechas #{y_sentence(blockers.map { "##{it}" })}."
      else
        position = ready_queue(story.project).index(story)
        position ? "Lista. Es la #{position + 1}.ª en la cola del roadmap." : "Lista, fuera de los hitos abiertos."
      end
    when "in_progress"
      who = story.claimed_by&.name || "alguien"
      since = story.claimed_at ? " desde hace #{short_time_ago(story.claimed_at)}" : ""
      "La está construyendo #{who}#{since}."
    when "done" then "Hecha."
    end
  end

  # Avisos al estar Lista (no bloquean): preguntas abiertas o UI sin mockup.
  def ready_warnings(story)
    return [] unless story.ready?

    warnings = []
    warnings << "Tiene preguntas abiertas sin responder." if open_questions?(story.body)
    warnings << "Tiene la label «ui» y no tiene mockup." if story.labels.include?("ui") && story.mockup.blank?
    warnings
  end

  # "Paper" para enlaces de Paper; si no, el dominio.
  def mockup_label(url)
    host = URI.parse(url).host.to_s.delete_prefix("www.")
    host.end_with?("paper.design") ? "Paper" : host
  rescue URI::InvalidURIError
    url
  end

  def milestone_name(milestone_id)
    milestone = milestone_id && Milestone.find_by(id: milestone_id)
    milestone ? milestone_label(milestone) : "la bandeja de ideas"
  end

  # Punto del autor de un comentario: humano en azul, agente en gris.
  def actor_dot(actor)
    tag.span class: class_names("inline-block size-1.5 shrink-0 rounded-full", actor.human? ? "bg-avatar" : "bg-text-subtle"), aria: { hidden: true }
  end

  private

  # Historias Listas y no bloqueadas de los hitos abiertos, en el orden del roadmap.
  def ready_queue(project)
    done = project.stories.done.pluck(:number)
    project.milestones.open.flat_map { it.stories.ready.ordered.to_a }.reject { it.blocked?(done_numbers: done) }
  end

  def open_questions?(body)
    section = body[/^## Preguntas abiertas\s*$(.*?)(?=^## |\z)/m, 1]
    section.to_s.strip.present?
  end
end
