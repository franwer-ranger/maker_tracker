# `mt decisions`: todas, de la más reciente a la más antigua.
class Api::DecisionsController < Api::BaseController
  TITLE_MIN = 47 # columna del título (docs/CLI.md → mt decisions)

  def index
    decisions = project.decisions.reorder(number: :desc).includes(:actor, :story, :supersedes, :superseded_by).to_a
    data = decisions.map do |decision|
      { reference: decision.reference, title: decision.title, body: decision.body, actor: decision.actor.name,
        date: Api::Markdown::Formatting.date(decision.created_at), story: decision.story&.reference,
        supersedes: decision.supersedes&.reference, superseded_by: decision.superseded_by&.reference }.compact
    end
    render_ok({ decisions: data, markdown: markdown(data) },
      summary: "#{Api::Markdown::Formatting.plural(data.size, 'decision')} in #{project.name}.")
  end

  # `mt decide "…" --why "…" [--story PG-49] [--supersedes D-9]`. Solo se añaden.
  def create
    story = find_story(params[:story]) if params[:story].present?
    supersedes = find_decision(params[:supersedes]) if params[:supersedes].present?
    decision = project.record_decision!({ title: params.require(:title), body: params[:body].to_s, story: story, supersedes: supersedes }, actor: Current.actor)
    warnings = decision.body.blank? ? [ "it has no why: add --why next time, it's what gets read later." ] : []
    render_ok({ decision: { reference: decision.reference, title: decision.title, story: story&.reference, supersedes: supersedes&.reference }.compact },
      status: :created, warnings: warnings,
      summary: "#{decision.reference} recorded by #{Current.actor.name}#{", superseding #{supersedes.reference}" if supersedes}.",
      breadcrumbs: [ "mt decisions" ])
  end

  private

  def find_decision(reference)
    number = Integer(reference.to_s.sub(/\AD-/i, ""), exception: false)
    project.decisions.find_by(number: number) ||
      raise(Api::Error.not_found("decision #{reference} does not exist.", hint: "see them with mt decisions."))
  end

  # D-14  PDFs con Prawn, sin servicios externos           claude  2026-10-16  PG-48
  #       Why: autoalojado y sin coste por documento.
  def markdown(data)
    return "No decisions yet.\n" if data.empty?

    rows = data.map do |d|
      tags = [ d[:story], ("supersedes #{d[:supersedes]}" if d[:supersedes]), ("superseded by #{d[:superseded_by]}" if d[:superseded_by]) ].compact
      [ d[:reference], d[:title], d[:actor], d[:date], tags.join("  ") ]
    end
    lines = Api::Markdown::Formatting.table(rows, min: [ 0, TITLE_MIN, "claude".length ])
    indent = " " * (rows.map { it.first.length }.max + 2)
    items = lines.zip(data).map do |line, d|
      why = d[:body].to_s.strip
      why.present? ? "#{line}\n#{indent}Why: #{why.gsub(/\n(?=.)/, "\n#{indent}")}" : line
    end
    "#{items.join("\n")}\n"
  end
end
