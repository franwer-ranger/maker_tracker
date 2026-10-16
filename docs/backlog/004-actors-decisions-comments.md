---
number: 4
title: Modelo v2 · actores, decisiones y comentarios
milestone: M1
state: ready
claimed_by:
mockup:
labels: [modelo]
blocked_by: [3]
---

## Contexto

Sin login, lo que importa es saber **quién hizo qué**: Fran o un agente (`claude`, `codex`…). Eso es el `Actor`. Para M1 hay un único actor humano, y todo lo que pase en la UI se le atribuye a él. Las decisiones (qué decidimos y por qué) y los comentarios de una historia también los escribe un actor. Ver `docs/ARCHITECTURE.md` (Modelo de datos) y `docs/PRODUCT.md` → Decisiones → 2026-10-16.

## Historia

Como Fran, quiero que cada decisión, comentario y acción quede firmada por quien la hizo (yo o un agente), para saber qué está pasando sin preguntar.

## Criterios de aceptación

**Actor**
- [ ] Campos: `name` (único, en minúsculas, sin espacios: `fran`, `claude`), `kind` (`human` / `agent`) y `token_digest` (opcional; se usará en M2).
- [ ] `Actor.human` devuelve el actor humano. Si no existe, lo crea con el nombre `fran`.
- [ ] `Current.actor` (con `ActiveSupport::CurrentAttributes`) vale `Actor.human` en todas las peticiones de la UI. Lo fija `ApplicationController`.
- [ ] `Story#claimed_by` (de la #003) apunta ya a `Actor`.

**Decision**
- [ ] Campos: `project`, `story` (opcional), `number`, `title`, `body` (markdown: el porqué) y `actor`.
- [ ] `number` es correlativo por proyecto. `Decision#reference` devuelve `D-14`.
- [ ] **Solo se añaden**: una decisión guardada no se puede modificar ni borrar (`readonly?` una vez persistida). Para cambiar una decisión se escribe otra; un campo opcional `supersedes` (otra decisión del mismo proyecto) dice a cuál sustituye.

**Comment**
- [ ] Campos: `story`, `actor` y `body` (markdown).
- [ ] Ordenados por fecha. No se editan ni se borran en M1.

- [ ] En `bin/rails runner` se puede crear una decisión ligada a una historia y comprobar que intentar actualizarla falla.
- [ ] `bin/ci` en verde.

## Fuera de alcance

- Tokens de agente y autenticación de la API: M2. Aquí solo existe la columna.
- Colaboración entre varias personas: después del MVP.
- Eventos: #005 (añadir una decisión o un comentario generará su evento allí).

## Notas para quien lo construya

- `Current` en `app/models/current.rb`.
- La única forma de ser `human` en M1 es `Actor.human`. No hace falta impedir crear más humanos, pero la UI siempre usa ese.

## Preguntas abiertas

## Cierre
