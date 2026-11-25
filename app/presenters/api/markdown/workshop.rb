# `mt workshop` (MT-97, docs/CLI.md): el taller del producto para el agente. Lo
# mismo que la portada y en el mismo orden: lo siguiente que la persona tiene
# que definir (como mucho Workshop::LIMIT), cada cosa con lo que le falta y el
# comando que la cierra, y cuántas más esperan.
class Api::Markdown::Workshop
  include Api::Markdown::Formatting

  KINDS = { answer: "answer", criteria: "write criteria", design: "design", review: "review and OK" }.freeze

  def initialize(workshop)
    @workshop = workshop
    @project = workshop.project
  end

  def summary
    return "Nothing to define in #{@project.key}. #{@workshop.ready_count} ready to build." if @workshop.items.empty?

    "#{@workshop.items.size} of #{plural(@workshop.count, 'thing')} to define in #{@project.key}, in roadmap order. #{@workshop.ready_count} ready to build."
  end

  def to_s
    parts = [ "# Workshop · #{@project.name} · #{@project.key}", summary ]
    parts << @workshop.items.each_with_index.map { |item, index| item_block(item, index + 1) }.join("\n\n") if @workshop.items.any?
    parts << "Waiting: #{@workshop.waiting_count} more defining. They come up when the roadmap gets to them." if @workshop.waiting_count.positive?
    parts.join("\n\n") + "\n"
  end

  def data
    { items: @workshop.items.each_with_index.map { |item, index| item_data(item, index + 1) },
      total: @workshop.count, waiting: @workshop.waiting_count, ready: @workshop.ready_count }
  end

  def breadcrumbs = @workshop.items.first(3).map { "mt show #{it.story.reference}" }

  # Lo que falta, en una línea y en inglés (el contenido, tal cual).
  def missing(item)
    question = item.question
    case item.kind
    when :answer
      question ? "#{question.reference} from #{question.actor.name} (#{question_traits(question).join(', ')}): #{question.title}" : "open questions in the body"
    when :criteria then "no acceptance criteria"
    when :design then "ui label and no mockup"
    when :review then "#{'mockup, ' if item.story.mockup.present?}criteria and no questions: only the OK is missing"
    end
  end

  def command(item)
    story = item.story
    case item.kind
    when :answer then item.question ? answer_command(item.question, "<option>") : "mt show #{story.reference}"
    when :review then "mt move #{story.reference} ready"
    else "mt edit #{story.reference} --file f.md"
    end
  end

  private

  def item_block(item, index)
    story = item.story
    head = "#{index}. #{KINDS.fetch(item.kind)} · #{story.reference} · #{story.title}#{" · #{story.milestone.code}" if story.milestone}"
    lines = [ head, "   #{missing(item)}" ]
    if (question = item.question)
      question.options.each_with_index { |text, i| lines << "     #{i + 1} #{text}#{' (recommended)' if i + 1 == question.recommended}" }
    end
    lines << "   #{command(item)}"
    lines.join("\n")
  end

  def item_data(item, index)
    story = item.story
    { position: index, kind: item.kind, reference: story.reference, title: story.title, state: story.state,
      milestone: story.milestone&.code, missing: missing(item), command: command(item),
      question: (question_data(item.question) if item.question) }.compact
  end
end
