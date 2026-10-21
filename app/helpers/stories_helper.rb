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
    when "story.state_changed" then state_change_sentence(event)
    when "question.asked" then "#{event.actor.name} pregunta: #{data['title']}"
    when "question.answered" then "#{event.actor.name} responde a #{data['asked_by']}: «#{data['answer']}»#{" (D-#{data['decision']})" if data['decision']}"
    when "story.edited" then "#{event.actor.name} edita #{y_sentence(Array(data['fields']).map { EDITED_FIELDS.fetch(it, it) })}"
    when "story.claimed" then "#{event.actor.name} la reclama"
    when "story.released" then data["from"] ? "Se libera (la tenía #{data['from']})" : "Se libera"
    when "story.reordered" then "Cambia de posición en su hito"
    when "story.moved" then "Pasa a #{milestone_name(data.dig('to', 'milestone_id'))}"
    when "comment.added" then "#{event.actor.name} comenta"
    when "qa.passed" then "#{event.actor.name} da la QA por probada#{": «#{data['note']}»" if data['note']}"
    when "qa.failed" then "#{event.actor.name} falla la QA: #{project_story_ref(event, data['story'])}"
    when "decision.recorded" then "Se decide D-#{data['number']}"
    when "brief.edited" then "#{event.actor.name} edita el brief"
    when "milestone.created" then "#{event.actor.name} crea el hito #{data['title']}"
    when "milestone.edited" then "#{event.actor.name} edita #{milestone_event_ref(event)}"
    when "milestone.closed" then "#{event.actor.name} cierra #{milestone_event_ref(event)}"
    when "milestone.reopened" then "#{event.actor.name} reabre #{milestone_event_ref(event)}"
    when "milestone.reordered" then "#{event.actor.name} reordena #{milestone_event_ref(event)}"
    else event.action
    end
  end

  # "M2", o "un hito borrado" si ya no existe.
  def milestone_event_ref(event)
    @milestone_codes ||= Milestone.pluck(:id, :position).to_h { |id, position| [ id, "M#{position}" ] }
    @milestone_codes.fetch(event.data["milestone_id"], "un hito borrado")
  end

  # "Pasa a Lista"; si un agente la suelta (porque pregunta), "codex la suelta: vuelve a Lista".
  def state_change_sentence(event)
    data = event.data
    return "Pasa a #{Story.human_state(data['to'])}#{' · QA pendiente' if data['qa'] == 'pending'}" unless data["released"] && data["to"] != "done"

    "#{event.actor.name} la suelta: vuelve a #{Story.human_state(data['to'])}"
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

  # «Qué cambió desde tu visita» (5.11): una línea por cosa nueva, no por evento.
  # Marca: ! un cambio de estado o de sitio, − algo que deja de esperar, + algo nuevo.
  ChangeLine = Data.define(:mark, :text, :who, :at, :detail, :commits) do
    def initialize(commits: [], **rest) = super
  end
  CHANGE_MARKS = { "!" => "text-state-defining", "−" => "text-text-muted", "+" => "text-state-done" }.freeze

  def story_change_lines(events)
    lines = without_round_trips(events).group_by { it.action == "comment.added" ? [ it.action, it.actor_id ] : it.id }.flat_map do |_, group|
      event = group.last
      case event.action
      when "comment.added"
        [ ChangeLine.new("+", "#{pluralize_es(group.size, 'comentario')} de #{event.actor.name}", event.actor.name, event.occurred_at, nil) ]
      when "story.state_changed" then state_change_lines(event)
      when "decision.recorded"
        title = decision_title(event)
        [ ChangeLine.new("+", [ "D-#{event.data['number']}", title ].compact.join(" · "), event.actor.name, event.occurred_at, nil) ]
      when "question.answered" then [ ChangeLine.new("−", event_sentence(event), event.actor.name, event.occurred_at, nil) ]
      when "story.claimed", "story.released", "story.reordered", "story.moved"
        [ ChangeLine.new("!", event_sentence(event), event.actor.name, event.occurred_at, nil) ]
      when "story.edited" then [ edit_line(event) ]
      else [ ChangeLine.new("+", event_sentence(event), event.actor.name, event.occurred_at, nil) ]
      end
    end
    lines.sort_by.with_index { |line, index| [ { "!" => 0, "−" => 1, "+" => 2 }.fetch(line.mark), index ] }
  end

  # El título de la decisión de un evento `decision.recorded`; una sola consulta por petición.
  def decision_title(event)
    @decision_titles ||= Decision.pluck(:project_id, :number, :title).to_h { |project_id, number, title| [ [ project_id, number ], title ] }
    @decision_titles[[ event.project_id, event.data["number"] ]]
  end

  # «codex marcó 2 criterios · 2 de 3»; los eventos de antes del dato dicen «edita el cuerpo».
  def edit_line(event)
    criteria = event.data["criteria"]
    text = if criteria && criteria["checked"].to_i.positive?
      "#{event.actor.name} marcó #{pluralize_es(criteria['checked'], 'criterio')} · #{criteria['done']} de #{criteria['total']}"
    elsif criteria && criteria["unchecked"].to_i.positive?
      "#{event.actor.name} desmarcó #{pluralize_es(criteria['unchecked'], 'criterio')} · #{criteria['done']} de #{criteria['total']}"
    else
      event_sentence(event)
    end
    ChangeLine.new("+", text, event.actor.name, event.occurred_at, nil)
  end

  # Quita las idas y vueltas del mismo actor (Lista → En curso y En curso → Lista), que no cambian nada.
  def without_round_trips(events)
    states = []
    events.each do |event|
      next unless event.action == "story.state_changed"

      last = states.last
      if last && event.actor_id == last.actor_id && event.data["from"] == last.data["to"] && event.data["to"] == last.data["from"]
        states.pop
      else
        states << event
      end
    end
    events.reject { it.action == "story.state_changed" && states.exclude?(it) }
  end

  # "Estado: Lista → En curso" y, si trae trabajo, sus commits en otra línea.
  def state_change_lines(event)
    data = event.data
    lines = [ ChangeLine.new("!", "Estado: #{Story.human_state(data['from'])} → #{Story.human_state(data['to'])}", event.actor.name, event.occurred_at, nil) ]
    commits = event.commits
    pr = ("PR #{data['pr'].to_s.delete_prefix('#')}" if data["pr"].present?)
    lines << ChangeLine.new("+", pluralize_es(commits.size, "commit"), event.actor.name, event.occurred_at, pr, commits: commits) if commits.any?
    lines
  end

  # Qué significa el estado actual, debajo del selector. Una pregunta abierta
  # que bloquea lo explica ella: la historia espera a quien responde.
  def state_explanation(story, next_story)
    if (questions = story.blocking_questions).any?
      askers = y_sentence(questions.map { it.actor.name }.uniq)
      return "Bloqueada por ti: #{askers} #{questions.one? ? 'preguntó' : 'preguntaron'}#{' y la soltó' if released_for_question?(story, questions)}. Ningún agente la cogerá hasta que contestes."
    end

    case story.state
    when "idea" then "Una idea sin definir. Pásala a Definiendo cuando empieces a darle forma."
    when "defining" then "Se está definiendo. Pásala a Lista cuando un agente pueda construirla sin preguntar."
    when "ready"
      if story == next_story
        lead = answered_question_note(story)
        "Siguiente en el roadmap. #{lead}#{lead ? 'el' : 'El'} primer agente que pregunte «¿qué es lo siguiente?» la cogerá."
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
    when "done" then done_explanation(story)
    end
  end

  # «PG-50» de una historia del proyecto del evento; es la historia que crea una QA fallida.
  def project_story_ref(event, number) = "#{event.project.key}-#{number}"

  # La historia Hecha: con QA pendiente, quién la cerró y que no bloquea nada.
  def done_explanation(story)
    return "Hecha." unless story.qa_pending?

    event = story_done_event(story)
    who = event ? " #{event.actor.name} la cerró #{relative_day(event.occurred_at, time_of_day: true)}." : ""
    "Hecha.#{who} Te falta probarla: no bloquea nada."
  end

  # El evento que la pasó a Hecha.
  def story_done_event(story)
    story.history.includes(:actor).find { it.action == "story.state_changed" && it.data["to"] == "done" }
  end

  # La propiedad «QA» de la Historia (5.12): Pendiente en testing.…, Probada o Falló y su historia.
  def qa_status(story)
    event = story.events.where(action: %w[qa.passed qa.failed]).recent_first.includes(:actor).first
    dot = ->(done) { tag.span(class: class_names("inline-block size-1.5 shrink-0 rounded-full", "bg-state-done": done, "border-[1.5px] border-state-done": !done), aria: { hidden: true }) }
    case story.qa
    when "pending"
      url = story.project.qa_url
      tag.span(class: "flex items-center gap-2") do
        safe_join([ dot.call(false), tag.span("Pendiente", class: "text-control text-text"),
          (tag.span("en #{URI.parse(url).host}", class: "font-mono text-xs text-text-muted") if url) ].compact)
      end
    when "passed"
      tag.span(class: "flex items-center gap-2") do
        safe_join([ dot.call(true), tag.span("Probada", class: "text-control text-text"),
          (tag.span("#{event.actor.name} · #{relative_day(event.occurred_at, time_of_day: true)}", class: "font-mono text-xs text-text-muted") if event) ].compact)
      end
    else
      fix = event && story.project.stories.find_by(number: event.data["story"])
      tag.span(class: "flex items-center gap-2") do
        safe_join([ tag.span("Falló", class: "text-control text-text"),
          (link_to(fix.reference, project_story_path(story.project, fix), class: "font-mono text-xs text-text-muted underline decoration-border-strong underline-offset-[3px] hover:text-text") if fix) ].compact)
      end
    end
  end

  # ¿La soltó de verdad? Hay un evento released poco antes de la primera pregunta o después.
  def released_for_question?(story, questions)
    since = questions.map(&:created_at).min - 1.minute
    story.history.any? { it.data["released"] && it.occurred_at >= since }
  end

  # "Respondiste a codex: " si lo último que pasó en la historia fue una respuesta a una pregunta.
  def answered_question_note(story)
    question = story.answered_questions.max_by(&:answered_at)
    return unless question && story.events.recent_first.first&.action == "question.answered"

    "#{question.answered_by.human? ? 'Respondiste' : "#{question.answered_by.name} respondió"} a #{question.actor.name}: "
  end

  # Avisos al estar Lista (no bloquean): preguntas abiertas o UI sin mockup.
  def ready_warnings(story)
    story.ready? ? story.readiness_issues : []
  end

  # "Paper" para enlaces de Paper; si no, el dominio.
  def mockup_label(url)
    host = URI.parse(url).host.to_s.delete_prefix("www.")
    host.end_with?("paper.design") ? "Paper" : host
  rescue URI::InvalidURIError
    url
  end

  def milestone_name(milestone_id)
    @milestones ||= Milestone.all.index_by(&:id)
    milestone = milestone_id && @milestones[milestone_id]
    milestone ? milestone_label(milestone) : "la bandeja de ideas"
  end

  # Punto del autor de un comentario: humano en azul, agente en gris.
  def actor_dot(actor)
    tag.span class: class_names("inline-block size-1.5 shrink-0 rounded-full", actor.human? ? "bg-avatar" : "bg-text-subtle"), aria: { hidden: true }
  end

  # "Pregunta abierta · te toca", "Preguntas abiertas · te tocan", "… · no bloquea".
  def open_questions_label(questions)
    many = questions.size > 1
    status = questions.any?(&:blocking?) ? (many ? "te tocan" : "te toca") : (many ? "no bloquean" : "no bloquea")
    "#{many ? 'Preguntas abiertas' : 'Pregunta abierta'} · #{status}"
  end

  # La etiqueta de reversibilidad solo sale si está indicada: sin ella, no se asume irreversible.
  def question_reversibility(question)
    return if question.reversible.nil?

    tag.span(question.reversible ? "Reversible" : "Irreversible", class: "rounded-sm bg-surface px-1.5 py-0.5 font-mono text-label text-text-muted")
  end

  # `mt answer PG-49 2`, con `--question 12` si hay varias abiertas (docs/CLI.md).
  def question_answer_command(story, question, number)
    many = story.open_questions_asked.size > 1
    tag.span "mt answer #{story.reference} #{number}#{" --question #{question.id}" if many}"
  end

  private

  # Historias Listas y no bloqueadas de los hitos abiertos, en el orden del roadmap.
  def ready_queue(project)
    done = project.stories.done.pluck(:number)
    project.milestones.open.flat_map { it.stories.ready.ordered.includes(:questions).to_a }.reject { it.blocked?(done_numbers: done) }
  end
end
