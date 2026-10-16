---
number: 5
title: Eventos · el registro de los hechos
milestone: M1
state: done
claimed_by: development
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

Rama `dev/v2-model`, commit «Añade los eventos y las operaciones de dominio».

**Hecho**
- Migración `CreateEvents` y modelo `Event`: `readonly?` una vez guardado (`update!` / `destroy!` lanzan `ReadOnlyRecord`), `occurred_at` por defecto ahora y el scope `recent_first`.
- Concern `Eventable` con `record_event!` (es público para que las seeds puedan añadir eventos a mano) y `Eventable::ReasonRequired`.
- Operaciones con su evento, todas en una transacción, en este orden de la tabla: `Project.create_with_event!`, `Project#create_story!`, `Story#edit!` (solo título, cuerpo y propiedades; guarda los nombres de los campos cambiados), `#move_to!`, `#claim!` / `#release!`, `#reorder!` (`story.reordered` o `story.moved`, también a la bandeja con `milestone: nil`), `Project#create_milestone!`, `Milestone#reorder!` / `#close!` / `#reopen!`, `Project#edit_brief!`, `Project#record_decision!` y `Story#add_comment!`. Las de la historia viven en `app/models/story/operations.rb`.
- Reglas: pasar a En curso reclama la historia o falla con `Story::ClaimedByOther` («EV-1 la tiene claude»). Salir de En curso hacia atrás la libera; a Hecha mantiene el dueño. `claim!` y `move_to!` usan `with_lock`. Los agentes tienen que dar motivo al reordenar. Si una operación no cambia nada, no hay evento y devuelve `false`. `Story#history`.
- Comprobado en `bin/rails runner` (en una transacción que se deshace): cada operación de la tabla deja exactamente un evento; los no-cambios no dejan ninguno; dos agentes no cogen la misma historia; reordenar como agente sin motivo falla; los eventos no se pueden modificar.

**Decisiones**
- `move_to!` deja un único evento `story.state_changed` aunque reclame o libere, y lo indica en `data` (`claimed: true` / `released: true`). Así se cumple «un evento por operación» y el historial sigue diciendo quién la cogió.
- `story.released` guarda en `data.from` quién la tenía: la UI puede liberar la historia de otro actor y hace falta saberlo.
- Los eventos de hito no tienen `story`; el hito va en `data.milestone_id`. En `data` se guardan ids, no títulos, porque los títulos cambian.
- `Milestone#close!` / `#reopen!` (de la #003) piden ahora `actor:`.
