# Lee una historia en el formato de Api::Markdown::Story (frontmatter + cuerpo)
# y devuelve sus atributos. Es el inverso: lo que devuelve `mt show` se puede
# mandar sin tocar a `mt edit` y no cambia nada. Ignora lo que va tras la marca
# de solo lectura (bloqueos, comentarios, historial) y el motivo que antepone
# `mt next` (líneas `>` antes del frontmatter).
class Api::StoryDocument
  FIELDS = %w[number title milestone state claimed_by mockup labels blocked_by].freeze
  FRONTMATTER = /\A(?:[ \t]*(?:>.*)?\r?\n)*---\r?\n(.*?)\r?\n---[ \t]*(?:\r?\n|\z)(.*)\z/m

  def self.parse(markdown) = new(markdown).attributes

  def initialize(markdown)
    @markdown = markdown.to_s
  end

  # Solo las claves que trae el documento; `body` siempre.
  def attributes
    match = @markdown.match(FRONTMATTER)
    raise Api::Error.validation("El markdown no empieza por un frontmatter (---)", hint: "Parte de lo que devuelve mt show PG-49") unless match

    front = load_yaml(match[1])
    unknown = front.keys - FIELDS
    raise Api::Error.validation("Campos desconocidos en el frontmatter: #{unknown.join(', ')}", hint: "Los campos son #{FIELDS.join(', ')}") if unknown.any?

    body = match[2].split(Api::Markdown::Story::READ_ONLY_MARK, 2).first.strip
    front.transform_values { it.is_a?(String) ? it.strip.presence : it }.merge("body" => body)
  end

  private

  def load_yaml(text)
    data = YAML.safe_load(text) || {}
    raise Api::Error.validation("El frontmatter tiene que ser una lista de campos") unless data.is_a?(Hash)

    data.transform_keys(&:to_s)
  rescue Psych::SyntaxError => e
    raise Api::Error.validation("El frontmatter no es YAML válido: #{e.problem} (línea #{e.line})",
      hint: "Si un valor tiene «: » o empieza por un símbolo, ponlo entre comillas")
  end
end
