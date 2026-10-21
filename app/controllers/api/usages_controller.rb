# Coste por historia (MT-34): `mt usage` y el hook SessionEnd reportan el uso de
# una sesión. La historia la resuelve el servidor (Story.usage_target) salvo que
# llegue `story`. Si no hay ninguna, no se reporta nada.
class Api::UsagesController < Api::BaseController
  Formatting = Api::Markdown::Formatting

  def create
    source = params[:source].to_s.strip.presence || raise(Api::Error.validation("missing source.", hint: "claude-code, wflow…"))
    session_id = params[:session_id].to_s.strip.presence || raise(Api::Error.validation("missing session_id."))
    models = params[:models]
    unless models.is_a?(Array)
      raise Api::Error.validation("models must be a list of { model, input, output, cache_read, cache_write_5m, cache_write_1h }.")
    end

    ended_at = time_param(:ended_at) || Time.current
    started_at = time_param(:started_at) || ended_at
    target = params[:story].present? ? find_story(params[:story]) : Story.usage_target(project, Current.actor, started_at: started_at, ended_at: ended_at)
    unless target
      return render_ok({ story: nil, reported: false },
        summary: "no story of #{Current.actor.name} in progress during this session; nothing reported.")
    end

    event = begin
      target.report_usage!(actor: Current.actor, source: source, session_id: session_id, models: models, occurred_at: ended_at)
    rescue ArgumentError => e
      raise Api::Error.validation("#{e.message}.")
    end
    total = target.usage_total
    data = { story: Formatting.story_data(target), reported: event.present?, total: total && { tokens: total.tokens, cost_usd: total.cost_usd.to_f, sessions: total.sessions } }
    unless event
      return render_ok(data, summary: "#{target.reference}: nothing new in this session since the last report.", breadcrumbs: [ "mt show #{target.reference}" ])
    end

    data[:event] = event.data.slice("tokens", "cost_usd", "unpriced_models", "estimated")
    render_ok(data, status: :created, summary: summary_for(target, event), breadcrumbs: [ "mt show #{target.reference}" ])
  end

  private

  def summary_for(target, event)
    data = event.data
    unpriced = ", #{data['unpriced_models'].join(', ')} without a price" if data["unpriced_models"].any?
    "#{target.reference}: reported ~#{Formatting.dollars(data['cost_usd'])} and #{data['tokens']} tokens#{unpriced} (estimated). " \
      "A session that touches several stories goes to the last one started."
  end

  def time_param(name)
    value = params[name].presence or return
    Time.zone.parse(value.to_s) || raise(ArgumentError)
  rescue ArgumentError
    raise Api::Error.validation("#{name} is not a date and time.", hint: "use ISO 8601, like 2026-10-22T10:30:00Z.")
  end
end
