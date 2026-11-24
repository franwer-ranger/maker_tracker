# Las capacidades que cambia una historia pasan a ser una propiedad
# (`properties.capabilities`, MT-91) en lugar de leerse del cuerpo (MT-90).
# Copia, con la regla de MT-90, los slugs que ya enlazaba la sección «## Qué
# cambia del producto» (exactos, entre backticks, fuera de comentarios HTML y
# de bloques de código, y de páginas que existen), para que las decisiones
# que se registren después en esas historias hereden lo mismo. No toca las
# decisiones ya enlazadas (`decision_capabilities`) ni las historias que ya
# tienen la propiedad. Sin páginas de capacidad no hace nada. Solo escribe
# en `stories.properties`, sin eventos ni versión: es la misma información.
class BackfillStoryCapabilities < ActiveRecord::Migration[8.1]
  SECTION = /^\#\# Qué cambia del producto[ \t]*$(.*?)(?=^\#\# |\z)/m
  CODE_BLOCK = /^[ \t]*(`{3,}|~{3,}).*?(?:^[ \t]*\1[ \t]*$|\z)/m
  CODE_SPAN = /(?<!`)`([^`\n]+)`(?!`)/

  def up
    pages = select_rows("SELECT project_id, slug FROM pages WHERE kind != 'cover' ORDER BY project_id, area IS NULL, area, title")
    return if pages.empty?

    pages.group_by(&:first).each do |project_id, rows|
      slugs = rows.map(&:last)
      stories = select_rows(<<~SQL.squish)
        SELECT id, body FROM stories WHERE project_id = #{Integer(project_id)}
          AND json_extract(properties, '$.capabilities') IS NULL AND body LIKE '%Qué cambia del producto%'
      SQL
      stories.each do |id, body|
        section = body.to_s[SECTION, 1].to_s.gsub(/<!--.*?-->/m, "").gsub(CODE_BLOCK, "")
        found = section.scan(CODE_SPAN).flatten.map(&:strip).uniq
        linked = slugs.select { found.include?(it) }
        next if linked.empty?

        execute "UPDATE stories SET properties = json_set(properties, '$.capabilities', json(#{quote(linked.to_json)})) WHERE id = #{Integer(id)}"
      end
    end
  end

  # La propiedad se queda: sin MT-91 nadie la lee.
  def down
  end
end
