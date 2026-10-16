---
number: 3
title: Modelo v2 · proyectos, hitos e historias
milestone: M1
state: done
claimed_by: development
mockup:
labels: [modelo]
blocked_by: [2]
---

## Contexto

Con la v1 fuera (#002), toca crear el núcleo del modelo v2: un proyecto tiene hitos ordenados, y cada hito tiene historias ordenadas. El orden es la prioridad. Modelo completo en `docs/ARCHITECTURE.md`; la forma de una historia (propiedades arriba, markdown abajo), en `docs/PRODUCT.md` → Decisiones → 2026-10-16.

## Historia

Como Fran y como agente, quiero proyectos con hitos e historias ordenados, para que el roadmap sea datos y no un documento aparte.

## Criterios de aceptación

**Project**
- [ ] Campos: `name`, `slug` (único, generado desde el nombre), `key` (único, 2–5 letras en mayúsculas, p. ej. `PG`), `brief` (texto markdown) y `settings` (json, por defecto `{}`).
- [ ] Al crear un proyecto, `brief` se rellena con la plantilla: `## Visión`, `## Principios`, `## Fuera de alcance` y `## Glosario`.
- [ ] Las URLs usan el `slug` (`to_param`).

**Milestone**
- [ ] Campos: `project`, `title`, `goal` (markdown), `position` y `closed_at`.
- [ ] Ordenados por `position` dentro del proyecto (gema `positioning`). `open` y `closed` como scopes. `close!` y `reopen!`.

**Story**
- [ ] Campos: `project`, `milestone` (opcional: sin hito = bandeja de ideas), `number`, `title`, `body` (markdown), `properties` (json, por defecto `{}`), `state`, `position`, `claimed_by` (referencia a `Actor`, opcional; la tabla `actors` llega en la #004, así que aquí la columna y la asociación quedan preparadas) y `claimed_at`.
- [ ] `number` es correlativo por proyecto, se asigna al crear, nunca se reutiliza y es único por proyecto (índice). `Story#reference` devuelve `PG-48`.
- [ ] `state` es un enum de texto: `idea`, `defining`, `ready`, `in_progress`, `done`. Por defecto `idea`. `Story.human_state` (o una traducción en `es.yml`) da Idea, Definiendo, Lista, En curso y Hecha.
- [ ] Ordenadas por `position` dentro de `[project, milestone]`. La bandeja de ideas (`milestone: nil`) tiene su propio orden.
- [ ] Al crear una historia sin `body`, se rellena con la plantilla de `PRODUCT.md`: `## Contexto`, `## Historia`, `## Criterios de aceptación`, `## Fuera de alcance`, `## Notas para quien lo construya` y `## Preguntas abiertas`.
- [ ] `properties` tiene tres claves conocidas, accesibles como atributos (`store_accessor`):
  - `mockup`: vacío o una URL `http(s)`.
  - `labels`: lista de textos, sin espacios sobrantes ni repetidos.
  - `blocked_by`: lista de números de historias **del mismo proyecto**, distintos del suyo.

  Lo que no cumpla esas reglas da un error de validación legible.
- [ ] `Story#blocked?` es verdadero si alguna historia de `blocked_by` no está `done`. `Story#blocking` devuelve las historias que la tienen en su `blocked_by`.
- [ ] `Project#next_story`: primera historia `ready` y no bloqueada del primer hito abierto, recorriendo los hitos en orden. Es la regla de `mt next`, y la UI la marcará como "Siguiente".
- [ ] En `bin/rails runner` se puede crear un proyecto con dos hitos y varias historias, y comprobar que el orden, la numeración, `blocked?` y `next_story` se comportan como arriba.
- [ ] `bin/ci` en verde.

## Fuera de alcance

- Actores, decisiones y comentarios: #004. Eventos y las operaciones que los generan (cambiar estado, reclamar, reordenar): #005.
- Borrar historias o hitos: en M1 no hay borrado. Si sobra algo, se deja en la bandeja de ideas.
- UI: de la #007 en adelante.

## Notas para quien lo construya

- SQLite: `t.json :properties, default: {}` funciona. Valida en el modelo, no con restricciones de BD.
- No pongas aquí la lógica de cambiar de estado o reclamar: en la #005 serán métodos explícitos que registran su evento. Aquí el estado es solo un atributo con su enum.
- La numeración tiene que ser segura ante dos creaciones casi a la vez: dentro de una transacción con el índice único, reintentando si choca, es suficiente.
- Nombres de tablas y columnas en inglés, como en `ARCHITECTURE.md`.

## Preguntas abiertas

## Cierre

Rama `dev/v2-model` (sale de `dev/remove-login`), commit «Añade el modelo v2: proyectos, hitos e historias».

**Hecho**
- Migración `CreateV2Core` con `projects`, `milestones` y `stories`. Índices únicos `[project_id, number]`, `[project_id, position]` en hitos y `[project_id, milestone_id, position]` en historias.
- `Project`: `slug` generado desde el nombre al crear (`prueba-uno`, `prueba-uno-2`…) y usado en `to_param`. `key` en mayúsculas y validada (2–5 letras). `brief` con la plantilla. `ideas` y `next_story`.
- `Milestone`: `positioned on: :project`, scopes `open` / `closed`, `close!` / `reopen!`.
- `Story`: enum de texto con `Story.human_state` / `#human_state` (Idea…Hecha; `ComponentsHelper::STATES` usa ya `Story::STATE_NAMES`). `positioned on: [project, milestone]` (la bandeja tiene su propio orden). `body` con la plantilla. `reference` (`PG-48`). `mockup`, `labels` y `blocked_by` con `store_accessor`: aceptan lista o texto separado por comas, se normalizan y se validan con mensajes legibles. `blocked?` y `blocking`.
- Comprobado con un script en `bin/rails runner` (en una transacción que se deshace): orden y reordenación, paso a otro hito, numeración por proyecto, número fijado (#48 → la siguiente es #49), `blocked?`, `blocking`, `next_story` saltando historias bloqueadas e hitos sin Listas, y cada validación.

**Decisiones**
- Los números no se reutilizan gracias a un contador en el proyecto (`last_story_number`), no a `maximum + 1`. Se reserva dentro de `with_lock`, así que dos creaciones a la vez no chocan y no hace falta reintentar. Se puede fijar un número (las seeds lo necesitan), y el contador salta a él.
- `next_story` recorre los hitos abiertos en orden: si el primero no tiene ninguna Lista desbloqueada, pasa al siguiente.
- `claimed_by_id` existe sin clave ajena; la #004 la añade al crear `actors`.
- `blocking` usa `json_each` de SQLite para no cargar todas las historias.
