# Una historia leída como documento (MT-104, «v1 · 4 · Historia»): su cuerpo
# partido en las piezas que pinta la UI.
#
# - `sentence`: «## Historia» (la historia en una frase).
# - `changes`: «## Qué cambia del producto», por capacidad (las de
#   `capabilities`). Una línea con `+` añade y con `=` no cambia; sin marca,
#   añade. Un `###` o una línea en negrita con el título o el slug de una
#   capacidad abre su bloque; con una sola capacidad, todo es suyo. Lo que no
#   cae en ninguna va en `changes_text`, para no perder texto.
# - `criteria`: las casillas de «## Criterios de aceptación».
# - `out_of_scope`: «## Fuera de alcance» en una línea.
# - `context`: el resto de secciones, tal cual (lo que se pliega).
class Story::Reading
  OWN = /\A(historia|criterios de aceptaci[oó]n|qu[eé] cambia del producto|fuera de alcance)\z/i
  CHECKBOX = /\A\s*[-*]\s+\[([ xX])\]\s+(.+)\z/
  BULLET = /\A\s*(?:[-*]|\d+[.)])\s+/

  attr_reader :sentence, :criteria, :out_of_scope, :context, :changes, :changes_text

  def initialize(story)
    @story = story
    sections = body_sections(story.body)
    @sentence = paragraphs(sections["historia"]).first
    @criteria = criteria_in(sections["criterios de aceptación"])
    @out_of_scope = out_of_scope_in(sections["fuera de alcance"])
    @changes, @changes_text = changes_in(sections["qué cambia del producto"], story.changed_capabilities.to_a)
    rest = story.body.to_s.gsub("\r\n", "\n").split(/^(?=## +)/).select { it.start_with?("## ") && !it[/\A## +(.+)$/, 1].strip.match?(OWN) }
    # Sin preámbulo, Page::Reading no saca frase: todo va en secciones.
    @context = Page::Reading.new(rest.join.gsub(/<!--.*?-->/m, "")).sections.reject { it[:blocks].empty? }
  end

  private

  # { "título en minúsculas" => texto sin comentarios HTML }
  def body_sections(body)
    body.to_s.gsub("\r\n", "\n").scan(/^## +(.+?)\s*$\n(.*?)(?=^## |\z)/m).to_h do |title, text|
      [ title.strip.downcase, text.gsub(/<!--.*?-->/m, "").strip ]
    end
  end

  def paragraphs(text) = text.to_s.split(/\n\s*\n/).map(&:squish).compact_blank

  def criteria_in(text)
    text.to_s.lines.filter_map do |line|
      next unless (match = line.match(CHECKBOX))

      { text: match[2].strip, done: match[1] != " " }
    end
  end

  def out_of_scope_in(text)
    lines = text.to_s.lines.map(&:strip).compact_blank
    return [] if lines.empty?

    bullets = lines.grep(BULLET)
    bullets.any? ? bullets.map { it.sub(BULLET, "").strip } : [ lines.join(" ") ]
  end

  def changes_in(text, pages)
    blocks = pages.map { { slug: it.slug, capability: it.title, icon: it.icon, adds: [], keeps: [] } }
    current = blocks.one? ? blocks.first : nil
    loose = []
    text.to_s.lines.map(&:strip).compact_blank.each do |line|
      if (heading = line[/\A###+\s+(.+)\z/, 1] || line[/\A\*\*([^*]+)\*\*:?\z/, 1])
        found = blocks.find { |block| [ block[:slug], block[:capability].downcase ].include?(heading.strip.delete_suffix(":").downcase) }
        next current = found if found
      end
      item = line.sub(BULLET, "")
      mark, rest = item.match(/\A([+=])\s*(.*)\z/)&.captures
      if current
        (mark == "=" ? current[:keeps] : current[:adds]) << (rest || item)
      else
        loose << line
      end
    end
    [ blocks, loose.join("\n").presence ]
  end
end
