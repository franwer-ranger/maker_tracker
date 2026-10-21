# Coste de una historia (MT-34, D-65): una estimación en tokens y dólares que
# reporta el hook SessionEnd de Claude Code (o wflow, con su `source`). No hay
# columna: el total es la suma de los eventos `usage.reported` de la historia.
#
# Cada reporte trae el total ACUMULADO de la sesión; el evento guarda solo la
# diferencia con el último reporte de la misma sesión (`source` + `session_id`,
# en `data.session_total`). Reenviar lo mismo no crea nada, reanudar suma lo
# nuevo y un total menor se ignora. Los dólares se calculan aquí (ModelPrice).
module Story::Usage
  extend ActiveSupport::Concern

  ACTION = "usage.reported".freeze
  TOKEN_FIELDS = %i[input output cache_read cache_write_5m cache_write_1h].freeze

  # Lo que suman los eventos de uso de una historia.
  Total = Data.define(:tokens, :cost_usd, :sessions, :unpriced_tokens) do
    def unpriced? = unpriced_tokens.positive?
  end

  class_methods do
    # La historia a la que va una sesión: de las que ESTE actor empezó
    # (`story.state_changed` a En curso o `story.claimed`) antes de acabar la
    # sesión, la que empezó más tarde que siga En curso o dejara de estarlo
    # después del inicio de la sesión. nil si ninguna.
    def usage_target(project, actor, started_at:, ended_at:)
      starts = project.events.where(actor: actor, action: %w[story.state_changed story.claimed])
        .where.not(story_id: nil).where(occurred_at: ..ended_at).order(:occurred_at, :id).includes(:story)
        .select { it.action == "story.claimed" || it.data["to"] == "in_progress" }
      latest = starts.group_by(&:story_id).transform_values(&:last).values.sort_by { [ it.occurred_at, it.id ] }
      latest.reverse_each do |start|
        story = start.story
        left = story.events.where(action: "story.state_changed").where(occurred_at: [ started_at, start.occurred_at ].max..)
        return story if story.in_progress? || left.any? { it.data["from"] == "in_progress" }
      end
      nil
    end
  end

  # El total de la historia, sumando sus eventos.
  def usage_total
    events = self.events.where(action: ACTION).to_a
    return if events.empty?

    cost = events.sum(BigDecimal("0")) { BigDecimal(it.data["cost_usd"].to_s) }
    unpriced = events.sum { |e| Array(e.data["models"]).sum { |m| Array(e.data["unpriced_models"]).include?(m["model"]) ? m["tokens"].to_i : 0 } }
    Total.new(tokens: events.sum { it.data["tokens"].to_i }, cost_usd: cost,
      sessions: events.map { [ it.data["source"], it.data["session_id"] ] }.uniq.size, unpriced_tokens: unpriced)
  end

  # Registra el reporte de una sesión. `models`: [{ model:, input:, output:, … }]
  # con los totales acumulados. Devuelve el evento, o nil si no hay nada nuevo.
  def report_usage!(actor:, source:, session_id:, models:, occurred_at: nil)
    total = self.class.normalize_usage(models)
    with_lock do
      previous = project.events.where(action: ACTION).recent_first.find { it.data["source"] == source && it.data["session_id"] == session_id }
      before = (previous&.data&.dig("session_total", "models")).to_a.index_by { it["model"] }
      next if total.sum { it["tokens"] } <= before.values.sum { it["tokens"].to_i }

      delta = total.filter_map do |row|
        old = before[row["model"]] || {}
        diff = TOKEN_FIELDS.to_h { |f| [ f.to_s, [ row[f.to_s] - old[f.to_s].to_i, 0 ].max ] }
        next if diff.values.sum.zero?

        price = ModelPrice.for(row["model"])
        { "model" => row["model"], **diff, "tokens" => diff.values.sum, "cost_usd" => price&.cost(diff.symbolize_keys)&.to_f }.compact
      end
      cost = delta.sum(BigDecimal("0")) { it["cost_usd"].to_s.to_d }
      data = { source: source, session_id: session_id, models: delta, tokens: delta.sum { it["tokens"] }, cost_usd: cost.round(4).to_f,
               estimated: true, unpriced_models: delta.reject { it["cost_usd"] }.map { it["model"] },
               session_total: { models: total, tokens: total.sum { it["tokens"] } } }
      record_event!(ACTION, actor: actor, story: self, data: data, occurred_at: occurred_at)
    end
  end

  class_methods do
    # Una fila por modelo con enteros >= 0 (y la misma sesión con un modelo repetido, sumada).
    def normalize_usage(models)
      rows = Array(models).filter_map { it.respond_to?(:to_unsafe_h) ? it.to_unsafe_h : it.to_h if it.respond_to?(:to_h) }.map(&:stringify_keys)
      rows.group_by { it["model"].to_s.strip }.reject { |name, _| name.empty? }.map do |name, group|
        row = TOKEN_FIELDS.to_h { |f| [ f.to_s, group.sum { [ it[f.to_s].to_i, 0 ].max } ] }
        row.merge("model" => name, "tokens" => row.values.sum)
      end
    end
  end
end
