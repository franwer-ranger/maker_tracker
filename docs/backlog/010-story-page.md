---
number: 10
title: Historia · ver y definir una historia
milestone: M1
state: done
claimed_by: development
mockup: https://app.paper.design/file/01M50CA4S5CN4Z8ERVW36XWDHF/p-C-0
labels: [ui]
blocked_by: [7]
---

## Contexto

Aquí es donde Fran define: escribe el markdown con la IA, enlaza el mockup, marca dependencias y la pasa a Lista. La historia también cuenta lo que ha pasado: historial y comentarios de los agentes. La plantilla y las propiedades están en `docs/PRODUCT.md` → 2026-10-16.

## Historia

Como Fran, quiero leer y editar una historia (cuerpo, propiedades y estado) y ver su historial, para dejarla lista para que un agente la construya sin preguntar.

## Criterios de aceptación

- [ ] Miga de pan `Roadmap / M2 · Publicar sin fricción / #49`. Título grande y el cuerpo markdown renderizado; los `- [ ]` y `- [x]` se ven como casillas.
- [ ] Editar título y cuerpo: textarea con pestaña de vista previa (`marked` ya está en el importmap). Guardar llama a `Story#edit!`.
- [ ] Columna lateral:
  - **Estado** con el selector de cinco estados (`state_selector` de la #001) y un texto de qué significa. En Lista: "Siguiente en el roadmap…" si es la siguiente; si no, su posición.
  - **Propiedades**: hito (selector), mockup (enlace a Paper), labels y "Bloqueada por" (`#n`, con enlace y estado de cada una) más "Bloquea" (calculado).
  - **Historial**: eventos de `Story#history` en lenguaje natural ("Pasa a Lista", "claude edita el cuerpo"), con actor y fecha relativa en mono.
- [ ] Si se pasa a Lista con preguntas abiertas en el cuerpo, o con `labels` que incluyen `ui` y sin mockup, se muestra un aviso. El aviso no bloquea.
- [ ] Comentarios debajo del cuerpo: lista con actor y fecha, y un campo para añadir uno como Fran.
- [ ] Coincide con `5.4` y `5.6`. La miga de pan termina en la referencia `PG-49`. Al editar, el título pasa a input, el cuerpo tiene pestañas Escribir / Vista previa, y abajo aparecen "Se guarda como fran · queda en el historial", Cancelar y Guardar (primario).
- [ ] `/p/:slug/stories/:number` funciona con el número de la historia.
- [ ] `bin/ci` en verde.

## Fuera de alcance

- Pestaña Ejecución, runs y paradas (artboard `4.5`): M4.
- Miniaturas de los mockups de Paper: con un enlace basta.
- Decisiones ligadas a la historia: se ven en el Brief; aquí, como mucho, un enlace.

## Notas para quien lo construya

- El texto de cada evento sale de su `action` y su `data`. Un helper con un `case` basta.

## Mockups

Paper → `App` → `5.4 Historia · Lista (#49)` (lectura) y `5.6 Historia · Editando (#49)` (edición).

## Preguntas abiertas


## Cierre

Rama `dev/m1-screens`, commit «Añade la página de la Historia».

**Hecho**
- `/p/:slug/stories/:number`:
  - miga de pan `Roadmap / M2 · Publicar sin fricción / PG-49` (o `Bandeja de ideas`) y título;
  - cuerpo markdown pintado (`markdown_controller.js` con `marked` + `dompurify`), con casillas para `- [ ]` / `- [x]` y sin las secciones vacías;
  - comentarios con actor y fecha, y un campo para comentar como Fran (`Story#add_comment!`).
- Columna lateral (`stories/_aside`):
  - **Estado**: el `state_selector` (variante `compact`) envía al cambiar (`Story#move_to!`). Debajo, qué significa: «Siguiente en el roadmap…», la posición en la cola de Listas, bloqueada por…, quién la construye y desde cuándo.
  - **Avisos**: al estar Lista con preguntas abiertas, o con la label `ui` y sin mockup. No bloquean.
  - **Propiedades**: hito con un selector que envía al cambiar (`Story#reorder!` al final del hito o de la bandeja), mockup como enlace, labels, «Bloqueada por» y «Bloquea» con enlace y estado de cada una.
  - **Historial** en lenguaje natural (`StoriesHelper#event_sentence`), con la marca lateral del color del estado al que pasa, actor, fecha (`ayer 22:40`, `9 oct`) y el motivo si lo hay.
- Edición (`/edit`, `5.6`): el título pasa a input y el cuerpo va en un editor con pestañas Escribir / Vista previa (`editor_controller.js`). Abajo, «Se guarda como fran · queda en el historial», Cancelar y Guardar, que llama a `Story#edit!`. Si falla, vuelve con los errores (422).
- Comprobado en Chrome headless:
  - editar título y mockup deja `story.edited` con `["title", "mockup"]` y aparece el aviso de «ui» sin mockup;
  - el selector deja `story.state_changed`;
  - mover a la bandeja deja `story.moved`;
  - comentar deja `comment.added`.

  Capturas contra `5.4` y `5.6`.
- Arreglos de paso:
  - `Story#to_param` devuelve el número. Antes las tarjetas del Tablero y el Roadmap enlazaban por `id`.
  - `config.time_zone = "Madrid"`, para que «ayer 22:40» sea hora de aquí.
  - `y_sentence` evita el «and» de `to_sentence`.

**Decisiones**
- El markdown se pinta en el navegador con lo que ya había en el importmap, sin gemas nuevas. Es genérico: cada `##` es una etiqueta de sección. En `5.4` la Historia sale como entradilla y Contexto no aparece; aquí salen todas las secciones con contenido.
- Al editar, las propiedades de la columna (mockup, labels, «Bloqueada por») pasan a ser campos y se guardan con el mismo Guardar. Paper no lo dibuja, pero la historia pide poder enlazar el mockup y marcar dependencias. El estado no se puede cambiar mientras se edita, porque son formularios distintos.
- El enlace del mockup dice «Paper» (o el dominio): la URL no lleva el nombre del artboard («Paper · Plantillas» en el mockup).
