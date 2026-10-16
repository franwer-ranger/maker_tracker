# El roadmap en vivo (`mt roadmap`): hitos abiertos en orden, cada uno con su
# objetivo y sus historias en orden, y al final la bandeja de ideas.
class Api::Markdown::Roadmap
  include Api::Markdown::Formatting

  def initialize(project, closed: false)
    @project = project
    @closed = closed
  end

  def milestones
    @milestones ||= (@closed ? @project.milestones : @project.milestones.open).includes(stories: :claimed_by).to_a
  end

  def ideas = @ideas ||= @project.ideas.includes(:claimed_by).to_a

  def done_numbers = @done_numbers ||= @project.stories.done.pluck(:number)

  def to_s
    sections = milestones.map do |milestone|
      status = milestone.closed? ? " (cerrado)" : ""
      [ "## #{milestone_label(milestone)}#{status}",
        (milestone.goal.strip if milestone.goal.present?),
        stories(milestone.stories) ].compact.join("\n\n")
    end
    sections << "## Bandeja de ideas\n\n#{stories(ideas)}"
    "# Roadmap · #{@project.name}\n\n#{sections.join("\n\n")}\n"
  end

  private

  def stories(list)
    list.map { story_line(it, done_numbers: done_numbers) }.join("\n").presence || "_Sin historias._"
  end
end
