---
number: 7
title: Proyectos y estructura de la app
milestone: M1
state: done
claimed_by: development
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

Rama `dev/m1-screens`, commit «Añade los proyectos y el layout de proyecto».

**Hecho**
- Rutas por slug: `/p/postgram` (Tablero), `/roadmap`, `/brief` y `/stories/49`. Si el slug no existe, 404.
- `/` lista los proyectos o, si solo hay uno, redirige a su Tablero. `/p` lista siempre, para poder crear otro aunque haya uno solo.
- Alta de proyecto: nombre y clave, `Project.create_with_event!` como `Current.actor` y redirección al Brief. Si falla, se vuelve a la lista con los errores bajo cada campo (422). Probado por HTTP: crea `guarderia-de-perros` con la plantilla de brief y su `project.created` de fran.
- `5.0 Proyectos`: cada fila muestra la clave, el hito actual (`M2 · Publicar sin fricción`) y `2 en curso` con el punto naranja, o `sin actividad · 2 d`. La captura coincide con Paper.
- Layout `project` con la barra lateral (`layouts/_sidebar`):
  - arriba, el proyecto con su clave y un menú para cambiar de proyecto o ir a todos;
  - en medio, Tablero · Roadmap · Brief con el item activo;
  - abajo, Agentes: `claude en #48` si tiene una historia En curso en el proyecto; si no, `inactivo · 2 h` desde su último evento.

  Coincide con la barra lateral de `5.1`.
- Componentes nuevos:
  - `ui_menu` y `menu_item`, sacados del menú de `5.2`, con `menu_controller.js` para cerrar al pulsar fuera o con Escape. Están en `/design`.
  - `project_key_badge`, `milestone_label`, `short_time_ago` y `agent_status` (`ProjectsHelper`), y `Milestone#code`, `Project#current_milestone` y `#last_activity_at`.
- `ui_field` admite `surface: :bg` (inputs sobre una superficie hundida, como en el alta) y muestra el primer error del atributo.
- Las pantallas de Tablero, Roadmap, Brief e Historia existen como páginas mínimas hasta sus historias. Se ha borrado la portada provisional de la #002 y el header de la v1 (`app-header`, `app-container`).

**Decisiones**
- El número de un hito (`M2`) es su posición en el roadmap: no se guarda.
- El estado de los agentes es por proyecto (historia En curso o último evento en ese proyecto).
- Paper usa `system-ui` en algunos textos de `5.0` y de la barra lateral. En código todo va en Geist, como manda `DESIGN.md`.
