# Que ninguna página de la documentación rompa su lectura (MT-116): `bin/ci`
# lee todas las de la BD (las seeds) y los ejemplos de lib/tasks/pages, que
# cubren «Cómo funciona» y «¿Qué pasa si…?» en `###` y en viñetas.
namespace :mt do
  namespace :pages do
    desc "Lee todas las páginas de la documentación y los ejemplos de lib/tasks/pages; falla si alguna no se deja leer"
    task check: :environment do
      fixtures = Rails.root.glob("lib/tasks/pages/{titulos,vinetas,inesperado}.md").to_h { [ it.basename(".md").to_s, Page::Reading.new(it.read).to_h ] }
      Page.find_each { Page::Reading.new(it.body, attachments: it.screenshots.map { Attachable.path(it) }).to_h }

      expect = ->(name, actual, expected) { abort "#{name}: esperaba #{expected.inspect}, sale #{actual.inspect}" unless actual == expected }
      titulos, vinetas, inesperado = fixtures.values_at("titulos", "vinetas", "inesperado")
      expect.("titulos · reglas", titulos[:rules].map { it.values_at(:title, :text, :decisions) }, [
        [ "La nota cabe entera en el marco", "Hasta 140 caracteres y 4 líneas. El servidor comprueba lo mismo.", [ "D-30" ] ],
        [ "La nota puede ir vacía", "Basta la foto y el lugar para sellar.", [ "D-47" ] ],
        [ "Sin texto debajo", nil, [] ]
      ])
      expect.("titulos · preguntas", titulos[:questions].map(&:values), [
        [ "¿… pego un texto muy largo?", "Se corta a lo que cabe (PG-8)." ],
        [ "¿… me cambio el nombre?", "Solo cambia el «from» de las fotos que dejes desde entonces." ]
      ])
      expect.("viñetas · reglas", vinetas[:rules].map { it.values_at(:title, :text, :decisions) }, [
        [ "Avisa del enlace", "Si falta `{enlace}`, avisa antes de publicar y deja seguir.", [ "D-52" ] ],
        [ "Cada red recibe su copia", "La longitud se adapta.", [] ]
      ])
      expect.("viñetas · preguntas", vinetas[:questions].map(&:values), [
        [ "¿Y si no tengo redes?", "No deja publicar." ], [ "¿Y si una red falla?", "Se reintenta una vez." ]
      ])
      # Un `###` vacío no se deja partir y unas preguntas con intro no son solo preguntas: las dos, como prosa.
      expect.("inesperado · como prosa", [ inesperado[:rules], inesperado[:questions], inesperado[:sections].map { it[:title] } ],
        [ nil, nil, [ "Cómo funciona", "¿Qué pasa si…?" ] ])

      # `mt doc lint` (MT-123) sobre las mismas lecturas: sin frase, citas e imágenes rotas son errores; lo demás, avisos.
      Page.documentation.find_each { Page::Lint.new(it).to_h }
      lint = Page::Lint.new(Page.new(project: Project.new(key: "ZZ"), slug: "lint-ejemplo", body: Rails.root.join("lib/tasks/pages/lint.md").read))
      expect.("lint · errores", lint.errors.map { it.message[/\A\S+(?: \S+)?/] }, [ "no opening", "D-1 does", "ZZ-3 does", "image rota", "image suelta" ])
      expect.("lint · avisos", lint.warnings.map { it.message[/\A\S+ \S+/] }, [ "«Cómo funciona»", "image fuera" ])
      expect.("lint · preguntas", lint.questions.size, 1)

      puts "#{Page.count} páginas y #{fixtures.size} ejemplos se leen bien."
    end
  end
end
