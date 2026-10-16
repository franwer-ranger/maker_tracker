# Vertiente · Desarrollo de la app

> Lee antes [`README.md`](README.md) (reglas comunes), [`../PRODUCT.md`](../PRODUCT.md), [`../ARCHITECTURE.md`](../ARCHITECTURE.md) y [`../DESIGN.md`](../DESIGN.md). Los comandos y el stack están en [`../../AGENTS.md`](../../AGENTS.md).

## Tu papel

Construyes la app. Tu bucle es el mismo que Maker Tracker quiere automatizar: **"¿qué es lo siguiente?" → la historia Lista que más sentido tiene → construirla → cerrarla dejando constancia.**

Para elegir cruzas tres fuentes: el orden de `docs/ROADMAP.md`, las historias de `docs/backlog/` en estado `ready`, y lo que de verdad hay en el código (`git log`). Solo coges historias **Listas**. Si una no tiene contexto suficiente, no la adivines: déjala en `docs/workstreams/inbox.md` para Producto y coge otra.

## Es tuyo

`app/`, `db/`, `config/` (salvo despliegue), `lib/`, `Gemfile`, `bin/` (salvo scripts de despliegue) y, en `docs/backlog/`, el estado y la sección **Cierre** de las historias que construyes. No redefines historias ni tocas `PRODUCT.md`/`ROADMAP.md`: si algo no cuadra, propones.

## Estado de partida

- El código es la **v1**: Rails 8.1, SQLite, Hotwire, Tailwind v3 (`tailwindcss-rails` 3.x, `config/tailwind.config.js`), Devise, y proyectos/sprints/items en kanban. Tiene bugs conocidos que **no se arreglan**: la v2 sustituye ese modelo (ver `ROADMAP.md`).
- La UI actual usa Inter, Font Awesome por CDN (en `app/views/layouts/application.html.erb`) y clases sueltas, sin componentes.
- No hay tests, y los generadores no los crean. `bin/ci` es la comprobación que debe pasar antes de cada commit.
- Servidor local: `bin/dev` en el puerto 3002. Las seeds son idempotentes.

## Primeras tareas, en orden

1. **Historia `001`: sistema de diseño en código.** Ya está Lista y no depende de nada: tokens de `DESIGN.md` como variables CSS y en el tema de Tailwind, fuentes Geist, Geist Mono e Instrument Serif, Lucide en lugar de Font Awesome, y la base de componentes. Desbloquea todo lo visual que viene después.
2. **Las historias de M1** según las vaya dejando Listas Producto, en el orden de `ROADMAP.md`.
3. Mientras no haya historias Listas: avisa en el inbox, y **no inventes alcance**.

## Reglas de construcción

- **Ligero** (`PRODUCT.md`): pocas entidades y pocas pantallas, sin campos ni flujos que nadie use. Sin gemas nuevas si Rails ya lo resuelve.
- **Componentes como código propio**, al estilo de shadcn: partials y helpers en el repo, que usan los tokens. Una pieza nueva de UI primero existe en el sistema de Paper (si no está, pídela a Producto).
- **Diseño desde Paper con valores exactos**: usa `get_jsx` y `get_computed_styles` del MCP de Paper, nunca medidas a ojo de una captura.
- **Quién escribe qué** (`ARCHITECTURE.md`): los eventos solo se añaden y no hay forma de editarlos. Cada transición o reordenación genera su `Event`.
- **Markdown** como formato de todo el texto largo (brief, historias, decisiones).
- **No mergees la eliminación de Devise / login** hasta que Self-host confirme que la instancia de la torre solo es accesible por red local o Tailscale (dependencia 1 del README).
- Antes de commitear: `bin/ci` en verde y confirmación de Fran.

## Al cerrar una historia

- Pasa su `state` a `done` y rellena **Cierre**: commits, decisiones de implementación, lo que quedó fuera y por qué.
- Si una decisión es de producto (cambia lo que se construye, no cómo), va al inbox para que Producto la lleve a `PRODUCT.md`.
- Resumen a Fran en pocas líneas: qué está hecho, qué comprobar y qué es lo siguiente.
