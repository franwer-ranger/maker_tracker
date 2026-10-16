---
number: 2
title: Quitar el login y la v1
milestone: M1
state: ready
claimed_by:
mockup:
labels: [limpieza]
blocked_by: [1]
---

## Contexto

La v1 es un kanban estilo Pivotal Tracker (proyectos, sprints, items, comentarios) con login por Devise. La v2 lo sustituye entero (`docs/ARCHITECTURE.md`) y no hay datos reales que conservar. Fran decidió el 2026-10-16 quitar el login lo primero: la app solo será accesible por red local o Tailscale, y sin login los agentes de desarrollo pueden probar su trabajo directamente en el navegador.

## Historia

Como agente que construye Maker Tracker, quiero que la app arranque sin login y sin el código de la v1, para construir la v2 sobre una base limpia y poder probarla sin autenticarme.

## Criterios de aceptación

- [ ] La gema `devise` ya no está en el `Gemfile`, ni su inicializador, rutas, vistas (`app/views/devise/`), layout `devise` ni `configure_permitted_parameters` en `ApplicationController`.
- [ ] Desaparece el código de la v1: modelos `User`, `Project` (y `Project::Backlog`), `Sprint`, `Item` (e `Item::State`) y `Comment`; sus controladores, vistas, helpers, jbuilders, rutas y controladores Stimulus (`backlog`, `icebox`, `iteration`, `override`, `items`, `items/description`). También las imágenes que solo usaba el kanban (`*_empty.svg`).
- [ ] Una migración borra las tablas `comments`, `items`, `sprints`, `users` y `projects`. `bin/setup --reset` deja una base de datos sin ellas.
- [ ] `/` muestra una página mínima con el sistema de diseño de la #001: el nombre "Maker Tracker" y un texto de que la v2 está en construcción. En development enlaza a `/design`.
- [ ] Ninguna página pide login. `/design` y `/up` siguen funcionando.
- [ ] `db/seeds.rb` no crea nada (lo rehará la #006) y sigue siendo idempotente.
- [ ] `AGENTS.md` ya no menciona el usuario de desarrollo (`fran@gmail.com`) ni Devise.
- [ ] `bin/ci` en verde.

## Fuera de alcance

- Crear el modelo v2: es la #003.
- Arreglar los bugs de la v1: se borran con ella.
- Autenticación de agentes por token: llega en M2.

## Notas para quien lo construya

- Parte de la rama de la #001 ya mergeada: el layout nuevo, los componentes y `/design` vienen de ahí. Si `app/views/layouts/project.html.erb` solo lo usaba la v1, se borra.
- `letter_opener_web` solo existía para ver los emails de Devise. Si nada más envía emails, quítalo también (gema, ruta y línea de `AGENTS.md`).
- `sortablejs` (importmap) se usará para arrastrar en el Tablero y el Roadmap: borra el controlador `sortable_controller.js` si solo servía a la v1, pero deja el pin.
- Si `positioning` se queda sin usos, déjalo en el `Gemfile`: la #003 lo usa.
- Las migraciones antiguas se quedan; la nueva solo borra tablas. No reescribas el historial de migraciones.

## Preguntas abiertas

## Cierre
