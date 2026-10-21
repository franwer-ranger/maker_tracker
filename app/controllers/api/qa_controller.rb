# QA pendiente (MT-32): `mt qa` lista lo que Fran aún no ha probado, y
# `mt qa PG-49 ok|fail` lo cierra. Solo una persona prueba (como las preguntas).
class Api::QaController < Api::BaseController
  Formatting = Api::Markdown::Formatting

  # `mt qa [--project PG]`: lo pendiente de todos los proyectos, lo más antiguo primero.
  def index
    cards = Activity.new.qa_pending
    cards = cards.select { it.project.key == params[:project].to_s.upcase } if params[:project].present?
    summary = "#{cards.size} #{cards.one? ? 'story' : 'stories'} waiting for QA."
    render_ok({ stories: cards.map { qa_data(it) }, markdown: list_markdown(summary, cards) },
      summary: summary, breadcrumbs: cards.first(3).map { "mt show #{it.story.reference}" })
  end

  # `mt qa PG-49 ok [--note "…"]` o `mt qa PG-49 fail --note "…"`
  def create
    raise forbidden_error if Current.actor.agent?

    result = params[:result].to_s
    unless %w[ok fail].include?(result)
      raise Api::Error.validation("result must be ok or fail, not #{result.presence || 'empty'}.",
        hint: "mt qa #{story.reference} ok [--note \"…\"] or mt qa #{story.reference} fail --note \"what fails\".")
    end
    result == "ok" ? pass : fail_it
  rescue Story::Qa::NotPending => e
    raise Api::Error.new("NOT_PENDING", "#{e.story.reference} is not waiting for QA#{qa_reason(e.story)}.", status: :conflict,
      hint: "see what is waiting with mt qa.")
  end

  private

  def pass
    changed = story.qa_pass!(actor: Current.actor, note: params[:note])
    render_ok({ story: Formatting.story_data(story.reload) },
      summary: changed ? "#{story.reference} passed QA." : "#{story.reference} had already passed QA.", breadcrumbs: [ "mt qa" ])
  end

  def fail_it
    note = params[:note].to_s.strip
    if note.empty?
      raise Api::Error.validation("a failed QA needs a note saying what fails.", hint: "mt qa #{story.reference} fail --note \"what fails\".")
    end

    fix = story.qa_fail!(note: note, actor: Current.actor)
    render_ok({ story: Formatting.story_data(story.reload), created: Formatting.story_data(fix) }, status: :created,
      summary: "#{story.reference} failed QA. #{fix.reference} was created in #{fix.milestone ? Formatting.milestone_label(fix.milestone) : 'the inbox'} as defining, linked to it.",
      breadcrumbs: [ "mt show #{fix.reference}", "mt qa" ])
  end

  def qa_reason(story)
    return " (it is #{Formatting.state_words(story.state)})" unless story.done?

    story.qa_failed? ? " (it failed QA already)" : " (it was done before QA existed)"
  end

  def forbidden_error
    human = Actor.human.name
    Api::Error.new("FORBIDDEN", "only a person tests QA, and #{Current.actor.name} is an agent.", status: :forbidden,
      hint: "#{human} passes or fails it with mt qa or in the app. You can list what is waiting with mt qa.")
  end

  def qa_data(card)
    { reference: card.story.reference, title: card.story.title, project: card.project.key, done_at: card.done_at.iso8601,
      done_by: card.done_by&.name, commits: card.commits.map { { sha: it.sha, message: it.message }.compact }, url: card.url, criteria: card.criteria }.compact
  end

  # PG-47  Borradores automáticos  done 2026-10-20 18:40 by codex  https://testing.postgram.app
  #        1 Mientras escribes, el post se guarda solo…
  def list_markdown(summary, cards)
    return "#{summary}\n" if cards.empty?

    rows = cards.map { [ it.story.reference, it.story.title, "done #{Formatting.datetime(it.done_at)}#{" by #{it.done_by.name}" if it.done_by}", it.url || "no \"Dónde se prueba\" line in the brief" ] }
    items = Formatting.table(rows, min: [ 0, Formatting::TITLE_WIDTH ]).zip(cards).map do |line, card|
      [ line, *card.criteria.each_with_index.map { |text, i| "#{' ' * 7}#{i + 1} #{text}" }, *card.commits.map { "#{' ' * 7}#{it.label}" } ].join("\n")
    end
    "#{summary}\n\n#{items.join("\n")}\n"
  end
end
