---
number: 4
title: Modelo v2 · actores, decisiones y comentarios
milestone: M1
state: done
claimed_by: development
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

Rama `dev/v2-model`, commit «Añade actores, decisiones y comentarios».

**Hecho**
- Migración `CreateActorsDecisionsComments`: `actors`, `decisions` y `comments`, la clave ajena de `stories.claimed_by_id` a `actors` y el contador `projects.last_decision_number`.
- `Actor`: `name` único, normalizado a minúsculas y validado (`[a-z0-9_-]`); `kind` como enum `human` / `agent`; `token_digest` sin usar hasta M2. `Actor.human` devuelve el primer humano o crea `fran`.
- `Current.actor` (`app/models/current.rb`), que `ApplicationController` fija a `Actor.human` en cada petición.
- `Decision`: número correlativo por proyecto (`D-14`), `supersedes` / `superseded_by`, y historia y decisión sustituida del mismo proyecto. `readonly?` una vez guardada: `update!` y `destroy!` lanzan `ActiveRecord::ReadOnlyRecord`.
- `Comment`: ordenados por fecha en `Story#comments`, de solo lectura una vez guardados.
- Comprobado en `bin/rails runner` (en una transacción que se deshace): `Actor.human`, normalización, `claimed_by`, numeración y sustitución de decisiones, que editar o borrar una decisión o un comentario falla, y las validaciones de proyecto.

**Decisiones**
- La numeración de historias y decisiones comparte el concern `NumberedInProject` y `Project#reserve_number!`, con un contador por tipo (`last_story_number`, `last_decision_number`).
- Los comentarios también son de solo lectura en el modelo, no solo en la UI: la historia dice que no se editan ni se borran en M1.
