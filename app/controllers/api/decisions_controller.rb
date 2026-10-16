# `mt decisions`: todas, de la más reciente a la más antigua.
class Api::DecisionsController < Api::BaseController
  def index
    decisions = project.decisions.reorder(number: :desc).includes(:actor, :story, :supersedes, :superseded_by).to_a
    data = decisions.map do |decision|
      { reference: decision.reference, title: decision.title, body: decision.body, actor: decision.actor.name,
        date: Api::Markdown::Formatting.date(decision.created_at), story: decision.story&.reference,
        supersedes: decision.supersedes&.reference, superseded_by: decision.superseded_by&.reference }.compact
    end
    render_ok({ decisions: data, markdown: markdown(data) },
      summary: "#{data.size} #{data.size == 1 ? 'decisión' : 'decisiones'} en #{project.name}",
      breadcrumbs: [ 'mt decide "…" --why "…"' ])
  end

  # `mt decide "…" --why "…" [--story PG-49] [--supersedes D-9]`. Solo se añaden.
  def create
    story = find_story(params[:story]) if params[:story].present?
    supersedes = find_decision(params[:supersedes]) if params[:supersedes].present?
    decision = project.record_decision!({ title: params.require(:title), body: params[:body].to_s, story: story, supersedes: supersedes }, actor: Current.actor)
    warnings = decision.body.blank? ? [ "Sin porqué: añade --why la próxima vez, es lo que se lee después" ] : []
    render_ok({ decision: { reference: decision.reference, title: decision.title, story: story&.reference, supersedes: supersedes&.reference }.compact },
      status: :created, warnings: warnings,
      summary: "#{decision.reference} registrada por #{Current.actor.name}#{", sustituye a #{supersedes.reference}" if supersedes}",
      breadcrumbs: [ "mt decisions" ])
  end

  private

  def find_decision(reference)
    number = Integer(reference.to_s.sub(/\AD-/i, ""), exception: false)
    project.decisions.find_by(number: number) ||
      raise(Api::Error.not_found("No existe la decisión #{reference}", hint: "Las decisiones están en mt decisions"))
  end

  def markdown(data)
    items = data.map do |d|
      tags = [ d[:date], d[:actor], ("de #{d[:story]}" if d[:story]), ("sustituye a #{d[:supersedes]}" if d[:supersedes]) ].compact.join(" · ")
      title = d[:superseded_by] ? "~~#{d[:reference]} · #{d[:title]}~~ (sustituida por #{d[:superseded_by]})" : "#{d[:reference]} · #{d[:title]}"
      "## #{title}\n\n#{tags}#{"\n\n#{d[:body].strip}" if d[:body].present?}"
    end
    "# Decisiones · #{project.name}\n\n#{items.join("\n\n").presence || '_Ninguna._'}\n"
  end
end
