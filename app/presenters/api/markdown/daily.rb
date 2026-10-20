# `mt daily` (docs/CLI.md): los datos de la daily del proyecto para un actor.
# Maker Tracker no resume ni opina: enseña qué ha pasado, qué hay en curso, qué
# está bloqueado o espera a Fran y qué toca, y el agente pone el criterio.
class Api::Markdown::Daily
  include Api::Markdown::Formatting

  MAX_EVENTS = 40
  MAX_WAITING = 10
  TITLE_MIN = 24

  def initialize(daily)
    @daily = daily
    @project = daily.project
  end

  def to_s
    [ "# #{@project.name} · #{@project.key} · daily of #{@daily.actor.name}", intro, happened, in_progress, blocked, waiting, next_up ].join("\n\n") + "\n"
  end

  # Para el resumen y los datos.
  def window
    if @daily.explicit_since? then "since #{datetime(@daily.since)}"
    elsif @daily.first? then "first daily: the last #{Daily::DEFAULT_WINDOW.in_days.to_i} days"
    else "since your last daily, #{datetime(@daily.since)}"
    end
  end

  private

  def intro
    "Daily of #{@daily.actor.name} in #{@project.key}, #{window}. Today is #{datetime(Time.current)}."
  end

  def happened
    activity = @daily.activity
    return "## What happened\n\nNothing#{' yet' if @project.events.none?}." if activity.empty?

    events = activity.events
    skipped = [ events.size - MAX_EVENTS, 0 ].max
    events = events.last(MAX_EVENTS)
    codes = Api::Markdown::EventSentence.milestone_codes(@project)
    lines = events.group_by(&:story).flat_map do |story, group|
      heading = story ? "#{story.reference}  #{story.title}" : "Project"
      rows = group.map { [ datetime(it.occurred_at), it.actor.name, Api::Markdown::EventSentence.new(it, codes).to_s ] }
      [ heading, *table(rows).map { "  #{it}" } ]
    end
    title = "## What happened · #{plural(activity.size, 'event')} by #{activity.actors.map(&:name).sort.to_sentence(words_connector: ', ', two_words_connector: ' and ', last_word_connector: ' and ')}"
    lines.unshift("… and #{plural(skipped, 'earlier event')} not shown (mt show <story> has each history).", "") if skipped.positive?
    "#{title}\n\n#{lines.join("\n")}"
  end

  def in_progress
    return "## In progress\n\nNothing in progress." if @daily.in_progress.empty?

    rows = @daily.in_progress.map do |story|
      [ story.reference, story.title, story.claimed_by&.name || "nobody", ("since #{datetime(story.claimed_at)}" if story.claimed_at) ]
    end
    "## In progress\n\n#{table(rows, min: [ 0, TITLE_MIN ]).join("\n")}"
  end

  def blocked
    return "## Blocked\n\nNothing is blocked." if @daily.blocked.empty?

    done = @project.stories.done.pluck(:number)
    rows = @daily.blocked.map do |story|
      [ story.reference, story.title, "by #{sentence(story.pending_blockers(done_numbers: done).map { "#{@project.key}-#{it}" })}" ]
    end
    "## Blocked\n\n#{table(rows, min: [ 0, TITLE_MIN ]).join("\n")}"
  end

  def waiting
    human = Actor.human.name
    return "## Waiting for #{human}\n\nNothing." if @daily.waiting_for_human.empty?

    waiting = @daily.waiting_for_human
    rows = waiting.first(MAX_WAITING).map { |story, reasons| [ story.reference, story.title, reasons.join("; ") ] }
    lines = table(rows, min: [ 0, TITLE_MIN ])
    lines << "… and #{waiting.size - MAX_WAITING} more: mt list --state defining" if waiting.size > MAX_WAITING
    "## Waiting for #{human}\n\n#{lines.join("\n")}"
  end

  def next_up
    story = @daily.next_story
    ready = @daily.ready_count
    return "## What is next\n\nNo ready, unblocked story#{" (#{plural(ready, 'ready story', 'ready stories')} blocked)" if ready.positive?}. See the roadmap with mt roadmap." unless story

    others = ready - 1
    "## What is next\n\n#{story.reference}  #{story.title}\nWhy this one: #{Api::NextStory.new(@project).reason}#{" #{plural(others, 'more ready story', 'more ready stories')}." if others.positive?}"
  end
end
