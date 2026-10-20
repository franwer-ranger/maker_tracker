# El roadmap en vivo (`mt roadmap`, docs/CLI.md): hitos abiertos en orden, cada
# uno con su objetivo y sus historias en orden; las hechas en una línea; al
# final la bandeja de ideas (las 3 primeras) y los hitos cerrados en una línea.
class Api::Markdown::Roadmap
  include Api::Markdown::Formatting

  INBOX = 3
  STATE_WIDTH = "in progress".length

  def initialize(project, closed: false)
    @project = project
    @closed = closed
  end

  def milestones
    @milestones ||= (@closed ? @project.milestones : @project.milestones.open).includes(stories: %i[claimed_by project questions]).to_a
  end

  def ideas = @ideas ||= @project.ideas.includes(:claimed_by, :project, :questions).to_a

  def done_numbers = @done_numbers ||= @project.stories.done.pluck(:number)

  def next_story = defined?(@next_story) ? @next_story : (@next_story = @project.next_story)

  def to_s
    sections = [ "# Roadmap · #{@project.name}", *milestones.map { milestone_section(it) } ]
    sections << inbox_section if ideas.any?
    sections << closed_line unless @closed || closed_milestones.empty?
    sections.join("\n\n") + "\n"
  end

  private

  def closed_milestones = @closed_milestones ||= @project.milestones.closed.to_a

  def milestone_section(milestone)
    stories = milestone.stories.to_a
    header = "## #{milestone_label(milestone)} · #{status(milestone, stories)}"
    header += "\nGoal: #{milestone.goal.strip}" if milestone.goal.present?
    [ header, story_lines(stories).presence ].compact.join("\n\n")
  end

  # "in progress · 4/12", "closed · 9/9", "6 stories", "3 ideas"
  def status(milestone, stories)
    done = stories.count(&:done?)
    return "closed · #{done}/#{stories.size}" if milestone.closed?
    return "in progress · #{done}/#{stories.size}" if stories.any? { it.in_progress? || it.done? }
    return "no stories" if stories.empty?

    stories.all?(&:idea?) ? plural(stories.size, "idea") : plural(stories.size, "story", "stories")
  end

  def story_lines(stories)
    open, done = stories.partition { !it.done? }
    rows = open.map do |story|
      [ state_words(story.state), story.reference, story.title, story_meta(story, next_story: next_story, done_numbers: done_numbers) ]
    end
    lines = table(rows, min: [ STATE_WIDTH, 0, TITLE_WIDTH ])
    lines << "#{'done'.ljust(STATE_WIDTH)}  #{done.map(&:reference).join(' ')}" if done.any?
    lines.join("\n")
  end

  def inbox_section
    lines = table(ideas.first(INBOX).map { [ it.reference, it.title ] })
    lines << "… and #{ideas.size - INBOX} more: mt list --milestone inbox" if ideas.size > INBOX
    noun = ideas.all?(&:idea?) ? plural(ideas.size, "idea") : plural(ideas.size, "story", "stories")
    "## Inbox · #{noun}\n\n#{lines.join("\n")}"
  end

  # "Closed: M1 · Cuentas y primer post (9/9, 2026-09-12). Show them with mt roadmap --closed."
  def closed_line
    items = closed_milestones.map do |milestone|
      done, total = milestone.progress
      "#{milestone_label(milestone)} (#{done}/#{total}, #{date(milestone.closed_at)})"
    end
    "Closed: #{items.join(', ')}. Show them with mt roadmap --closed."
  end
end
