# Turno de noche: Maker Tracker

Un solo repo (este) para todo el proyecto `MT`: web, API y la CLI `mt` en `cli/`. Corre en la torre, como el usuario `cobertizo`.

- etiqueta: ninguna. Todas las historias del proyecto `MT` son de este repo, tengan la etiqueta que tengan (`ui`, `api`, `cli`, `tech`, `agentes` o ninguna). Elige con `mt next` y `mt list --state ready`, sin filtrar por etiqueta.
- base: main
- checks: `bin/ci`
- checks_rápidos: `bin/rubocop -A`, y si tocas `cli/`: `gofmt -l cli` (sin salida) y `make -C cli vet build`
- app: en el worktree, `cp -n .env.example .env` si falta, `bin/setup --skip-server` (crea y siembra su propia BD de desarrollo en `storage/` del worktree) y `PORT=3012 bin/dev` en segundo plano. Lista cuando `curl -fsS http://localhost:3012/up` da 200. Si el 3012 está ocupado por algo que no arrancaste tú, no lo mates: devuelve `APP: no arranca` diciendo qué lo ocupa. Las verificaciones van **de una en una** (puerto fijo).
- despliegue: `cd /srv/maker-tracker && bin/deploy` (la instancia real, desplegada por cobertizo desde su propio clon: git pull, `docker compose up -d --build`, espera a `/up` y `mt deployed`)
- riesgo:
  - `db/migrate/**`, `db/schema.rb`, `db/seeds*`, `bin/backup`, `bin/restore` → datos
  - `app/controllers/api/**`, `config/routes.rb`, `cli/**`, `docs/CLI.md` → contrato (la API y la salida de `mt` las leen los agentes de todos los proyectos)
  - `Dockerfile`, `compose.yml`, `bin/deploy`, `bin/docker-entrypoint`, `config/deploy*` → entrega
- notas:
  - Lee `AGENTS.md` y `docs/PRODUCT.md` antes de tocar nada; para UI, `docs/DESIGN.md` y la skill `maker-tracker-design` (`.claude/skills/`). `docs/CLI.md` es el contrato de la salida de `mt`: si cambias lo que imprime un comando, cámbialo en el mismo commit.
  - No hay tests de Ruby (se eliminaron): no los añadas. `bin/ci` es la comprobación.
  - **La instancia real de Maker Tracker no se toca.** Es el contenedor `maker-tracker-app-1` en `127.0.0.1:3002` (y `https://omarchy-tower.chamois-triceratops.ts.net`), con los proyectos de verdad (`PG` y los demás). Nunca la uses para probar, nunca hagas `docker compose` sobre ella (solo el `despliegue`) y nunca toques `~franwer/Projects/maker_tracker` ni `/srv/maker-tracker` (el clon del que se despliega: solo lo usa el `despliegue`). Por eso la app de la historia va en el 3012 y con su BD del worktree.
  - `mt` habla con la instancia real: úsalo solo para la propia historia (`mt show`, `mt start`, `mt comment`…). Para probar un cambio de la CLI, compílalo (`make -C cli build`) y apúntalo a la app del worktree con `MT_URL=http://localhost:3012` y un token de esa BD (`bin/rails "mt:token[claude]"` en el worktree), nunca a la real. No crees ni borres proyectos en la real.
  - Verificación en el navegador con **agent-browser** (headless, ya instalado con su Chromium). Antes de nada, carga su skill (`~/.claude/skills/agent-browser/SKILL.md`) y su guía: `agent-browser skills get core`. Usa siempre `--session night-<id>` para no chocar con otro carril, guarda las capturas con `agent-browser --session night-<id> screenshot <evidence>/NN-<criterio>.png` y, al acabar, `agent-browser --session night-<id> close`. Para la CLI, ejecútala y guarda la salida en `evidence/NN-<criterio>.txt`.
  - Identidad git: la del repo (ya configurada), nunca otra.
