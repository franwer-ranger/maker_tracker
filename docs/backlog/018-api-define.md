---
number: 18
title: API · definir producto (crear, editar, mover y ordenar)
milestone: M2
state: ready
claimed_by:
mockup:
labels: [api]
blocked_by: [16]
---

## Contexto

Fran decidió el 2026-10-16 que en M2 los agentes también escriben producto, **directamente y con registro**: crean y editan historias, las mueven de estado y las reordenan. Sin esto, Maker Tracker no se puede construir con Maker Tracker, porque el agente de Producto no podría escribir el backlog en la app. Si hacen falta propuestas que Fran apruebe, se decide en M3 (`PRODUCT.md` → Preguntas abiertas).

## Historia

Como agente de producto, quiero crear, editar y ordenar historias, hitos y el brief por la API, para escribir el backlog donde vive en vez de en ficheros.

## Criterios de aceptación

- [ ] **Crear historia** (`POST …/projects/PG/stories`): o con campos (`title`, `milestone`, `state`, `body`, `mockup`, `labels`, `blocked_by`), o con un `markdown` en el formato de **ver** (#016). Sin `state`, nace como Idea; sin `milestone`, va a la bandeja de ideas. Sin `body`, la plantilla.
- [ ] **Editar historia** (`PATCH …/stories/49`): igual que crear, con `Story#edit!`. Si llega `markdown`, se aplican `title`, cuerpo, `mockup`, `labels` y `blocked_by`. Si cambian `state` o `milestone`, error `VALIDATION_FAILED` con hint ("Usa mt move PG-49 ready" / "mt reorder"): son hechos con su propio evento. `number` y `claimed_by` se ignoran.
- [ ] **Mover** (`POST …/stories/49/move`, `state`). Al pasar a Lista, la regla de `PRODUCT.md` es un warning, no un bloqueo: "Tiene preguntas abiertas" o "Tiene label ui y no tiene mockup".
- [ ] **Reordenar** (`POST …/stories/49/reorder`, `position` y/o `milestone`, `reason`). Un agente sin motivo recibe `REASON_REQUIRED`. Las posiciones se cuentan desde 1.
- [ ] **Hitos**: crear (`title`, `goal`), editar el objetivo, reordenar (con motivo), cerrar y reabrir.
- [ ] **Brief** (`PUT …/projects/PG/brief`, `markdown`): `Project#edit_brief!`.
- [ ] Todo con su evento a nombre del actor. Ninguna operación borra nada.
- [ ] `bin/ci` en verde.

## Fuera de alcance

- Borrar historias o hitos (no se puede ni en la UI).
- Crear proyectos por la API: lo hace Fran desde la UI.
- Propuestas que Fran aprueba: M3.

## Notas para quien lo construya

- Editar un hito (`goal`) no tiene operación todavía. Añade `Milestone#edit!` con su evento `milestone.edited`, como `Story#edit!`.
- El parser del markdown con frontmatter es el mismo para crear y editar, y es el inverso de `Api::Markdown::Story`. Que lo que devuelve **ver** se pueda mandar sin tocar y no cambie nada.

## Preguntas abiertas

## Cierre
