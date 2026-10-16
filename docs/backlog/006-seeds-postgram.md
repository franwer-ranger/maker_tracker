---
number: 6
title: Seeds · Postgram como en los mockups
milestone: M1
state: ready
claimed_by:
mockup: https://app.paper.design/file/01M50CA4S5CN4Z8ERVW36XWDHF/p-8-0
labels: [modelo, seeds]
blocked_by: [5]
---

## Contexto

Las pantallas de M1 se revisan contra Paper. Para eso, la base de datos de desarrollo tiene que contener lo mismo que los mockups v2 (página `v2 · Agent-first`): el proyecto **Postgram**, con sus hitos, historias, decisiones y agentes. `bin/ci` ejecuta las seeds (`db:seed:replant`), así que también son la prueba de que el modelo se sostiene.

## Historia

Como agente que construye una pantalla, quiero datos de desarrollo iguales a los de los mockups, para comparar lo que construyo con Paper sin inventarme nada.

## Criterios de aceptación

- [ ] Actores: `fran` (humano), `claude` y `codex` (agentes).
- [ ] Proyecto **Postgram**, `key: PG`, con un `brief` como el del artboard `4.6 Brief`: Visión, Principios (los tres) y Fuera de alcance, con esos textos.
- [ ] Hitos en orden, con título y objetivo como en `4.2 Roadmap`:
  - M1 "Cuentas y primer post", cerrado, con 9 historias hechas.
  - M2 "Publicar sin fricción" (objetivo: "un maker programa una semana de posts en menos de 10 minutos").
  - M3 "Analítica para makers": 6 historias, 4 de ellas en Definiendo.
  - M4 "Equipos": solo ideas.
- [ ] En M2 y en este orden:

  | Historia | Título | Estado y detalles |
  |---|---|---|
  | #48 | Exportar post a PDF | En curso, reclamada por `claude` |
  | #45 | Programar publicaciones | En curso, reclamada por `codex` |
  | #49 | Plantillas de post reutilizables | Lista, con el cuerpo de `4.4 Historia · Lista (#49)`: historia, los tres criterios y las notas |
  | #50 | Vista previa por red social | Lista, con `mockup` |
  | #51 | Métricas de engagement | Definiendo, sin criterios |
  | #41, #42, #43, #47 | — | Hechas |

  Los números coinciden con los del mockup (fíjalos al crear). Las que el mockup no detalla llevan títulos verosímiles.
- [ ] Varias ideas en la bandeja (sin hito), con algunas `labels`, y al menos una historia con `blocked_by` para que se vea una bloqueada.
- [ ] Decisiones D-12, D-13 y D-14 con los textos de `4.6 Brief`. D-14 va ligada a #48.
- [ ] Algún comentario en #49 y #48.
- [ ] Eventos coherentes: #49 tiene su historial ("Creada desde una idea" → claude edita → pasa a Lista, como en el artboard), y #48 y #45 tienen su `story.claimed`.
- [ ] `Project#next_story` de Postgram devuelve #49.
- [ ] Idempotentes: `bin/rails db:seed` dos veces no duplica nada. `bin/ci` en verde.

## Fuera de alcance

- Runs, coste y paradas de wflow (#45 "PR #61 · revisión" en el mockup): M4.
- Un segundo proyecto. Si hace falta uno para probar el selector de proyectos, se añade en la #007.

## Notas para quien lo construya

- Lee los textos exactos de los artboards con el MCP de Paper (`get_node_info` / `get_jsx` sobre `4.2`, `4.4` y `4.6`). No los copies de una captura.
- Para que los eventos tengan fechas como "ayer 22:40" o "3 oct", fija `occurred_at` relativo a `Time.current`.
- Las seeds pueden crear registros directamente y añadir los eventos a mano. No hace falta pasar por las operaciones de dominio si así quedan más claras, pero el resultado tiene que ser el mismo.

## Preguntas abiertas

## Cierre
