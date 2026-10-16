# El onboarding de un agente (`mt context`, docs/CLI.md): brief entero, las
# decisiones vigentes más recientes, hito actual y lo que está en curso.
class Api::Markdown::Context
  include Api::Markdown::Formatting

  DECISIONS = 5
  TITLE_MIN = 24 # columna del título en "In progress"

  def initialize(project)
    @project = project
  end

  def decisions = @decisions ||= in_force.limit(DECISIONS).includes(:actor, :story, :supersedes).to_a

  # En el orden del roadmap: hitos abiertos, luego los demás y la bandeja.
  def in_progress
    @in_progress ||= @project.stories.in_progress.includes(:claimed_by, :milestone).to_a
      .sort_by { [ it.milestone ? 0 : 1, it.milestone&.position.to_i, it.position ] }
  end

  def to_s
    [ "# #{@project.name} · #{@project.key}", edited_line, brief, decisions_section,
      milestone_section, in_progress_section ].join("\n\n") + "\n"
  end

  private

  def in_force = @project.decisions.reorder(number: :desc).where.missing(:superseded_by)

  def edited_line
    event = @project.events.where(action: "brief.edited").includes(:actor).recent_first.first
    event ? "Project context. Brief last edited #{date(event.occurred_at)} by #{event.actor.name}." : "Project context."
  end

  def brief = @project.brief.strip.presence || "No brief yet. Write it with mt brief --file <f.md>."

  # D-14  PDFs con Prawn, sin servicios externos
  #       Why: autoalojado y sin coste por documento. · claude · 2026-10-16 · PG-48
  def decisions_section
    return "## Decisions in force\n\nNone yet." if decisions.empty?

    width = decisions.map { it.reference.length }.max
    items = decisions.map do |decision|
      tags = [ decision.actor.name, date(decision.created_at), decision.story&.reference,
               ("supersedes #{decision.supersedes.reference}" if decision.supersedes) ].compact
      why = decision.body.to_s.strip.gsub(/\s*\n\s*/, " ")
      tags.unshift("Why: #{why}") if why.present?
      "#{decision.reference.ljust(width)}  #{decision.title}\n#{' ' * (width + 2)}#{tags.join(' · ')}"
    end
    more = in_force.count - decisions.size
    items << "… and #{more} more: mt decisions" if more.positive?
    "## Decisions in force\n\n#{items.join("\n")}"
  end

  def milestone_section
    milestone = @project.current_milestone
    return "## Current milestone\n\nNo open milestone." unless milestone

    lines = [ "## Current milestone · #{milestone_label(milestone)}", "" ]
    lines << "Goal: #{goal(milestone.goal)}" if milestone.goal.present?
    lines << counts(milestone.stories.group(:state).count)
    lines.join("\n")
  end

  # "4 of 12 done · 2 in progress · 2 ready · 2 defining · 2 ideas"
  def counts(by_state)
    total = by_state.values.sum
    parts = [ "#{by_state.fetch('done', 0)} of #{total} done" ]
    parts << "#{by_state['in_progress']} in progress" if by_state["in_progress"]
    parts << "#{by_state['ready']} ready" if by_state["ready"]
    parts << "#{by_state['defining']} defining" if by_state["defining"]
    parts << plural(by_state["idea"], "idea") if by_state["idea"]
    parts.join(" · ")
  end

  def in_progress_section
    return "## In progress\n\nNothing in progress." if in_progress.empty?

    rows = in_progress.map do |story|
      [ story.reference, story.title, story.claimed_by&.name || "nobody", ("since #{datetime(story.claimed_at)}" if story.claimed_at) ]
    end
    "## In progress\n\n#{table(rows, min: [ 0, TITLE_MIN ]).join("\n")}"
  end
end
