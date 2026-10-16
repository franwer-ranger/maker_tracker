---
number: 8
title: Tablero por estados
milestone: M1
state: done
claimed_by: development
mockup: https://app.paper.design/file/01M50CA4S5CN4Z8ERVW36XWDHF/p-C-0
labels: [ui]
blocked_by: [7]
---

## Contexto

Fran quiere una vista de columnas para ver de un vistazo qué está hecho, qué está en curso y qué está listo; le resulta más visual que una sola lista. Es la portada del proyecto. El Roadmap (#009) sigue siendo donde se decide el orden entre hitos. Decisión en `docs/PRODUCT.md` → 2026-10-16.

## Historia

Como Fran, quiero ver las historias de un hito en columnas por estado y moverlas arrastrando, para saber qué está pasando y empujar el trabajo sin abrir cada historia.

## Criterios de aceptación

- [ ] Cinco columnas: Idea · Definiendo · Lista · En curso · Hecha, cada una con su punto de estado y su contador.
- [ ] Filtro de hito arriba. Por defecto, el primer hito abierto. Opciones: cada hito, "Bandeja de ideas" y "Todos".
- [ ] Dentro de cada columna, el orden es el del roadmap (posición en el hito; con "Todos", primero el orden de los hitos).
- [ ] Cada tarjeta muestra: `#49` en mono, título, `labels`, el actor si está En curso (`claude`), una marca si está bloqueada (con las historias que la bloquean) y **Siguiente** en la historia que devuelve `Project#next_story`.
- [ ] Arrastrar una tarjeta a otra columna llama a `Story#move_to!` como `Current.actor`. Llevarla a En curso la reclama para Fran. Si la tiene otro actor, se muestra el error y la tarjeta vuelve a su sitio.
- [ ] Arrastrar arriba o abajo dentro de una columna llama a `Story#reorder!` dentro de su hito, sin pedir motivo. Con el filtro "Todos" solo se puede cambiar de columna, no reordenar.
- [ ] Con "Todos", Hecha muestra las 10 más recientes y un enlace "ver todas".
- [ ] "+ Nueva idea" en la columna Idea crea una historia con solo el título, en el hito filtrado (o en la bandeja), y genera `story.created`.
- [ ] Al pulsar una tarjeta se abre la Historia (#010).
- [ ] Coincide con `5.1` y `5.2`. El selector muestra los hitos abiertos con su progreso (`4/12`), los cerrados atenuados con "cerrado", y después la Bandeja de ideas y "Todos los hitos · sin reordenar". La cabecera muestra el hito filtrado en Instrument Serif, con su objetivo y su progreso.
- [ ] Los cambios se ven sin recargar (Turbo). Si un agente cambia algo, aparece al refrescar; en tiempo real no hace falta en M1.
- [ ] `bin/ci` en verde.

## Fuera de alcance

- Filtros por label o actor.
- Actualización en vivo por Action Cable.

## Notas para quien lo construya

- `sortablejs` ya está en el importmap.
- Revisa los datos contra las seeds (#006): con M2 filtrado, #49 es Siguiente; #48 y #45 están En curso con `claude` y `codex`.

## Mockups

Paper → `App` → `5.1 Tablero · M2` y `5.2 Tablero · Selector de hito`.

## Preguntas abiertas


## Cierre

Rama `dev/m1-screens`, commit «Añade el Tablero».

**Hecho**
- `/p/:slug` muestra el Tablero: cinco columnas con punto, nombre y contador, y la cabecera del hito (`M2 · En curso · 4/12 hechas`, título en Instrument Serif y objetivo).
- Filtro en `?hito=`: el número del hito, `ideas` o `todos`. Por defecto, el primer hito abierto. El selector (`5.2`) usa el `ui_menu` de la #007 y muestra los hitos abiertos con su progreso, los cerrados atenuados con «cerrado», la Bandeja de ideas y «Todos los hitos · sin reordenar».
- Tarjeta: `#n`, título, labels y un solo metadato, por este orden de prioridad: actor si está En curso, «Siguiente» (`Project#next_story`), «tras #45» con candado si está bloqueada, «faltan criterios» si está en Definiendo sin `- [ ]`, o «mockup». Las Hechas, sin fondo y con el título atenuado. Al pulsar una tarjeta se abre la Historia.
- Arrastrar (`board_controller.js` con `sortablejs`):
  - a otra columna llama a `Story#move_to!` (`PATCH …/stories/:n/state`);
  - dentro de la columna, a `Story#reorder!` junto a la vecina (`PATCH …/stories/:n/position`, `{before|after: n}`), sin motivo;
  - si falla, la tarjeta vuelve a su sitio y se ve el error (`PG-48 la tiene claude`);
  - si va bien, se refresca con Turbo (morph).

  Con «Todos» solo se cambia de columna (`sort: false`), y Hecha muestra las 10 más recientes con «ver todas (n)».
- «Nueva idea» abre un campo en la columna Idea y crea la historia en el hito filtrado o en la bandeja (`Project#create_story!`, `story.created`).
- Componentes nuevos: `ui_label`, `next_badge` y `menu_separator`. `menu_item` admite icono y color de metadato, y `state_dot` admite `halo: false` (cabeceras de columna). Modelo: `Story#pending_blockers`, `#missing_criteria?`, `Milestone#progress` y `#status`.
- Comprobado:
  - capturas contra `5.1` y `5.2`;
  - arrastre real con Chrome headless por CDP: #52 a Lista deja `story.state_changed` de fran; #48 (de claude) a En curso se rechaza y vuelve a su sitio; reordenar dentro de Hecha deja `story.reordered`;
  - por HTTP: estado desconocido (422), sin `before`/`after` (400), y crear ideas en el hito y en la bandeja.

**Decisiones**
- El 11px de las labels no es un token. Va como `text-[11px]` solo dentro de `ui_label` (lo dejo en el inbox).
- Los endpoints de arrastre responden 204 o 422 con `{error}`. La página se refresca entera con morph en lugar de devolver streams: es más simple y basta en M1.
