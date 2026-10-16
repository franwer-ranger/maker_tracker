---
number: 12
title: Seeds · alinear con las pantallas de App
milestone: M1
state: ready
claimed_by:
mockup: https://app.paper.design/file/01M50CA4S5CN4Z8ERVW36XWDHF/p-C-0
labels: [seeds]
blocked_by: [6]
---

## Contexto

La #006 sembró Postgram a partir de los mockups antiguos (`4.2`, `4.4`, `4.6`). Ahora las pantallas de M1 están en Paper → `App` (`5.0`–`5.6`), aprobadas por Fran, y se parecen mucho pero añaden datos: más historias en M2, labels, bloqueos, una decisión sustituida y un segundo proyecto. Esta historia solo cubre esas diferencias, para que las historias de UI (#007–#011) se puedan comparar con Paper.

También resuelve dos dudas del Cierre de la #006:
- M2 tiene **12** historias (8 abiertas y 4 hechas): el `4/12` de `5.1`.
- El brief **sí** tiene Glosario (ver abajo).

## Historia

Como agente que construye una pantalla de M1, quiero que las seeds coincidan con los artboards de `App`, para comparar sin inventarme nada.

## Criterios de aceptación

- [ ] M2 queda con este orden y estos datos (`5.1 Tablero · M2` y `5.3 Roadmap`):

  | # | Título | Estado y detalles | Labels |
  |---|---|---|---|
  | 48 | Exportar post a PDF | En curso, `claude` (ya existe) | export |
  | 45 | Programar publicaciones | En curso, `codex` (ya existe) | calendario |
  | 49 | Plantillas de post reutilizables | Lista, `mockup` y `blocked_by: [47]` | editor, ui |
  | 50 | Vista previa por red social | Lista, `mockup` | editor |
  | 51 | Métricas de engagement | Definiendo, sin criterios | analítica |
  | 54 | Reprogramar arrastrando en el calendario | **Nueva.** Definiendo, `blocked_by: [45]` | calendario |
  | 52 | Hilos de X en un solo post | **Nueva.** Idea | editor |
  | 53 | Programar desde el móvil | **Nueva.** Idea | móvil |
  | 47, 43, 42, 41 | Borradores automáticos · Subir varias imágenes a la vez · Conectar Instagram · Conectar LinkedIn | Hechas (renombra si tenían otro título) | editor · editor · redes · redes |

- [ ] El cuerpo de #49 es el markdown de `5.6 Historia · Editando (#49)`: Contexto, Historia, los tres criterios, Fuera de alcance y Preguntas abiertas (vacía).
- [ ] El comentario de `claude` en #49 dice lo mismo que en `5.4`.
- [ ] El historial de #49 tiene los cuatro eventos de `5.4`. Al que ya existe se le añade "pasa a Definiendo" el 9 oct (fran).
- [ ] M3 tiene como objetivo "Saber qué post funciona y por qué".
- [ ] El brief añade `## Glosario` con: "Post: lo que escribe el maker, una vez. Publicación: cada copia de un post en una red."
- [ ] Decisiones como en `5.5 Brief`:
  - D-14 la registra `claude`.
  - Se añade **D-9** "Imágenes en S3 desde el principio", registrada por `fran`.
  - D-12 la sustituye (`supersedes`).
- [ ] Segundo proyecto **Maker Tracker** (`key: MT`), con un hito abierto "M1 · Núcleo v2", sin historias en curso y con su `project.created` de hace 2 días. Es la segunda fila de `5.0 Proyectos`.
- [ ] `Project#next_story` de Postgram sigue devolviendo #49 (#47 está hecha, así que no la bloquea).
- [ ] Siguen siendo idempotentes. `bin/ci` en verde.

## Fuera de alcance

- Cambiar la numeración que eligió la #006 para M1, M3, M4 y la bandeja.
- Runs y coste: M4.

## Notas para quien lo construya

- Textos exactos con el MCP de Paper sobre la página `App` (`get_jsx` / `get_node_info`).
- Los artboards `Pendiente · …` de esa página son diseños antiguos: no los uses como referencia de datos.

## Preguntas abiertas

## Cierre
