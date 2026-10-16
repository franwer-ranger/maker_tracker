---
number: 6
title: Seeds · Postgram como en los mockups
milestone: M1
state: done
claimed_by: development
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

Rama `dev/v2-model`, commit «Siembra Postgram como en los mockups v2».

**Hecho**
- `db/seeds.rb` siembra lo siguiente, con los textos sacados con el MCP de Paper (`get_jsx` sobre `4.2`, `4.4` y `4.6`):
  - Actores `fran`, `claude` y `codex`.
  - Postgram (`PG`) con el brief de `4.6`.
  - Cuatro hitos con sus objetivos. M1 está cerrado hace 34 días («12 sep» en el mockup).
  - 41 historias: M1 con 9 hechas; M2 en el orden del roadmap, con #48 reclamada por claude y #45 por codex; M3 con 6 historias, 4 en Definiendo y #28 bloqueada por #51; M4 con 3 ideas; y 14 ideas en la bandeja con `labels`.
  - D-12, D-13 y D-14 (la D-14 ligada a #48) y comentarios en #49 y #48.
  - El historial de #49 tal como sale en `4.4`: creada el 3 oct, claude la edita ayer a las 22:31 y pasa a Lista ayer a las 22:40. También el `story.claimed` de #48 y #45.
- `Project#next_story` de Postgram devuelve PG-49.
- Idempotentes: después de `db:seed:replant` y otro `db:seed`, los recuentos no cambian (3 actores, 1 proyecto, 4 hitos, 41 historias, 3 decisiones, 3 comentarios y 5 eventos).

**Decisiones**
- Todo se crea con `find_or_create_by!` por clave natural (nombre, `key`, título, `number`, cuerpo). Los eventos solo se añaden si la historia aún no tiene uno con esa acción y ese actor. Las seeds no pasan por las operaciones de dominio, para no generar eventos que no salen en los mockups.
- Las fechas son relativas a `Time.current`: «3 oct» son 13 días antes, «ayer 22:40» es ayer a esa hora.
- Los cuerpos de las decisiones son el «Por qué» del mockup sin la etiqueta. El «Vinculada a #48» de la D-14 es la relación con la historia, no texto.
- Los números que el mockup no da son inventados: M1 #1–#9, bandeja #10–#23, M4 #24–#26 y M3 #27–#32. Quedan huecos (#33–#40, #44 y #46).

**Fuera / a revisar con Producto**
- El mockup dice «En curso · 4/10» en M2, pero la tabla de la historia da 9 historias (5 visibles y 4 hechas). He seguido la tabla.
- El brief no tiene Glosario en el mockup: la sección queda vacía.
