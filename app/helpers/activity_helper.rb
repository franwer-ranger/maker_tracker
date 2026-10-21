# Piezas de la portada de Actividad (MT-30).
module ActivityHelper
  NUMBER_WORDS = %w[cero una dos tres cuatro cinco seis siete ocho nueve diez].freeze

  # "Cinco cosas solo las puedes hacer tú. La más antigua lleva dos días esperando."
  def activity_summary(cards)
    count = cards.size
    words = NUMBER_WORDS[count] || count.to_s
    lead = count == 1 ? "Una cosa solo la puedes hacer tú." : "#{words.capitalize} cosas solo las puedes hacer tú."
    cards.one? ? lead : "#{lead} La más antigua lleva #{waiting_in_words(cards.first.since)} esperando."
  end

  # "2 días", "16 horas", "40 minutos".
  def waiting_in_words(time)
    seconds = Time.current - time
    if seconds < 1.hour then pluralize_es([ (seconds / 60).floor, 1 ].max, "minuto")
    elsif seconds < 1.day then pluralize_es((seconds / 1.hour).floor, "hora")
    else pluralize_es((seconds / 1.day).floor, "día")
    end
  end

  def pluralize_es(count, noun) = "#{count} #{noun}#{'s' unless count == 1}"

  # "desde 08:10", "desde ayer", "desde 12 oct".
  def since_label(time)
    day = relative_day(time)
    day == "hoy" ? "desde #{time.strftime('%H:%M')}" : "desde #{day}"
  end

  # El contador de «Te toca»: el número de tarjetas (nil si no hay ninguna).
  def activity_count = Activity.for_you.size.nonzero?

  # Lo que cuenta una tarjeta de historia en Definiendo, completo (escritorio) y corto (móvil).
  def definition_meta(card)
    waiting = short_time_ago(card.since)
    questions = card.reason == :questions
    safe_join([
      tag.span("en Definiendo · #{questions ? 'preguntas abiertas' : 'parada, sin cambios'} · espera #{waiting}", class: "hidden md:inline"),
      tag.span("Definiendo · #{questions ? 'preguntas' : 'parada'} · #{waiting}", class: "md:hidden")
    ])
  end

  # Primera línea de las preguntas abiertas del cuerpo de la historia, sin la viñeta.
  def open_questions_excerpt(story)
    line = story.open_questions_text.to_s.lines.map(&:strip).find(&:present?).to_s
    line.sub(/\A[-*]\s+(\[[ xX]\]\s+)?/, "").truncate(160)
  end

  # Una línea de «Lo último que ha pasado»: qué pasó, en qué historia.
  def recent_event_text(event)
    sentence = event_sentence(event)
    event.story ? "#{event.story.reference} · #{event.story.title} — #{sentence}" : sentence
  end

  # Mientras no mirabas (MT-31) ----------------------------------------------

  # "ayer 23:10", "hoy 08:10", "12 oct".
  def away_time(time) = relative_day(time, time_of_day: true)

  # Cuántas historias o proyectos se despliegan abiertos: solo el primer grupo.
  def away_open?(index) = index.zero?

  # Debajo de cada historia del grupo: "Hecha · claude · hoy 01:40 · 3 commits".
  def away_story_meta(change)
    events = change.events
    state = events.reverse.find { it.action == "story.state_changed" }&.data&.dig("to")
    commits = events.sum { Array(it.data["commits"]).size }
    asked = events.count { it.action == "question.asked" }
    comments = events.count { it.action == "comment.added" }
    [
      (Story.human_state(state) if state),
      y_sentence(events.map { it.actor.name }.uniq),
      away_time(events.last.occurred_at),
      (pluralize_es(commits, "commit") if commits.positive?),
      (pluralize_es(asked, "pregunta") if asked.positive?),
      (pluralize_es(comments, "comentario") if comments.positive?)
    ].compact.join(" · ")
  end

  # La marca de la izquierda: el color del estado al que pasó, o el neutro.
  def away_story_marker(change)
    state = change.events.reverse.find { it.action == "story.state_changed" }&.data&.dig("to")
    event_marker_class(Event.new(action: "story.state_changed", data: { "to" => state }))
  end

  # La etiqueta de «Decidido por agentes»: D-37, a Lista, orden, hito o brief.
  def decided_tag(event)
    case event.action
    when "decision.recorded" then "D-#{event.data['number']}"
    when "story.state_changed" then "a Lista"
    when "story.reordered", "story.moved" then "orden"
    when "brief.edited" then "brief"
    else "hito"
    end
  end

  # El texto de la fila: el título de la decisión, o la historia con lo que le pasó y el motivo.
  def decided_text(event)
    return decision_title(event) || event_sentence(event) if event.action == "decision.recorded"

    text = event.story ? "#{event.story.reference} · #{event.story.title}: #{event_sentence(event).downcase_first}" : event_sentence(event)
    event.reason.present? ? "#{text} · «#{event.reason}»" : text
  end

  # Dónde se revisa: la historia, el brief (con sus decisiones) o el roadmap.
  def decided_path(event)
    project = event.project
    return project_story_path(project, event.story) if event.story
    return project_brief_path(project, anchor: ("D-#{event.data['number']}" if event.action == "decision.recorded")) if event.action.start_with?("decision", "brief")

    project_roadmap_path(project)
  end

  def decided_meta(event) = [ event.story&.reference || event.project.key, event.actor.name, away_time(event.occurred_at) ].join(" · ")

  # QA pendiente (MT-32) -------------------------------------------------------

  # Plegada: "hecha 06:22 · 3 criterios".
  def qa_collapsed_meta(card)
    [ "hecha #{away_time(card.done_at)}", pluralize_es(card.criteria.size, "criterio") ].join(" · ")
  end

  # Desplegada: "Hecha ayer 18:40 · codex · QA pendiente" (en móvil, sin lo último).
  def qa_card_meta(card)
    [ "Hecha #{away_time(card.done_at)}", card.done_by&.name, ("#{card.commits} #{'commit'.pluralize(card.commits)}" if card.commits.positive?), "QA pendiente" ].compact.join(" · ")
  end

  # Trabajo listo (MT-33) ----------------------------------------------------

  # El resumen del proyecto (`ReadyWork`), calculado una vez por petición para todos.
  def ready_work_for(project) = ReadyWork.all[project.id] || ReadyWork.for(project)

  # "Lista" o "Listas" tras el número: "1 Lista", "3 Listas".
  def ready_label(count) = count == 1 ? "Lista" : "Listas"

  # "0 Listas · 2 en Definiendo".
  def ready_work_counts(ready, defining) = "#{ready} #{ready_label(ready)} · #{defining} en Definiendo"

  # "A PG no le quedan historias Listas", "A PG le queda 1 historia Lista".
  def low_work_title(project, ready)
    case ready
    when 0 then "A #{project.key} no le quedan historias Listas"
    when 1 then "A #{project.key} le queda una historia Lista"
    else "A #{project.key} le quedan #{NUMBER_WORDS[ready] || ready} historias Listas"
    end
  end

  # Las cuatro pestañas de la barra inferior del móvil (layouts/_tab_bar).
  def bottom_tabs(project)
    [
      { label: "Actividad", href: root_path, icon: "inbox", active: current_page?(root_path), count: activity_count },
      { label: "Tablero", href: project_path(project), icon: "view-columns", active: current_page?(project_path(project)) },
      { label: "Roadmap", href: project_roadmap_path(project), icon: "list-bullet",
        active: current_page?(project_roadmap_path(project)) || controller_name == "stories" },
      { label: "Brief", href: project_brief_path(project), icon: "document-text", active: controller_name == "briefs" }
    ]
  end

  # Pestaña de la barra inferior del móvil (5.9 · Móvil): icono, etiqueta y, si hay, el contador.
  def tab_item(label, href, icon:, active:, count: nil)
    link_to href, class: class_names("flex w-20 shrink-0 flex-col items-center gap-1 rounded-md py-1.5 text-label leading-[14px] #{ComponentsHelper::FOCUS_RING}",
      active ? "font-medium text-text" : "text-text-muted"), aria: { current: ("page" if active) } do
      safe_join([
        tag.span(class: "relative flex") do
          safe_join([
            icon(icon, size: 22),
            (tag.span(count, class: "absolute -right-2.5 -top-1.5 rounded-full bg-accent px-1.5 font-mono text-label leading-[14px] text-bg") if count)
          ].compact)
        end,
        label
      ])
    end
  end
end
