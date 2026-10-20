# Lo que enseña un formulario cuando lo que editabas cambió entretanto (MT-37):
# qué cambió desde que lo abriste (`base` → `theirs`), qué has escrito tú
# (`mine`) y cómo seguir. Compara textos; no fusiona nada por su cuenta: donde
# los dos habéis tocado el mismo campo, manda lo tuyo y se avisa.
class EditConflict
  MAX_ROWS = 6

  Row = Data.define(:mark, :text)

  attr_reader :labels, :base, :mine, :theirs, :editor, :edited_at

  # Los cuatro hashes van por nombre de campo, con textos ya normalizados.
  def initialize(labels:, base:, mine:, theirs:, editor: nil, edited_at: nil)
    @labels, @base, @mine, @theirs, @editor, @edited_at = labels, base, mine, theirs, editor, edited_at
  end

  def fields = labels.keys

  # Campos que cambió el otro desde la versión que abriste.
  def changed_by_them = fields.reject { theirs[it] == base[it] }

  # Campos que los dos habéis cambiado y no coinciden.
  def clashes = fields.select { theirs[it] != base[it] && mine[it] != base[it] && mine[it] != theirs[it] }

  # Campos donde lo tuyo y lo suyo difieren: lo que enseña «Ver las dos versiones».
  def differing = fields.select { mine[it] != theirs[it] }

  # Tu texto en lo que solo tocaste tú, el suyo en lo que solo tocó él, y el
  # tuyo donde chocáis.
  def merged = fields.index_with { mine[it] != base[it] ? mine[it] : theirs[it] }

  # Filas «+ / − / ~» de lo que cambió el otro, las primeras MAX_ROWS.
  def rows = all_rows.first(MAX_ROWS)

  def more = [ all_rows.size - MAX_ROWS, 0 ].max

  private

  def all_rows
    @all_rows ||= changed_by_them.flat_map do |field|
      if field == "body" || field == "brief"
        line_diff(base[field], theirs[field])
      else
        [ Row.new("~", "#{labels[field]}: #{theirs[field].presence || '—'}") ]
      end
    end
  end

  # Líneas que ya no están (−) y líneas nuevas (+), ignorando las vacías.
  def line_diff(old_text, new_text)
    old_lines = old_text.to_s.lines.map(&:strip).compact_blank
    new_lines = new_text.to_s.lines.map(&:strip).compact_blank
    common = lcs(old_lines, new_lines)
    removed = old_lines - common
    added = new_lines - common
    # Con duplicados, `-` quita todas; basta para un resumen.
    removed.map { Row.new("−", it) } + added.map { Row.new("+", it) }
  end

  def lcs(a, b)
    table = Array.new(a.size + 1) { Array.new(b.size + 1, 0) }
    a.each_with_index do |x, i|
      b.each_with_index do |y, j|
        table[i + 1][j + 1] = x == y ? table[i][j] + 1 : [ table[i][j + 1], table[i + 1][j] ].max
      end
    end
    out = []
    i, j = a.size, b.size
    while i.positive? && j.positive?
      if a[i - 1] == b[j - 1] then out.unshift(a[i - 1]); i -= 1; j -= 1
      elsif table[i - 1][j] >= table[i][j - 1] then i -= 1
      else j -= 1
      end
    end
    out
  end
end
