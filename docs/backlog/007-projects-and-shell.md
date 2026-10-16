---
number: 7
title: Proyectos y estructura de la app
milestone: M1
state: ready
claimed_by:
mockup: https://app.paper.design/file/01M50CA4S5CN4Z8ERVW36XWDHF/p-C-0
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
- [ ] Coincide con `5.0 Proyectos` y la barra lateral de `5.1`: cada proyecto muestra su clave, su hito actual y cuántas historias tiene en curso (o el tiempo sin actividad). El botón del alta dice "Crear y escribir el brief".
- [ ] `bin/ci` en verde.

## Fuera de alcance

- Actividad y Stats en la navegación: M3 y M4.
- Editar o archivar proyectos.

## Notas para quien lo construya

- La barra lateral es igual en todas las pantallas de proyecto: hazla un partial del layout.

## Mockups

Paper → `App` → `5.0 Proyectos` (lista y alta) y la barra lateral de cualquier pantalla de proyecto (p. ej. `5.1 Tablero · M2`).

## Preguntas abiertas


## Cierre
