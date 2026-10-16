---
number: 8
title: Tablero por estados
milestone: M1
state: defining
claimed_by:
mockup:
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
- [ ] Los cambios se ven sin recargar (Turbo). Si un agente cambia algo, aparece al refrescar; en tiempo real no hace falta en M1.
- [ ] `bin/ci` en verde.

## Fuera de alcance

- Filtros por label o actor.
- Actualización en vivo por Action Cable.

## Notas para quien lo construya

- `sortablejs` ya está en el importmap.
- Revisa los datos contra las seeds (#006): con M2 filtrado, #49 es Siguiente; #48 y #45 están En curso con `claude` y `codex`.

## Preguntas abiertas

- Mockup v3 pendiente (Producto, tarea 3). No hay artboard v2 del tablero: se diseña nuevo en `v3 · App`.

## Cierre
