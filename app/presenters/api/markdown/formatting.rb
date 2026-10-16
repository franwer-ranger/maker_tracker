# Piezas comunes de los documentos markdown que lee un agente. Van aparte de
# las vistas HTML para que la UI y la API no se rompan la una a la otra.
module Api::Markdown::Formatting
  module_function

  # Un valor de frontmatter: tal cual si YAML lo lee igual; si no, entre
  # comillas dobles (JSON es YAML válido).
  def scalar(value)
    return "" if value.nil?
    return value.to_s if value.is_a?(Integer)

    text = value.to_s
    plain = text.present? && text == text.strip && !text.match?(/\A[-?:,\[\]{}#&*!|>'"%@`]|: | #|\A(true|false|null|yes|no|~|\d[\d.]*)\z/i)
    plain ? text : text.to_json
  end

  def list(values) = "[#{values.map { scalar(it) }.join(', ')}]"

  # "PG-48 y PG-45", "PG-1, PG-2 y PG-3"
  def sentence(items) = items.to_sentence(words_connector: ", ", two_words_connector: " y ", last_word_connector: " y ")

  def milestone_label(milestone) = milestone ? "#{milestone.code} · #{milestone.title}" : "Bandeja de ideas"

  def date(time) = time.localtime.strftime("%Y-%m-%d")

  def datetime(time) = time.localtime.strftime("%Y-%m-%d %H:%M")

  # Una historia en una lista: "PG-49 · ready · Plantillas de post · claude · bloqueada por PG-47"
  def story_line(story, done_numbers: nil, show_milestone: false)
    parts = [ story.reference, story.state, story.title ]
    parts << milestone_label(story.milestone) if show_milestone
    parts << story.claimed_by.name if story.claimed_by
    blockers = story.pending_blockers(done_numbers: done_numbers)
    parts << "bloqueada por #{sentence(blockers.map { "#{story.project.key}-#{it}" })}" if blockers.any? && !story.done?
    "- #{parts.join(' · ')}"
  end

  # Lo mismo en datos.
  def story_data(story, done_numbers: nil)
    { reference: story.reference, number: story.number, title: story.title, state: story.state,
      milestone: story.milestone&.code, claimed_by: story.claimed_by&.name,
      blocked_by: story.pending_blockers(done_numbers: done_numbers).presence }.compact
  end
end
