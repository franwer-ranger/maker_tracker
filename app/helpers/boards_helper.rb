module BoardsHelper
  # Lo que se ve arriba a la derecha de una tarjeta: solo una cosa, por
  # prioridad (5.1). `context` trae lo que se calcula una vez por tablero.
  def story_card_meta(story, context)
    if story.in_progress? && story.claimed_by
      tag.span class: "flex items-center gap-1.5" do
        safe_join([ state_dot(:in_progress), tag.span(story.claimed_by.name, class: "font-mono text-xs text-text") ])
      end
    elsif story == context[:next_story]
      next_badge
    elsif (pending = story.pending_blockers(done_numbers: context[:done_numbers])).any?
      tag.span class: "flex items-center gap-1 font-mono text-xs text-text-muted", title: "Bloqueada" do
        safe_join([ icon("lock-closed", size: 14), "tras #{pending.map { "##{it}" }.join(', ')}" ])
      end
    elsif story.blocking_questions.any?
      tag.span class: "flex items-center gap-1 font-mono text-xs text-text-muted", title: "Bloqueada por una pregunta abierta" do
        safe_join([ icon("lock-closed", size: 14), "pregunta" ])
      end
    elsif story.missing_criteria?
      tag.span "faltan criterios", class: "font-mono text-xs text-state-defining"
    elsif story.mockup.present?
      tag.span class: "flex items-center gap-1 font-mono text-xs text-text-muted" do
        safe_join([ icon("photo", size: 14), "mockup" ])
      end
    end
  end

  # Badge "Siguiente": píldora state-ready con texto negro. Solo una por proyecto.
  def next_badge
    tag.span "Siguiente", class: "flex h-5 items-center rounded-full bg-state-ready px-2 text-xs font-medium text-bg"
  end

  # Texto de la cabecera del tablero: "M2 · En curso · 4/12 hechas" (en el móvil, `short`: "M2 · En curso · 4/12").
  def board_heading_label(filter, milestone, short: false)
    case filter
    when :ideas then "Bandeja de ideas"
    when :all then "Todos los hitos"
    else
      done, total = milestone.progress
      [ milestone.code, milestone.status, "#{done}/#{total}#{' hechas' unless short}" ].join(" · ")
    end
  end

  # La pestaña de estado que abre el Tablero en el móvil (5.1 · Móvil): la
  # primera con historias empezando por Lista; si no hay ninguna, Lista.
  BOARD_TAB_ORDER = %w[ready in_progress defining idea done].freeze

  def board_default_tab(columns)
    BOARD_TAB_ORDER.find { columns[it].any? } || "ready"
  end

  # Cuántas hay en una columna (la de Hechas cuenta también las que no se enseñan).
  def board_column_count(state, stories, hidden_done)
    state == "done" && hidden_done.to_i.positive? ? stories.size + hidden_done : stories.size
  end
end
