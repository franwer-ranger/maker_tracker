# Maker Tracker

Gestor de proyectos estilo Pivotal Tracker: proyectos, sprints, items (historias/bugs) y comentarios.

## Stack

- Ruby 3.4.8 (`.ruby-version`, gestionado con rbenv) · Rails 8.1
- SQLite (`storage/*.sqlite3`): no hace falta Docker ni ningún servicio externo
- Hotwire (Turbo + Stimulus) con importmap · Tailwind CSS v3 (`tailwindcss-rails` 3.x) · Sprockets
- Devise para autenticación · `positioning` para ordenar items

## Comandos

```bash
bin/setup               # gemas + db:prepare (crea y siembra la BD) y arranca el servidor
bin/setup --skip-server # lo mismo sin arrancar el servidor
bin/setup --reset       # además borra la BD y vuelve a sembrarla
bin/dev                 # servidor en http://localhost:3002 (Tailwind en watch dentro de Puma)
bin/rails test          # tests
bin/rubocop             # lint
bin/ci                  # setup + lint + seguridad + tests (config/ci.rb)
```

- Puerto **3002** (fijo para poder levantarlo a la vez que el resto de proyectos). Se cambia con `PORT=...`.
- Usuario de desarrollo (seeds): `fran@gmail.com` / `12345678`.
- Los emails no se envían en desarrollo: se ven en http://localhost:3002/letter_opener.
- `bin/dev` es un solo proceso en primer plano; `debugger` funciona directamente en esa terminal.

## Notas

- `config/master.key` no está en git. Desarrollo y tests no lo necesitan; solo producción.
- Action Cable usa `async` en desarrollo y `solid_cable` en producción (BD `storage/production_cable.sqlite3`).
- Los tests de controladores son scaffolds antiguos y fallan (fixtures sin `position` ni `project`): pendiente de arreglar.
