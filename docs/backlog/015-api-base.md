---
number: 15
title: API · sobre, errores y autodescripción
milestone: M2
state: ready
claimed_by:
mockup:
labels: [api]
blocked_by: [14]
---

## Contexto

La API es lo que usan el CLI `mt` y, más adelante, el MCP. Está pensada para agentes: cada respuesta dice qué ha pasado en una frase y qué tiene sentido hacer después, y cada error dice cómo arreglarlo. Ver `docs/ARCHITECTURE.md` → Interfaz para agentes. Esta historia monta la base; los endpoints llegan en #016, #017 y #018.

## Historia

Como agente, quiero que todas las respuestas de la API tengan la misma forma y que los errores me digan cómo seguir, para no tener que adivinar.

## Criterios de aceptación

- [ ] Todo vive bajo `/api` y responde JSON. Sin CSRF ni sesión: el actor sale del `Authorization: Bearer <token>` (#014) y queda en `Current.actor`. Se actualiza `token_used_at`.
- [ ] Sin token o con uno inválido: `401` con código `UNAUTHORIZED` y un `hint` que explica cómo conseguir un token.
- [ ] Respuesta correcta, siempre con este sobre:
  ```json
  { "ok": true, "data": {}, "summary": "PG-49 is in progress, claimed by claude", "breadcrumbs": ["mt show PG-49", "mt done PG-49 --commit <sha>"], "warnings": [] }
  ```
  `warnings` solo aparece si hay alguno.
- [ ] **Todo lo que pone la API va en inglés**: `summary`, `message`, `hint`, `warnings` y claves. El contenido (títulos, cuerpos, brief) va tal cual se escribió. Los mensajes de las excepciones de dominio, que están en español para la UI, se traducen al pasar por la API. Ver `docs/CLI.md` → Idioma.
- [ ] Error, siempre con este sobre y su código HTTP:
  ```json
  { "ok": false, "error": { "code": "CLAIMED_BY_OTHER", "message": "PG-49 is claimed by codex since 11:42", "hint": "pick another one with mt next, or ask fran to release it", "retryable": false } }
  ```
  Códigos iniciales: `UNAUTHORIZED`, `NOT_FOUND`, `VALIDATION_FAILED` (con los errores por campo), `CLAIMED_BY_OTHER`, `REASON_REQUIRED`, `NOTHING_READY`, `INTERNAL`. Las excepciones de dominio (`Story::ClaimedByOther`, `Eventable::ReasonRequired`, `ActiveRecord::RecordInvalid`, `RecordNotFound`) se traducen en un solo sitio.
- [ ] Los proyectos se identifican por su clave (`/api/projects/PG/…`) y las historias por su número (`/api/projects/PG/stories/49`). En las respuestas, la referencia es siempre `PG-49`.
- [ ] `GET /api` (sin token) devuelve la versión de la API (`api_version: 1`) y la lista de operaciones: método, ruta, parámetros y para qué sirve. Es la fuente de verdad del CLI y del futuro MCP.
- [ ] `GET /api/projects` lista los proyectos: clave, nombre, hito actual y cuántas historias hay en curso.
- [ ] Todas las escrituras de la API pasan por las operaciones de dominio de la #005 con `actor: Current.actor`, así que cada una deja su evento.
- [ ] `bin/ci` en verde.

## Fuera de alcance

- Paginación: los volúmenes son pequeños.
- Límite de peticiones y CORS.

## Notas para quien lo construya

- Un controlador base (`Api::BaseController`) con la autenticación, el sobre y el `rescue_from`. Un helper tipo `render_ok(data, summary:, breadcrumbs:)` evita repetirlo.
- Los `breadcrumbs` se escriben como comandos de `mt`, no como rutas: es lo que el agente va a ejecutar.

## Preguntas abiertas

## Cierre
