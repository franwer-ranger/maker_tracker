# `mt next` (docs/CLI.md): la historia de Project#next_story y por qué es esa.
#   "first ready, unblocked story in M2. PG-48 and PG-45 come before it and are in progress."
class Api::NextStory
  include Api::Markdown::Formatting

  attr_reader :story

  def initialize(project)
    @project = project
    @story = project.next_story
  end

  def markdown
    "Next up: #{story.reference} · #{story.title}\nWhy this one: #{reason}\n\n#{Api::Markdown::Story.new(story)}"
  end

  def reason
    return unless story

    empty, skipped = [], []
    @project.milestones.open.includes(stories: %i[claimed_by project]).each do |milestone|
      before = milestone.stories.to_a
      before = before.take_while { it != story } if milestone == story.milestone
      blocked = before.select { it.ready? && it.blocked?(done_numbers: done_numbers) }
      skipped.concat(blocked)
      if milestone == story.milestone
        return [ "first ready, unblocked story in #{milestone.code}.",
                 (none_in(empty) if empty.any?),
                 (pending_sentence(before.reject { it.done? || it.ready? }) if before.any? { !it.done? && !it.ready? }),
                 *skipped.map { blocked_sentence(it) } ].compact.join(" ")
      end
      empty << milestone if blocked.empty?
    end
  end

  # Historias que hay que mirar antes de empezar: las que la bloqueaban.
  def related = story.blocked_by.map { "#{@project.key}-#{it}" }

  # Sin ninguna: el error de `mt next`, con lo que se está definiendo.
  def nothing_ready_error
    open = @project.milestones.open.to_a
    human = Actor.human.name
    if open.empty?
      return Api::Error.new("NOTHING_READY", "no open milestone.", status: :not_found,
        hint: "see the closed ones with mt roadmap --closed, or ask #{human}.")
    end

    defining = @project.stories.defining.where(milestone: open).sort_by { [ it.milestone.position, it.position ] }
    hint = if defining.any?
      "#{plural(defining.size, 'story', 'stories')} #{defining.one? ? 'is' : 'are'} being defined (#{defining.map(&:reference).join(', ')}). " \
        "See #{defining.one? ? 'it' : 'them'} with mt list --state defining, or ask #{human}."
    else
      "nothing is being defined either. See the roadmap with mt roadmap, or ask #{human}."
    end
    Api::Error.new("NOTHING_READY", "no ready, unblocked story in #{or_sentence(open.map(&:code))}.", status: :not_found, hint: hint)
  end

  private

  def done_numbers = @done_numbers ||= @project.stories.done.pluck(:number)

  def or_sentence(items) = items.to_sentence(words_connector: ", ", two_words_connector: " or ", last_word_connector: " or ")

  # "M2 has none." / "M2 and M3 have none."
  def none_in(milestones) = "#{sentence(milestones.map(&:code))} #{milestones.one? ? 'has' : 'have'} none."

  # "PG-48 and PG-45 come before it and are in progress."
  # "PG-48 (in progress) and PG-51 (defining) come before it."
  def pending_sentence(stories)
    groups = stories.chunk_while { |a, b| a.state == b.state }.to_a
    verb = stories.one? ? "comes" : "come"
    if groups.one?
      "#{sentence(stories.map(&:reference))} #{verb} before it and #{stories.one? ? 'is' : 'are'} #{state_words(stories.first.state)}."
    else
      "#{sentence(groups.map { "#{sentence(it.map(&:reference))} (#{state_words(it.first.state)})" })} #{verb} before it."
    end
  end

  # "PG-50 comes first but is blocked by PG-46 (in progress)."
  def blocked_sentence(blocked)
    blockers = @project.stories.where(number: blocked.pending_blockers(done_numbers: done_numbers)).order(:number)
    "#{blocked.reference} comes first but is blocked by #{sentence(blockers.map { "#{it.reference} (#{state_words(it.state)})" })}."
  end
end
