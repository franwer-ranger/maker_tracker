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

  private

  def markdown(data)
    items = data.map do |d|
      tags = [ d[:date], d[:actor], ("de #{d[:story]}" if d[:story]), ("sustituye a #{d[:supersedes]}" if d[:supersedes]) ].compact.join(" · ")
      title = d[:superseded_by] ? "~~#{d[:reference]} · #{d[:title]}~~ (sustituida por #{d[:superseded_by]})" : "#{d[:reference]} · #{d[:title]}"
      "## #{title}\n\n#{tags}#{"\n\n#{d[:body].strip}" if d[:body].present?}"
    end
    "# Decisiones · #{project.name}\n\n#{items.join("\n\n").presence || '_Ninguna._'}\n"
  end
end
