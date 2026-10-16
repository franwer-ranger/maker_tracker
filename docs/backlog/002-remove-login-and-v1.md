---
number: 2
title: Quitar el login y la v1
milestone: M1
state: done
claimed_by: development
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

Rama `dev/remove-login`, commit «Quita el login y la v1».

**Hecho**
- Fuera Devise (gema, inicializador, locale, rutas, vistas, layout `devise`, `configure_permitted_parameters`) y `letter_opener_web` (gema, ruta y `delivery_method` de development), porque nada más envía emails. `ApplicationMailer` y los layouts de mailer se quedan: son los de serie de Rails.
- Fuera la v1: modelos, controladores (`home` incluido), helpers, vistas, jbuilders, layout `project`, controladores Stimulus (`backlog`, `icebox`, `iteration`, `override`, `items`, `items/description` y `sortable`), imágenes `*_empty.svg` y el CSS que solo usaba ella (`app-scroll-container` y el `text-gray-800` en inputs).
- Migración `DropV1Tables`: borra `comments`, `items`, `sprints`, `users` y `projects` (es irreversible). Después de `bin/setup --reset` solo quedan `schema_migrations` y `ar_internal_metadata`.
- `/` es `HomeController#show`: nombre, texto de "en construcción" y, en development, un botón a `/design`. `/`, `/design` y `/up` responden 200; las rutas antiguas, 404.
- `db/seeds.rb` no crea nada. `AGENTS.md` ya no habla de Devise, del usuario de desarrollo ni de letter_opener.

**Decisiones**
- Se quedan los pins de `marked` y `dompurify`, aunque los usaba `items/description`: la v2 pinta markdown en todas partes. Se quedan también `sortablejs` (lo pide la historia), `positioning` y `jbuilder` (la API de M2).
- La migración usa `if_exists: true`, así que también funciona en una base de datos a medias.
