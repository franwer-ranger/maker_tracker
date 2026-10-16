---
number: 3
title: Modelo v2 · proyectos, hitos e historias
milestone: M1
state: ready
claimed_by:
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
