# Que ninguna página de la documentación rompa su lectura (MT-116): `bin/ci`
# lee todas las de la BD (las seeds) y los ejemplos de lib/tasks/pages, que
# cubren «Cómo funciona» y «¿Qué pasa si…?» en `###` y en viñetas.
namespace :mt do
  namespace :pages do
    desc "Lee todas las páginas de la documentación y los ejemplos de lib/tasks/pages; falla si alguna no se deja leer"
    task check: :environment do
      fixtures = Rails.root.glob("lib/tasks/pages/{titulos,vinetas,inesperado}.md").to_h { [ it.basename(".md").to_s, Page::Reading.new(it.read).to_h ] }
      Page.find_each { it.reading.to_h }

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
      check_lint(expect)

      puts "#{Page.count} páginas y #{fixtures.size} ejemplos se leen bien."
    end
  end

  # lib/tasks/pages/lint.md en una página de verdad, con sus capturas c1.png y
  # «captura (2).png», dentro de una transacción que se deshace. Lint la lee
  # como la web: las `attachment:` resueltas (también con %20 y %28) y fuera
  # del texto, así que no hay frase y la segunda «Cómo funciona» cuenta; la
  # primera, con intro, es la que queda como prosa (no «repetida»). Y `--all`
  # con una sola página cierra con su resumen.
  def check_lint(expect)
    abort "mt:pages:check usa el proyecto ZZ para lint y ya existe" if Project.exists?(key: "ZZ")
    png = Base64.decode64("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=")
    blobs = []
    ActiveRecord::Base.transaction do
      actor = Actor.create!(name: "mt-pages-check", kind: :agent)
      project = Project.create_with_event!({ name: "Lint", key: "ZZ" }, actor: actor)
      page = project.pages.create!(slug: "lint-ejemplo", title: "Lint", body: Rails.root.join("lib/tasks/pages/lint.md").read)
      blobs = [ "c1.png", "captura (2).png" ].map { page.attach_file!(StringIO.new(png), filename: it, actor: actor).blob }

      lint = Page::Lint.new(page.reload)
      expect.("lint · errores", lint.errors.map { it.message[/\A\S+(?: \S+)?/] }, [ "no opening", "D-1 does", "ZZ-3 does", "image rota", "image suelta" ])
      expect.("lint · avisos", lint.warnings.map { it.message[/\A[^:]+/] }, [ "«Cómo funciona» will show as prose, not as rules", "image fuera is not an attachment of the page (https" ])
      expect.("lint · reglas y preguntas", [ lint.rules.size, lint.questions.size ], [ 2, 1 ])

      session = ActionDispatch::Integration::Session.new(Rails.application).tap { it.host = "localhost" }
      session.get "/api/projects/ZZ/docs/lint", headers: { "Authorization" => "Bearer #{actor.regenerate_token!}" }
      expect.("lint · --all con una página", JSON.parse(session.response.body).dig("data", "markdown").lines.last, "1 page in ZZ: 1 with errors.\n")
      raise ActiveRecord::Rollback
    end
  ensure
    blobs.each { ActiveStorage::Blob.service.delete(it.key) }
  end
end
