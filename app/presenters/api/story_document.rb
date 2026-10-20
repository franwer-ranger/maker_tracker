# Lee una historia en el formato de Api::Markdown::Story (frontmatter + cuerpo)
# y devuelve sus atributos. Es el inverso: lo que devuelve `mt show` se puede
# mandar sin tocar a `mt edit` y no cambia nada. Ignora lo que va tras la marca
# de solo lectura (relacionadas, comentarios, historial) y las líneas que
# antepone `mt next` antes del frontmatter (Next up:, Why this one:).
class Api::StoryDocument
  FIELDS = %w[number version title milestone state claimed_by mockup labels blocked_by].freeze
  FRONTMATTER = /\A(?:(?!---[ \t]*\r?\n)[^\n]*\n)*?---[ \t]*\r?\n(.*?)\r?\n---[ \t]*(?:\r?\n|\z)(.*)\z/m

  def self.parse(markdown) = new(markdown).attributes

  def initialize(markdown)
    @markdown = markdown.to_s
  end

  # Solo las claves que trae el documento; `body` siempre.
  def attributes
    match = @markdown.match(FRONTMATTER)
    raise Api::Error.validation("the markdown has no frontmatter (---).", hint: "start from what mt show PG-49 prints.") unless match

    front = load_yaml(match[1])
    unknown = front.keys - FIELDS
    raise Api::Error.validation("unknown frontmatter keys: #{unknown.join(', ')}.", hint: "the keys are #{FIELDS.join(', ')}.") if unknown.any?

    body = match[2].split(Api::Markdown::Story::READ_ONLY_MARK, 2).first.to_s.strip
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
