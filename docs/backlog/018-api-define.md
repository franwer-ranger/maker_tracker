---
number: 18
title: API · definir producto (crear, editar, mover y ordenar)
milestone: M2
state: done
claimed_by: development
mockup:
labels: [api]
blocked_by: [16]
---

## Contexto

Fran decidió el 2026-10-16 que en M2 los agentes también escriben producto, **directamente y con registro**: crean y editan historias, las mueven de estado y las reordenan. Sin esto, Maker Tracker no se puede construir con Maker Tracker, porque el agente de Producto no podría escribir el backlog en la app. Si hacen falta propuestas que Fran apruebe, se decide en M3 (`PRODUCT.md` → Preguntas abiertas).

## Historia

Como agente de producto, quiero crear, editar y ordenar historias, hitos y el brief por la API, para escribir el backlog donde vive en vez de en ficheros.

## Criterios de aceptación

- [x] **Crear historia** (`POST …/projects/PG/stories`): o con campos (`title`, `milestone`, `state`, `body`, `mockup`, `labels`, `blocked_by`), o con un `markdown` en el formato de **ver** (#016). Sin `state`, nace como Idea; sin `milestone`, va a la bandeja de ideas. Sin `body`, la plantilla.
- [x] **Editar historia** (`PATCH …/stories/49`): igual que crear, con `Story#edit!`. Si llega `markdown`, se aplican `title`, cuerpo, `mockup`, `labels` y `blocked_by`. Si cambian `state` o `milestone`, error `VALIDATION_FAILED` con hint ("Usa mt move PG-49 ready" / "mt reorder"): son hechos con su propio evento. `number` y `claimed_by` se ignoran.
- [x] **Mover** (`POST …/stories/49/move`, `state`). Al pasar a Lista, la regla de `PRODUCT.md` es un warning, no un bloqueo: "Tiene preguntas abiertas" o "Tiene label ui y no tiene mockup".
- [x] **Reordenar** (`POST …/stories/49/reorder`, `position` y/o `milestone`, `reason`). Un agente sin motivo recibe `REASON_REQUIRED`. Las posiciones se cuentan desde 1.
- [x] **Hitos**: crear (`title`, `goal`), editar el objetivo, reordenar (con motivo), cerrar y reabrir.
- [x] **Brief** (`PUT …/projects/PG/brief`, `markdown`): `Project#edit_brief!`.
- [x] Todo con su evento a nombre del actor. Ninguna operación borra nada.
- [x] `bin/ci` en verde.

## Fuera de alcance

- Borrar historias o hitos (no se puede ni en la UI).
- Crear proyectos por la API: lo hace Fran desde la UI.
- Propuestas que Fran aprueba: M3.

## Notas para quien lo construya

- Editar un hito (`goal`) no tiene operación todavía. Añade `Milestone#edit!` con su evento `milestone.edited`, como `Story#edit!`.
- El parser del markdown con frontmatter es el mismo para crear y editar, y es el inverso de `Api::Markdown::Story`. Que lo que devuelve **ver** se pueda mandar sin tocar y no cambie nada.

## Preguntas abiertas

## Cierre

Rama `dev/m2-api`, commit «Añade la definición de producto a la API».

**Hecho**
- Historias: `POST …/stories` (crear), `PATCH …/stories/:n` (editar), `POST …/stories/:n/move` y `…/reorder`. Hitos: `POST …/milestones`, `PATCH …/milestones/:code`, `…/reorder`, `…/close` y `…/reopen`. Brief: `GET` y `PUT …/brief` (el `GET` es para `mt brief` sin `--file`). Todo en `GET /api`.
- `Api::StoryDocument` lee el formato de `Api::Markdown::Story`: frontmatter con YAML (`safe_load`) y cuerpo, sin lo que va tras la marca de solo lectura ni el motivo (`> …`) que antepone `mt next`. Comprobado: todas las historias de las seeds hacen el viaje de ida y vuelta sin cambios, `mt show` → `mt edit` y `mt next` → `mt edit` dan «sin cambios», y los 23 ficheros de `docs/backlog/` se leen bien (para la #022).
- **Crear**: con campos o con `markdown`. Sin `state`, Idea; sin `milestone`, bandeja; sin `body`, la plantilla. Warnings de la regla de Lista si nace Lista.
- **Editar**: `Story#edit!` con título, cuerpo, mockup, labels y bloqueos. Si cambian `state` o `milestone`, `VALIDATION_FAILED` con el comando que toca en el hint. `number` y `claimed_by` se ignoran. Un cuerpo igual salvo por espacios al principio o al final no cuenta como cambio.
- **Mover**: `move_to!`, con los warnings de `Story#readiness_issues` al pasar a Lista.
- **Reordenar**: posiciones desde 1 (la gema ya cuenta así y recorta si te pasas), `milestone` opcional, `REASON_REQUIRED` sin motivo.
- `Milestone#edit!` (título y objetivo) con su evento `milestone.edited`.

**Decisiones**
- Una historia nueva solo nace en Idea, Definiendo o Lista. Para En curso o Hecha, se crea y luego `mt start` / `mt done`, para que el reclamo y el cierre tengan su evento.
- Los hitos se citan por código (`M2`) o título. Ojo: el código es la posición, así que `milestone reorder` cambia los códigos (el summary dice el nuevo: «M5 pasa a ser M2»).
- Un agente no puede mover la historia En curso de otro (`CLAIMED_BY_OTHER`), como en `done` y `release`.

**Fuera**
- Los mensajes de validación de Rails salen en inglés («Title can't be blank»), igual que en la UI: no hay locale `es`. No es de esta historia.
