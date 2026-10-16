---
number: 7
title: Proyectos y estructura de la app
milestone: M1
state: defining
claimed_by:
mockup:
labels: [ui]
blocked_by: [6]
---

## Contexto

Todas las pantallas de M1 viven dentro de un proyecto, con la barra lateral de los mockups v2: el proyecto arriba, la navegación (Tablero, Roadmap, Brief) y los agentes abajo. Antes hace falta poder llegar a un proyecto, o crearlo.

## Historia

Como Fran, quiero ver mis proyectos, crear uno nuevo y moverme entre sus secciones, para empezar a definir un producto en Maker Tracker.

## Criterios de aceptación

- [ ] `/` lista los proyectos. Si solo hay uno, redirige a su Tablero.
- [ ] "Nuevo proyecto" pide nombre y clave (`PG`). Al crearlo se genera el slug, el brief se rellena con su plantilla, se registra `project.created` y se lleva al Brief del proyecto nuevo.
- [ ] Layout de proyecto con barra lateral:
  - arriba, nombre del proyecto y cambio de proyecto;
  - en medio, la navegación Tablero · Roadmap · Brief, con el item activo;
  - abajo, la sección **Agentes**: cada actor `agent` con su estado. En curso: `claude en #48`, en naranja con halo. Si no, inactivo, con el tiempo desde su último evento.
- [ ] Rutas por slug: `/p/postgram`, `/p/postgram/roadmap`, `/p/postgram/brief`, `/p/postgram/stories/49`. La raíz de un proyecto es el Tablero.
- [ ] Usa los componentes de la #001 (`nav_item`, `actor`…) y los iconos Heroicons.
- [ ] `bin/ci` en verde.

## Fuera de alcance

- Actividad y Stats en la navegación: M3 y M4.
- Editar o archivar proyectos.

## Notas para quien lo construya

- La barra lateral es la de los artboards v2. Ver el mockup v3 cuando exista.

## Preguntas abiertas

- Mockup v3 pendiente (Producto, tarea 3): página `v3 · App`.

## Cierre
