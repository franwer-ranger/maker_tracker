---
number: 9
title: Roadmap · hitos e historias en orden
milestone: M1
state: done
claimed_by: development
mockup: https://app.paper.design/file/01M50CA4S5CN4Z8ERVW36XWDHF/p-C-0
labels: [ui]
blocked_by: [7]
---

## Contexto

El roadmap es la estructura: hitos ordenados y, dentro de cada uno, historias ordenadas. El orden es la prioridad, y es lo que un agente usa para decidir qué es lo siguiente. Aquí se decide el orden entre hitos, cosa que el Tablero no enseña.

## Historia

Como Fran, quiero ver y ordenar los hitos y sus historias en una sola lista, para decidir qué se construye primero.

## Criterios de aceptación

- [ ] Lista de hitos en orden: `M1`… en mono, título, objetivo y resumen a la derecha. Hecho: `Hecho · 9/9 · 12 sep`. En curso: `En curso · 4/10`. También `6 historias · 4 definiendo` y `Solo idea`.
- [ ] Los hitos cerrados aparecen plegados. El primer hito abierto aparece desplegado con sus historias en orden: estado, `#n`, título y metadatos a la derecha (actor si está en curso, "Siguiente", "bloqueada", "faltan criterios" si el cuerpo no tiene ningún `- [ ]`). Las Hechas se agrupan en una fila que se puede desplegar.
- [ ] Cualquier hito se puede desplegar o plegar.
- [ ] Arrastrar hitos los reordena (`Milestone#reorder!`). Arrastrar una historia la reordena dentro de su hito o la lleva a otro hito o a la bandeja (`Story#reorder!`). El motivo es opcional: tras soltar aparece un campo para escribirlo, que se puede ignorar.
- [ ] "Nuevo hito" (título y objetivo) y cerrar o reabrir un hito.
- [ ] Coincide con `5.3`. El hito abierto va sobre `surface-sunken` con borde `border-strong`; los plegados, solo con borde; la bandeja, con borde discontinuo.
- [ ] La bandeja de ideas aparece al final, con su contador y "+ Nueva idea".
- [ ] `bin/ci` en verde.

## Fuera de alcance

- "Como lo ve el agente" (el roadmap en markdown, artboard `4.3`): llega con `mt roadmap` en M2.

## Notas para quien lo construya

- La misma operación de dominio que el Tablero: no dupliques lógica de orden.

## Mockups

Paper → `App` → `5.3 Roadmap`.

## Preguntas abiertas


## Cierre

Rama `dev/m1-screens`, commit «Añade el Roadmap».

**Hecho**
- `/p/:slug/roadmap`, como en `5.3`:
  - los hitos en orden con su código, título y resumen (`Hecho · 9/9 · 12 sep`, `En curso · 4/12`, `6 historias · 4 definiendo`, `Solo ideas · 3`);
  - el primer hito abierto aparece desplegado sobre `surface-sunken` con borde `border-strong`, y los demás plegados, solo con borde. Cualquiera se puede desplegar o plegar (`<details>`);
  - filas de historia con columnas fijas (estado 104 · `#n` 40 · título · metadato, el mismo que en el Tablero);
  - las Hechas, agrupadas en una fila «#41 #42 #43 #47 · mostrar» que se despliega;
  - la bandeja al final, con borde discontinuo, su contador y «+ Nueva idea».
- Arrastrar (`roadmap_controller.js`): hitos por su asa (`Milestone#reorder!`) e historias dentro del hito, a otro hito o a la bandeja (`Story#reorder!`). Al soltar aparece una barra con el motivo opcional, «Deshacer» y «Guardar orden». El cambio se guarda al confirmarlo (Enter o el botón), porque el motivo va en el evento y los eventos no se editan después.
- «Nuevo hito» (título y objetivo) en un panel bajo el botón, con `Project#create_milestone!`. «Cerrar hito» / «Reabrir hito» al pie del hito desplegado, con `Milestone#close!` / `#reopen!`.
- Endpoints: `PATCH …/milestones/:id/position` ({before|after: id}), `POST|DELETE …/milestones/:id/closure` y `PATCH …/stories/:n/position`, que ahora acepta una vecina de otro hito o `{milestone: id | "ideas"}` para un hito vacío.
- Comprobado con arrastres reales por CDP: reordenar #53 en M2 con motivo («Lo pide la beta» en `story.reordered`), llevar #52 a la bandeja (`story.moved`), subir Equipos sobre Analítica (`milestone.reordered`, con motivo) y reordenar #50. Por HTTP: crear un hito, cerrarlo y reabrirlo. Captura contra `5.3`.

**Decisiones**
- Las listas de historias que viven dentro de un hito interfieren con el arrastre del hito (Sortable anidado). Se desmontan al pulsar el asa (`pointerdown`, antes de que empiece el arrastre) y se vuelven a montar al soltar. Desmontarlas más tarde cancela el arrastre.
- Un cambio pendiente cada vez: si se suelta otro sin guardar el anterior, se descarta todo y se recarga.
- Paper no dibuja dónde se cierra o reabre un hito. Lo he puesto como botón fantasma pequeño al pie del hito desplegado (en el inbox).
- Las fechas cortas (`12 sep`, `hoy`, `ayer 22:40`) salen de `ApplicationHelper#short_date` / `#relative_day`, sin I18n.
