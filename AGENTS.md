# Maker Tracker

Herramienta para definir y organizar productos junto a agentes de IA. La v1 (estilo Pivotal Tracker) se ha retirado; la v2 se está construyendo según el roadmap.

**Antes de proponer, priorizar o construir nada, lee [`docs/PRODUCT.md`](docs/PRODUCT.md)**: visión, filosofía (agent-first, ligero), decisiones y preguntas abiertas. Si una decisión lo cambia, actualízalo.

- [`docs/ROADMAP.md`](docs/ROADMAP.md): qué construimos y en qué orden.
- [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md): modelo de datos v2, interfaz para agentes (`mt`, API, MCP), contrato de eventos y módulo de wflow.
- [`docs/DESIGN.md`](docs/DESIGN.md): sistema de diseño (tokens, tipografía, componentes, landing). Léelo antes de tocar UI; la skill `maker-tracker-design` (`.claude/skills/`) explica el procedimiento.
- [`docs/workstreams/`](docs/workstreams/README.md): el trabajo va en tres vertientes paralelas (producto, desarrollo, self-host), cada una con su brief, su worktree y lo que es suyo. Si eres uno de esos agentes, lee el README y tu brief antes de empezar.
- [`docs/backlog/`](docs/backlog/): historias en markdown hasta que la v2 guarde su propio backlog.

## Stack

- Ruby 3.4.8 (`.ruby-version`, gestionado con rbenv) · Rails 8.1
- SQLite (`storage/*.sqlite3`): no hace falta Docker ni ningún servicio externo
- Hotwire (Turbo + Stimulus) con importmap · Tailwind CSS v3 (`tailwindcss-rails` 3.x) · Sprockets
- Sin login: la app solo es accesible por red local o Tailscale · `positioning` para ordenar

## Comandos

```bash
bin/setup               # gemas + db:prepare (crea y siembra la BD) y arranca el servidor
bin/setup --skip-server # lo mismo sin arrancar el servidor
bin/setup --reset       # además borra la BD y vuelve a sembrarla
bin/dev                 # servidor en http://localhost:3002 (Tailwind en watch dentro de Puma)
bin/rubocop -A          # lint (con -A corrige todo lo que puede)
bin/ci                  # setup + lint + auditorías de seguridad + seeds (config/ci.rb); debe pasar antes de cada commit
```

- Puerto **3002** (fijo para poder levantarlo a la vez que el resto de proyectos). Se cambia con `PORT=...`.
- `/design` (solo en development) muestra el sistema de diseño y sus componentes.
- `bin/dev` es un solo proceso en primer plano; `debugger` funciona directamente en esa terminal.

## Notas

- `config/master.key` no está en git. Desarrollo y tests no lo necesitan; solo producción.
- Action Cable usa `async` en desarrollo y `solid_cable` en producción (BD `storage/production_cable.sqlite3`).
- No hay tests (se eliminaron) y los generadores de Rails no los crean. `bin/ci` es la comprobación que hay que pasar.
- Las seeds son idempotentes: `bin/rails db:seed` se puede ejecutar varias veces.
