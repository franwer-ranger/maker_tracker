# `mt next`: la historia de Project#next_story y el porqué en una frase.
#   "Primera Lista no bloqueada de M2. Antes en el orden: PG-48 y PG-45 (en curso)."
class Api::NextStory
  include Api::Markdown::Formatting

  attr_reader :story

  def initialize(project)
    @project = project
    @story = project.next_story
  end

  def reason
    return unless story

    parts = [ "Primera Lista no bloqueada de #{story.milestone.code}." ]
    skipped = []
    @project.milestones.open.each do |milestone|
      before = milestone.stories.includes(:claimed_by).to_a
      before = before.take_while { it != story } if milestone == story.milestone
      skipped.concat(before.select { it.ready? && it.blocked?(done_numbers: done_numbers) })
      if milestone == story.milestone
        pending = before.reject { it.done? || it.ready? }
        parts << "Antes en el orden: #{grouped(pending)}." if pending.any?
        break
      end
      parts.unshift("#{milestone.code} no tiene ninguna Lista libre.") unless skipped.any? { it.milestone == milestone }
    end
    parts << "Se salta #{sentence(skipped.map { "#{it.reference} (bloqueada por #{sentence(blockers(it))})" })}." if skipped.any?
    parts.join(" ")
  end

  # Historias que hay que mirar antes de empezar: las que la bloqueaban.
  def related = story.blocked_by.map { "#{@project.key}-#{it}" }

  # Por qué no hay ninguna: qué hay en Definiendo en el hito actual.
  def nothing_ready_hint
    milestone = @project.current_milestone
    return "No hay hitos abiertos. Mira el roadmap con mt roadmap --closed" unless milestone

    defining = milestone.stories.defining.count
    if defining.positive?
      "Hay #{defining} #{defining == 1 ? 'historia' : 'historias'} en Definiendo en #{milestone.code}: mt list --state defining --milestone #{milestone.code}"
    else
      "No hay historias Listas ni en Definiendo en #{milestone.code}. Mira el roadmap con mt roadmap"
    end
  end

  private

  def done_numbers = @done_numbers ||= @project.stories.done.pluck(:number)

  def blockers(story) = story.pending_blockers(done_numbers: done_numbers).map { "#{@project.key}-#{it}" }

  # "PG-48 y PG-45 (en curso), PG-51 (definiendo)"
  def grouped(stories)
    stories.chunk_while { |a, b| a.state == b.state }.map do |group|
      "#{sentence(group.map(&:reference))} (#{group.first.human_state.downcase})"
    end.join(", ")
  end
end
