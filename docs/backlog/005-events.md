---
number: 5
title: Eventos · el registro de los hechos
milestone: M1
state: ready
claimed_by:
mockup:
labels: [modelo]
blocked_by: [3, 4]
---

## Contexto

Principio de `PRODUCT.md`: los agentes escriben contenido y Maker Tracker es dueño de los **hechos**. Cada transición, reclamación, reordenación o alta genera un `Event` con su actor y fecha, que no se edita ni se borra. De ese registro saldrán el historial de una historia (M1), la pantalla Actividad (M3) y las fechas derivadas. Ver `docs/ARCHITECTURE.md` → "Quién escribe qué" y "Roadmap como datos".

## Historia

Como Fran, quiero que cada cambio de estado, reclamación y reordenación quede registrado con quién lo hizo y cuándo, para fiarme de lo que veo sin que un agente pueda reescribirlo.

## Criterios de aceptación

**Event**
- [ ] Campos: `project`, `story` (opcional), `actor`, `action` (texto), `data` (json), `reason` (texto opcional) y `occurred_at`.
- [ ] Solo se añaden: `readonly?` una vez persistido, sin `update` ni `destroy` (lanzan error).

**Operaciones de dominio.** Son métodos explícitos que reciben `actor:` (y `reason:` donde aplique). Cada uno hace el cambio y su evento en la misma transacción. La UI de M1 y la API de M2 usarán estos mismos métodos.

| Método | Evento (`action`) | `data` |
|---|---|---|
| `Project.create_with_event` o equivalente al crear proyecto | `project.created` | — |
| crear historia | `story.created` | `state`, `milestone` |
| `Story#edit!(attrs, actor:)` (título, cuerpo, propiedades) | `story.edited` | nombres de los campos cambiados (no el contenido) |
| `Story#move_to!(state, actor:)` | `story.state_changed` | `from`, `to` |
| `Story#claim!(actor:)` / `Story#release!(actor:)` | `story.claimed` / `story.released` | — |
| `Story#reorder!(position:, milestone:, actor:, reason:)` | `story.reordered` (mismo hito) o `story.moved` (otro hito o la bandeja) | `from`, `to` (hito y posición) |
| crear / `Milestone#reorder!` / `close!` / `reopen!` | `milestone.created` / `milestone.reordered` / `milestone.closed` / `milestone.reopened` | según el caso |
| `Project#edit_brief!(text, actor:)` | `brief.edited` | — |
| añadir decisión / comentario | `decision.recorded` / `comment.added` | `number` de la decisión |

**Reglas**
- [ ] Pasar a `in_progress` reclama la historia para el actor si no tiene dueño (`claimed_by`, `claimed_at`). Si ya la tiene **otro actor**, falla con un error que dice quién la tiene. Dos actores no cogen la misma.
- [ ] Salir de `in_progress` hacia un estado anterior (`idea`, `defining`, `ready`) la libera. Pasar a `done` mantiene `claimed_by`.
- [ ] Cualquier otro salto entre estados está permitido. En M1 no hay validaciones para pasar a Lista.
- [ ] Reordenar exige `reason` no vacío si el actor es `agent`. Para `human` es opcional. El motivo queda en `Event#reason`.
- [ ] Cambiar un valor por el mismo (mover al mismo estado o a la misma posición) no genera evento.
- [ ] `Story#history` devuelve sus eventos, del más reciente al más antiguo.
- [ ] En `bin/rails runner`: un agente reclama una historia y otro no puede; reordenar como agente sin motivo falla; cada operación de la tabla deja exactamente un evento.
- [ ] `bin/ci` en verde.

## Fuera de alcance

- Eventos de runs (`run.started`, `run.stopped`…) y el endpoint para recibirlos: M4.
- Pantalla Actividad: M3. El historial dentro de la Historia es la #010.
- Fechas derivadas (inicio y fin de una historia): se calcularán desde los eventos cuando una pantalla las necesite.

## Notas para quien lo construya

- No uses callbacks de ActiveRecord para generar eventos. Con métodos explícitos se sabe quién y por qué, y las seeds pueden crear datos sin ruido.
- Un concern pequeño (`Eventable`, `record_event!`) evita repetir la creación del evento.
- `action` es texto libre a propósito: en M4 llegarán acciones de herramientas externas que el núcleo no interpreta.

## Preguntas abiertas

## Cierre
