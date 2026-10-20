# Piezas comunes de lo que lee un agente (docs/CLI.md). Van aparte de las
# vistas HTML para que la UI y la API no se rompan la una a la otra. Todo lo que
# pone la herramienta va en inglés; el contenido (títulos, cuerpos), tal cual.
module Api::Markdown::Formatting
  module_function

  TITLE_WIDTH = 42 # mínimo: la columna crece si un título es más largo

  # Un valor de frontmatter: tal cual si YAML lo lee igual; si no, entre
  # comillas dobles (JSON es YAML válido).
  def scalar(value)
    return "" if value.nil?
    return value.to_s if value.is_a?(Integer)

    text = value.to_s
    plain = text.present? && text == text.strip && !text.match?(/\A[-?:,\[\]{}#&*!|>'"%@`]|: | #|\A(true|false|null|yes|no|on|off|y|n|~|\d[\d.]*)\z/i)
    plain ? text : text.to_json
  end

  def list(values) = "[#{values.map { scalar(it) }.join(', ')}]"

  # "PG-48 and PG-45", "PG-1, PG-2 and PG-3"
  def sentence(items) = items.to_sentence(words_connector: ", ", two_words_connector: " and ", last_word_connector: " and ")

  # "1 story", "3 stories"
  def plural(count, singular, plural = "#{singular}s") = "#{count} #{count == 1 ? singular : plural}"

  # En la prosa, en minúscula y con espacios: "in progress".
  def state_words(state) = state.to_s.tr("_", " ")

  def milestone_label(milestone) = milestone ? "#{milestone.code} · #{milestone.title}" : "the inbox"

  def date(time) = time.localtime.strftime("%Y-%m-%d")

  # Fechas absolutas, y solo la hora si es de hoy: "11:42", "2026-10-15 22:40".
  def datetime(time)
    time = time.localtime
    time.to_date == Time.current.localtime.to_date ? time.strftime("%H:%M") : time.strftime("%Y-%m-%d %H:%M")
  end

  # Cuánto lleva esperando algo: "40 min", "2 h", "3 days".
  def waiting(time)
    seconds = Time.current - time
    if seconds < 1.hour then "#{[ (seconds / 60).floor, 1 ].max} min"
    elsif seconds < 1.day then "#{(seconds / 1.hour).floor} h"
    else plural((seconds / 1.day).floor, "day")
    end
  end

  # "PG-49 · Q12", la pregunta con su historia.
  def question_label(question) = "#{question.story.reference} #{question.reference}"

  # "blocking, reversible": lo que se sabe de una pregunta. Sin `reversible`, no dice nada de la reversibilidad.
  def question_traits(question)
    [ (question.blocking? ? "blocking" : "non-blocking"),
      (question.reversible.nil? ? nil : (question.reversible ? "reversible" : "irreversible")) ].compact
  end

  # `mt answer PG-49 2`, con `--question 12` si la historia tiene varias abiertas.
  def answer_command(question, option)
    story = question.story
    many = story.open_questions_asked.size > 1
    "mt answer #{story.reference} #{option}#{" --question #{question.id}" if many}"
  end

  # La pregunta en datos, para la API.
  def question_data(question)
    { id: question.id, reference: question.story.reference, question: question.reference, title: question.title,
      context: question.context.presence, options: question.options, recommended: question.recommended,
      reversible: question.reversible, blocking: question.blocking?, asked_by: question.actor.name,
      asked_at: question.created_at.iso8601, answer: question.answer, answer_note: question.answer_note,
      answered_by: question.answered_by&.name, answered_at: question.answered_at&.iso8601 }.compact
  end

  # "PR #63" si la url es de una PR de GitHub; si no, "PR <url>".
  def pr_label(url) = (number = url.to_s[%r{/pull/(\d+)}, 1]) ? "PR ##{number}" : "PR #{url}"

  # Columnas alineadas con espacios (dos entre columnas). Cada columna mide lo
  # que su celda más larga o, como poco, `min[i]`. La última no se rellena.
  def table(rows, min: [])
    return [] if rows.empty?

    size = rows.map(&:size).max
    rows = rows.map { |row| row.map(&:to_s) + [ "" ] * (size - row.size) }
    widths = rows.transpose.map.with_index { |column, i| [ min[i].to_i, *column.map(&:length) ].max }
    rows.map { |row| row.each_with_index.map { |cell, i| i == size - 1 ? cell : cell.ljust(widths[i]) }.join("  ").rstrip }
  end

  # Lo que se ve a la derecha de una historia en el roadmap: lo mismo que en el
  # Tablero y por el mismo orden (BoardsHelper#story_card_meta).
  def story_meta(story, next_story:, done_numbers:)
    return story.claimed_by.name if story.in_progress? && story.claimed_by
    return "← next" if story == next_story

    blockers = story.pending_blockers(done_numbers: done_numbers)
    return "blocked by #{sentence(blockers.map { "#{story.project.key}-#{it}" })}" if blockers.any?
    return "blocked by #{Actor.human.name}" if story.blocking_questions.any?
    return "no criteria" if story.missing_criteria?

    "mockup" if story.mockup.present?
  end

  # Lo mismo en datos.
  def story_data(story, done_numbers: nil)
    { reference: story.reference, number: story.number, title: story.title, state: story.state,
      milestone: story.milestone&.code, claimed_by: story.claimed_by&.name,
      blocked_by: story.pending_blockers(done_numbers: done_numbers).presence,
      blocked_by_questions: story.blocking_questions.map(&:reference).presence }.compact
  end

  # Avisos al pasar a ready (Story#readiness_problems), en inglés.
  def readiness_warnings(story)
    story.readiness_problems.map do |problem|
      { open_questions: "it has open questions.", ui_without_mockup: "it has the ui label but no mockup." }.fetch(problem)
    end
  end
end
