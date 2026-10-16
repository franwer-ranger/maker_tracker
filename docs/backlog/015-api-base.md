---
number: 15
title: API · sobre, errores y autodescripción
milestone: M2
state: done
claimed_by: development
mockup:
labels: [api]
blocked_by: [14]
---

## Contexto

La API es lo que usan el CLI `mt` y, más adelante, el MCP. Está pensada para agentes: cada respuesta dice qué ha pasado en una frase y qué tiene sentido hacer después, y cada error dice cómo arreglarlo. Ver `docs/ARCHITECTURE.md` → Interfaz para agentes. Esta historia monta la base; los endpoints llegan en #016, #017 y #018.

## Historia

Como agente, quiero que todas las respuestas de la API tengan la misma forma y que los errores me digan cómo seguir, para no tener que adivinar.

## Criterios de aceptación

- [x] Todo vive bajo `/api` y responde JSON. Sin CSRF ni sesión: el actor sale del `Authorization: Bearer <token>` (#014) y queda en `Current.actor`. Se actualiza `token_used_at`.
- [x] Sin token o con uno inválido: `401` con código `UNAUTHORIZED` y un `hint` que explica cómo conseguir un token.
- [x] Respuesta correcta, siempre con este sobre:
  ```json
  { "ok": true, "data": {}, "summary": "PG-49 is in progress, claimed by claude", "breadcrumbs": ["mt show PG-49", "mt done PG-49 --commit <sha>"], "warnings": [] }
  ```
  `warnings` solo aparece si hay alguno.
- [ ] **Todo lo que pone la API va en inglés**: `summary`, `message`, `hint`, `warnings` y claves. El contenido (títulos, cuerpos, brief) va tal cual se escribió. Los mensajes de las excepciones de dominio, que están en español para la UI, se traducen al pasar por la API. Ver `docs/CLI.md` → Idioma. **Lo hace la #024** (llegó después de construir esta).
- [x] Error, siempre con este sobre y su código HTTP:
  ```json
  { "ok": false, "error": { "code": "CLAIMED_BY_OTHER", "message": "PG-49 is claimed by codex since 11:42", "hint": "pick another one with mt next, or ask fran to release it", "retryable": false } }
  ```
  Códigos iniciales: `UNAUTHORIZED`, `NOT_FOUND`, `VALIDATION_FAILED` (con los errores por campo), `CLAIMED_BY_OTHER`, `REASON_REQUIRED`, `NOTHING_READY`, `INTERNAL`. Las excepciones de dominio (`Story::ClaimedByOther`, `Eventable::ReasonRequired`, `ActiveRecord::RecordInvalid`, `RecordNotFound`) se traducen en un solo sitio.
- [x] Los proyectos se identifican por su clave (`/api/projects/PG/…`) y las historias por su número (`/api/projects/PG/stories/49`). En las respuestas, la referencia es siempre `PG-49`.
- [x] `GET /api` (sin token) devuelve la versión de la API (`api_version: 1`) y la lista de operaciones: método, ruta, parámetros y para qué sirve. Es la fuente de verdad del CLI y del futuro MCP.
- [x] `GET /api/projects` lista los proyectos: clave, nombre, hito actual y cuántas historias hay en curso.
- [x] Todas las escrituras de la API pasan por las operaciones de dominio de la #005 con `actor: Current.actor`, así que cada una deja su evento.
- [x] `bin/ci` en verde.

## Fuera de alcance

- Paginación: los volúmenes son pequeños.
- Límite de peticiones y CORS.

## Notas para quien lo construya

- Un controlador base (`Api::BaseController`) con la autenticación, el sobre y el `rescue_from`. Un helper tipo `render_ok(data, summary:, breadcrumbs:)` evita repetirlo.
- Los `breadcrumbs` se escriben como comandos de `mt`, no como rutas: es lo que el agente va a ejecutar.

## Preguntas abiertas

## Cierre

Rama `dev/m2-api`, commit «Añade la base de la API».

**Hecho**
- `Api::BaseController` hereda de `ActionController::API` (sin sesión, CSRF ni `allow_browser`). Saca el actor de `Authorization: Bearer`, lo deja en `Current.actor` y marca `token_used_at` (como mucho una escritura por minuto).
- `render_ok(data, summary:, breadcrumbs:, warnings:)` y el sobre de error. `Api::Error` lleva `code`, `message`, `hint`, `retryable` y, en validaciones, `details` con los errores por campo.
- Todas las excepciones se traducen en el `rescue_from` del controlador base: `RecordNotFound` → `NOT_FOUND`, `RecordInvalid` y `ParameterMissing` → `VALIDATION_FAILED`, `Story::ClaimedByOther` → `CLAIMED_BY_OTHER` (409), `Eventable::ReasonRequired` → `REASON_REQUIRED`, cualquier otra → `INTERNAL` (500, `retryable: true`, se registra en el log). `NOTHING_READY` se usa en la #016.
- Proyecto por su clave (`project`) e historia por su número, que admite `49` o `PG-49` (`find_story`).
- `GET /api` (sin token): `api_version: 1` y las operaciones de `Api::Operations::ALL` (método, ruta, parámetros, comando de `mt` y para qué sirve). Cada historia de la API añade las suyas.
- `GET /api/projects`: clave, nombre, hito actual y cuántas en curso, también en `data.markdown`.
- Cualquier otra ruta bajo `/api` da `NOT_FOUND` en el sobre, no la página de error de Rails.

**Decisiones**
- `CLAIMED_BY_OTHER` responde 409 y los errores de validación y de motivo, 422.
- Con `API_RAISE=1` en local, los errores internos se lanzan en lugar de envolverse, para depurar.
