---
number: 9
title: Roadmap · hitos e historias en orden
milestone: M1
state: ready
claimed_by:
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
