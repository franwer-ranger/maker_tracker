---
number: 17
title: API · reclamar, cerrar, comentar y decidir
milestone: M2
state: done
claimed_by: development
mockup:
labels: [api]
blocked_by: [15]
---

## Contexto

La otra mitad del ciclo: un agente de desarrollo coge una historia, la construye fuera (en su repo) y la cierra enlazando el código. Por el camino comenta (preguntas, avances) y registra las decisiones que tome.

## Historia

Como agente de desarrollo, quiero reclamar una historia, cerrarla con sus commits y dejar comentarios y decisiones, para que Fran vea qué he hecho sin preguntarme.

## Criterios de aceptación

- [x] **Empezar** (`POST …/stories/49/start`): `move_to!(:in_progress)`. Si es de otro, `CLAIMED_BY_OTHER`. Si no está Lista, la empieza igualmente pero añade un warning ("PG-51 está en Definiendo: puede que le falte contexto"). Si está bloqueada, otro warning con lo que la bloquea.
- [x] **Terminar** (`POST …/stories/49/done`, `commits: [sha]`, `pr: url`, ambos opcionales): `move_to!(:done)`, con `commits` y `pr` en el `data` del evento. Sin commits ni PR, warning.
- [x] **Soltar** (`POST …/stories/49/release`, `reason`): la devuelve a Lista y la libera. El motivo queda en el evento.
- [x] **Comentar** (`POST …/stories/49/comments`, `body` en markdown).
- [x] **Decidir** (`POST …/projects/PG/decisions`, `title`, `body` con el porqué y, opcionales, `story` y `supersedes`). Devuelve la referencia (`D-15`).
- [x] Todo se guarda a nombre del actor del token y deja su evento. Los `summary` lo dicen ("PG-49 en curso, reclamada por claude").
- [x] Repetir una operación que no cambia nada (empezar una que ya es tuya) no es un error: `ok: true` y un `summary` que lo dice.
- [x] `bin/ci` en verde.

## Fuera de alcance

- Ver los commits y la PR en la página de la Historia: el historial ya enseña el evento. Mostrarlos mejor llega con los runs (M4).

## Notas para quien lo construya

- `done` y `release` no necesitan operaciones nuevas: son `move_to!` con datos extra en el evento. Si hace falta, `move_to!` acepta un `data:` adicional.

## Preguntas abiertas

## Cierre

Rama `dev/m2-api`, commit «Añade las operaciones de trabajo de la API».

**Hecho**
- `POST …/stories/:n/start`, `…/done` (`commits`, `pr`), `…/release` (`reason`), `…/stories/:n/comments` (`body`) y `POST …/decisions` (`title`, `body`, `story`, `supersedes`), en `Api::StoryWorkController`, `Api::CommentsController` y `Api::DecisionsController`. Están en `GET /api`.
- `Story#move_to!` acepta `data:` (se añade al evento: `commits` y `pr` al terminar) y `reason:`. `release!` también acepta `reason:`.
- **Empezar**: warnings si está en Idea o Definiendo, si ya estaba Hecha y si está bloqueada («PG-54 está bloqueada por PG-45 (en curso)»). Si estaba En curso sin dueño, la reclama (`story.claimed`).
- Repetir una operación que no cambia nada da `ok: true` y lo dice («PG-49 ya estaba en curso y es tuya», «ya estaba hecha», «no la tenía nadie»).
- Arreglado al probar: `move_to!(:in_progress)` sobre una historia que ya está En curso y es de otro devolvía false en lugar de `ClaimedByOther`. Ahora la comprobación va antes. La UI no cambia: ahí el actor siempre es Fran.

**Decisiones**
- Un agente no puede terminar ni soltar la historia de otro (`CLAIMED_BY_OTHER`). Fran sí, con su token, como dice el hint.
- **Soltar** pide motivo a los agentes (`REASON_REQUIRED`), como reordenar: en el CLI `--reason` no es opcional.
- Una decisión sin porqué se registra, con un warning.
- `story` admite `PG-49` o `49`, y `supersedes` admite `D-9` o `9`.
