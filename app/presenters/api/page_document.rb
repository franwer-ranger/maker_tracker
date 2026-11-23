# Lee una página en el formato de Api::Markdown::Page (frontmatter + cuerpo) y
# devuelve sus atributos, con `type` como `kind`. Es el inverso: lo que imprime
# `mt doc tablero` se puede mandar sin tocar a `mt doc edit` y no cambia nada.
# Ignora lo que va tras la marca de solo lectura (el historial).
class Api::PageDocument
  FIELDS = %w[slug version type title icon area].freeze
  READ_ONLY = /^<!-- mt: read-only below this line[^\n]*-->/

  def self.parse(markdown) = new(markdown).attributes

  def initialize(markdown)
    @markdown = markdown.to_s
  end

  # Solo las claves que trae el documento; `body` siempre. Sin frontmatter, todo es el cuerpo.
  def attributes
    match = @markdown.match(Api::StoryDocument::FRONTMATTER)
    front, body = match ? [ load_yaml(match[1]), match[2] ] : [ {}, @markdown ]
    unknown = front.keys - FIELDS
    raise Api::Error.validation("unknown frontmatter keys: #{unknown.join(', ')}.", hint: "the keys are #{FIELDS.join(', ')}.") if unknown.any?

    front["kind"] = front.delete("type") if front.key?("type")
    body = body.split(READ_ONLY, 2).first.to_s.strip
    front.transform_values { it.is_a?(String) ? it.strip.presence : it }.merge("body" => body)
  end

  private

  def load_yaml(text)
    data = YAML.safe_load(text) || {}
    raise Api::Error.validation("the frontmatter must be a list of keys and values.") unless data.is_a?(Hash)

    data.transform_keys(&:to_s)
  rescue Psych::SyntaxError => e
    raise Api::Error.validation("the frontmatter is not valid YAML: #{e.problem} (line #{e.line}).",
      hint: "quote values that contain \": \" or start with a symbol.")
  end
end
