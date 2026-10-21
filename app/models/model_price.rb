# Precio por millón de tokens de un modelo (config/model_prices.yml). El
# servidor calcula los dólares: los precios cambian y los `mt` instalados se
# quedan viejos (MT-34).
class ModelPrice
  FIELDS = %i[input output cache_read cache_write_5m cache_write_1h].freeze

  class << self
    def table = @table ||= YAML.load_file(Rails.root.join("config/model_prices.yml"), symbolize_names: true)

    def as_of = table[:as_of]
    def source = table[:source]

    # El precio del modelo o nil. Se quita el sufijo de fecha y el de contexto
    # largo (`claude-haiku-4-5-20251001`, `claude-opus-5-5[1m]`); no se adivina
    # por prefijo parcial, para que un modelo nuevo no cobre como el anterior.
    def for(model)
      key = model.to_s.strip.downcase.sub(/\[[^\]]*\]\z/, "").sub(/-\d{8}\z/, "")
      row = table[:models][key.to_sym]
      row && new(row)
    end

    # Dólares (BigDecimal, 4 decimales) de tokens ya sumados por modelo, o nil si no tiene precio.
    def cost(model, tokens) = self.for(model)&.cost(tokens)
  end

  def initialize(row)
    @row = row
  end

  # `tokens`: input, output, cache_read, cache_write_5m, cache_write_1h.
  def cost(tokens)
    total = FIELDS.sum(BigDecimal("0")) { BigDecimal(@row.fetch(it).to_s) * tokens[it].to_i }
    (total / 1_000_000).round(4)
  end
end
