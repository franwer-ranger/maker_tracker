---
number: 17
title: API · reclamar, cerrar, comentar y decidir
milestone: M2
state: ready
claimed_by:
mockup:
labels: [api]
blocked_by: [15]
---

## Contexto

La otra mitad del ciclo: un agente de desarrollo coge una historia, la construye fuera (en su repo) y la cierra enlazando el código. Por el camino comenta (preguntas, avances) y registra las decisiones que tome.

## Historia

Como agente de desarrollo, quiero reclamar una historia, cerrarla con sus commits y dejar comentarios y decisiones, para que Fran vea qué he hecho sin preguntarme.

## Criterios de aceptación

- [ ] **Empezar** (`POST …/stories/49/start`): `move_to!(:in_progress)`. Si es de otro, `CLAIMED_BY_OTHER`. Si no está Lista, la empieza igualmente pero añade un warning ("PG-51 está en Definiendo: puede que le falte contexto"). Si está bloqueada, otro warning con lo que la bloquea.
- [ ] **Terminar** (`POST …/stories/49/done`, `commits: [sha]`, `pr: url`, ambos opcionales): `move_to!(:done)`, con `commits` y `pr` en el `data` del evento. Sin commits ni PR, warning.
- [ ] **Soltar** (`POST …/stories/49/release`, `reason`): la devuelve a Lista y la libera. El motivo queda en el evento.
- [ ] **Comentar** (`POST …/stories/49/comments`, `body` en markdown).
- [ ] **Decidir** (`POST …/projects/PG/decisions`, `title`, `body` con el porqué y, opcionales, `story` y `supersedes`). Devuelve la referencia (`D-15`).
- [ ] Todo se guarda a nombre del actor del token y deja su evento. Los `summary` lo dicen ("PG-49 en curso, reclamada por claude").
- [ ] Repetir una operación que no cambia nada (empezar una que ya es tuya) no es un error: `ok: true` y un `summary` que lo dice.
- [ ] `bin/ci` en verde.

## Fuera de alcance

- Ver los commits y la PR en la página de la Historia: el historial ya enseña el evento. Mostrarlos mejor llega con los runs (M4).

## Notas para quien lo construya

- `done` y `release` no necesitan operaciones nuevas: son `move_to!` con datos extra en el evento. Si hace falta, `move_to!` acepta un `data:` adicional.

## Preguntas abiertas

## Cierre
