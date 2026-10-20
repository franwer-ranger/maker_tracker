# Maker Tracker · Arquitectura v2

> Propuesta de diseño para la v2. Parte de [`PRODUCT.md`](PRODUCT.md): si algo de aquí lo contradice, manda `PRODUCT.md`. Las secciones marcadas como **propuesta** aún no están decididas; se validan al construir y usar.

## Visión general

```
                   ┌────────────── Maker Tracker (Rails, en la torre) ──────────────┐
  Yo (navegador) ──┤  UI web         ─┐                                             │
                   │                  ├── modelos ── SQLite                         │
  Agentes ─────────┤  API JSON  /api ─┘        ▲                                    │
   (mt CLI, MCP)   │                           │ (solo lee el núcleo)               │
                   │  app/integrations/wflow ──┘  UI de wflow, opcional por proyecto│
                   └────────────────────────────────────────────────────────────────┘
                                ▲  leer historia (GET)   │  eventos (POST)
                                └──────────  wflow  ◄────┘
```

- Una sola app Rails es la fuente de verdad. La UI y la API usan los mismos modelos.
- Acceso solo desde red local o Tailscale. Humanos sin login; agentes con un token cada uno.
- Markdown es el formato nativo de todo lo que es texto (brief, historias, decisiones, descripciones de hitos): es lo que el agente lee y escribe sin traducir nada.

## Modelo de datos

Sustituye al actual (`projects`, `sprints`, `items`, `comments`, `users` con Devise). Desaparecen **sprints, puntos, velocidad y Devise**.

| Entidad | Para qué | Campos principales |
|---|---|---|
| **Project** | Un producto | `name`, `slug`, `key` (clave corta en mayúsculas para citar historias: `MT`), `brief` (md: visión, principios, autonomía de los agentes, fuera de alcance, glosario), `settings` (json: integraciones activas, p. ej. `wflow: true`) |
| **Milestone** (hito) | Un paso del roadmap | `project`, `title`, `goal` (md: objetivo y por qué), `position`, `closed_at` |
| **Story** (historia) | Algo a construir | `project`, `milestone` (nulo = bandeja de ideas), `number` (por proyecto; se cita `MT-45`), `title`, `body` (md con la plantilla de `PRODUCT.md`), `properties` (json: `mockup`, `labels`, `blocked_by`), `state`, `position` (dentro del hito), `claimed_by` (actor), `claimed_at` |
| **Decision** | Qué decidimos y por qué. Solo se añade | `project`, `story` (opcional), `number` (D-13), `title`, `body` (md: por qué), `actor` |
| **Comment** | Conversación en una historia | `story`, `actor`, `body` (md) |
| **Actor** | Quién hace algo: yo o un agente | `name`, `kind` (`human` / `agent`), `token_digest` (solo agentes) |
| **Event** | Registro de actividad. Solo se añade | `project`, `story` (opcional), `actor`, `action`, `data` (json), `reason`, `occurred_at` |
| **Run** | Una ejecución externa de una historia | `story`, `source` (texto libre: `wflow`, `codex`…), `external_id`, `status`, `started_at`, `finished_at`, `cost_usd`, `tokens` |

### Estados de una historia

`idea → defining → ready → in_progress → done` (en la UI: Idea, Definiendo, Lista, En curso, Hecha).

- **Idea / Definiendo**: es mi trabajo, con la IA y Paper.
- **Lista**: tiene contexto suficiente para que un agente la construya sin preguntar. Los agentes de desarrollo solo cogen historias en este estado.
- **En curso**: reclamada por un actor (`claimed_by`). Dos agentes no cogen la misma.
- **Hecha**: con sus commits y PR en el registro.

### Quién escribe qué

- Los agentes escriben **contenido**: `body`, `brief`, `goal`, comentarios, decisiones.
- Maker Tracker es dueño de los **hechos**: cada transición, reclamación, reordenación, commit o PR enlazado genera un `Event` con su actor y fecha. Los eventos no se editan ni se borran, y no hay endpoint que lo permita.
- Los campos derivados (fecha de inicio y fin de una historia, PR actual, coste) se calculan a partir de los eventos y los runs, no los escribe nadie a mano.

### Roadmap como datos (propuesta)

- El roadmap es la estructura: hitos ordenados y, dentro de cada uno, historias ordenadas. El orden es la prioridad.
- El documento markdown del roadmap (lo que devuelve `mt roadmap`) se **genera en vivo** desde esa estructura. No hay un documento aparte que sincronizar.
- Reordenar es la misma operación desde la UI (arrastrar, en el Roadmap o dentro de una columna del Tablero) que desde un agente. A los agentes les pide un **motivo** (en la UI es opcional), que queda en el evento (`milestone.reordered`, `reason`). Si el cambio es importante, se registra además como decisión.

### "Necesita tu atención"

No es una tabla: se deriva al consultar.
- Paradas abiertas de un run (evento `run.stopped` sin `run.resumed` posterior), con sus opciones.
- Historias en Definiendo paradas más de N días o sin criterios.
- Preguntas que un agente deja en un comentario dirigido a mí.
- (Si se decide) propuestas de cambio de producto pendientes de aprobar.

## Interfaz para agentes

Inspirada en las CLIs de 37signals para agentes y en el MCP de Paper.

**API JSON** (`/api/...`, token de agente en `Authorization: Bearer`, creado con `bin/rails "mt:token[claude]"`). Los proyectos se identifican por su clave (`/api/projects/PG/stories/49`). Toda respuesta va en un sobre:

```json
{
  "ok": true,
  "data": { },
  "summary": "Historia #49 reclamada por claude",
  "breadcrumbs": ["mt show 49", "mt done 49 --commit <sha>"]
}
```

- `breadcrumbs`: lo que tiene sentido hacer después, para que el agente no adivine.
- Errores con código tipado, `hint` de cómo arreglarlo y si se puede reintentar.
- **Conflictos de edición** (MT-37, D-43): historias (`stories.version`), hitos (`milestones.version`) y brief (`projects.brief_version`) llevan una versión que sube solo al editar contenido; mover, reordenar y cerrar son acciones atómicas y no la tocan. Quien edita manda la versión que leyó (en el frontmatter de `mt show`, `PATCH`/`PUT` con `version`); si no es la actual, `409 CONFLICT` con `hint` y no se guarda nada (`Versioned`, comprobado dentro de la transacción con el registro bloqueado). Sin versión no se comprueba. Los formularios de la UI hacen lo mismo y, al chocar, enseñan qué cambió sin perder lo escrito. La UI no se bloquea nunca.
- La API se describe a sí misma (`GET /api`: versión y lista de operaciones).
- `warnings`: avisos que no bloquean (pasar a Lista con preguntas abiertas, empezar una historia bloqueada…).
- Lo que lee un agente (contexto, roadmap, una historia) va además en `data.markdown`. Una historia se lee y se escribe en el mismo formato que imprime `mt show`: frontmatter con sus propiedades y el cuerpo debajo.

**Presencia de actores** (MT-36, D-46): la API es petición-respuesta y no hay sesiones ni heartbeats, así que la presencia se deduce de la actividad. Cada petición autenticada marca al actor en `Presence` (proyecto, historia o entidad de la ruta, y «leyendo» si es GET o «escribiendo» si no; al hacerse la escritura, `Event` completa qué ha cambiado). Solo cuentan las respuestas 2xx (un 404 o un 422 no dejan presencia). Un actor está activo 60 s desde su última petición y deja de estarlo solo: un barrido cada 5 s retira a quien caduca y lo emite. Las emisiones son en diferido y agrupadas, y un fallo al emitir se reporta sin romper la petición. Es estado efímero en memoria del proceso: no es una tabla, no escribe en SQLite al leer y no genera eventos. Con varios workers de Puma habría que moverlo a una caché compartida. En directo, por Turbo Streams: `[project, :presence]` y `:presence` (portada) reciben el reemplazo de `#presence` en cada cambio de presencia; `[project, :writes]` y `:writes` reciben un `append` a `#writes` por cada evento creado. La UI que lo enseña es MT-38.

**CLI `mt`**: binario en Go, en `cli/` de este repo. En el Mac, habla con la torre por Tailscale. Configuración en `~/.config/mt/config` (`mt setup <url> <token>`) y proyecto por repo en `.mt` (`mt init PG`). Imprime texto legible por defecto, también dentro de un agente; `--json` da el sobre. El formato de cada salida, con ejemplos, está en [`CLI.md`](CLI.md). Historias en [`backlog/`](backlog/) #014–#020. Los principales:

| Comando | Qué hace |
|---|---|
| `mt context` | Brief, últimas decisiones, hito actual y lo que está en curso, en markdown compacto. Es el onboarding del agente |
| `mt next` | Primera historia **Lista** y no bloqueada (`blocked_by` sin terminar) del primer hito abierto, entera y con el motivo de que sea esa |
| `mt roadmap` | El roadmap en markdown, generado en vivo |
| `mt show <n>` | Una historia completa en markdown |
| `mt start <n>` | Reclama la historia y la pasa a En curso |
| `mt done <n> --commit <sha>` | La cierra enlazando commits o PR |
| `mt comment <n> "…"` | Comenta en la historia |
| `mt decide "…" --why "…"` | Registra una decisión |
| `mt create` · `mt edit` · `mt move` · `mt reorder` · `mt brief` | Escriben producto (crear y editar historias con `--file`, cambiar estado, ordenar con motivo, editar el brief) |

**Skill + hook SessionStart**: la skill enseña al agente a usar `mt` y el hook inyecta `mt context` al empezar cada sesión, así cada conversación arranca sabiendo la filosofía del proyecto. `mt init PG --claude` los deja en el repo del proyecto.

**MCP**: al final, fino, como envoltorio de la misma API. Pocas herramientas, una por dominio (`mt_stories`, `mt_roadmap`…), con varias acciones cada una. Modo solo lectura disponible. Sirve para Claude Desktop o el móvil.

## Contrato con herramientas de ejecución

Genérico: lo usa wflow, pero no menciona wflow. Cualquier herramienta con un token de agente puede usarlo.

**1. Leer una historia**: `GET /api/projects/:key/stories/:number` → markdown (o JSON con `body` en markdown): título, qué, por qué, criterios, enlaces a Paper y decisiones relacionadas.

**2. Reportar eventos**: `POST /api/projects/:key/stories/:number/runs/:external_id/events`

```json
{
  "source": "wflow",
  "type": "run.stopped",
  "phase": "open-pr",
  "data": {
    "code": "EXTERNAL_REVIEW_REQUIRED",
    "summary": "PR #61 abierta, esperando revisión",
    "options": [
      { "label": "Merge", "command": "wflow merge 45" },
      { "label": "Ver PR", "url": "https://github.com/…/pull/61" }
    ]
  }
}
```

- Tipos del núcleo (los únicos que el núcleo interpreta): `run.started`, `run.phase_started`, `run.phase_finished`, `run.stopped`, `run.resumed`, `run.commit`, `run.pr_opened`, `run.finished`.
- `phase`, `runner`, `model` y el resto de `data` son **texto libre**: el núcleo los guarda y como mucho los muestra tal cual.
- Coste y tokens van en `data` (`cost_usd`, `tokens`, `estimated: true` si es una estimación); el núcleo los acumula en `Run`.
- `run.stopped` / `run.resumed` permiten medir el **tiempo esperando por mí**.
- Idempotente: cada evento lleva un `id` del emisor, y reenviarlo no lo duplica.

**Paradas**: las opciones llevan `command` o `url`. La UI muestra el comando para copiarlo. Maker Tracker nunca ejecuta nada (ver decisión en `PRODUCT.md`).

## Módulo de wflow

Todo lo específico de wflow vive en `app/integrations/wflow/` (namespace `Wflow::`, autocargado por Rails):

- La pestaña **Ejecución** de una historia: el ticket fase a fase con runner, modelo, esfuerzo, tiempo, coste y notas.
- Las **tarjetas de parada** con sus opciones, interpretando los códigos de wflow (`EXTERNAL_REVIEW_REQUIRED`, decisión humana…).
- En **Stats**, el desglose por fase y por runner/modelo.

Reglas:
1. **Dependencia en un solo sentido**: el módulo usa el núcleo (`Event`, `Run`, `Story`); el núcleo nunca referencia `Wflow::`. Los puntos donde la UI del núcleo deja hueco (una pestaña extra, una sección en Stats) se resuelven comprobando si la integración está activa en `project.settings`.
2. **Los datos siguen siendo genéricos**: el módulo solo interpreta y presenta eventos que ya están guardados. Desactivarlo o borrarlo no pierde nada.
3. Sin el módulo, la historia muestra igualmente sus runs y eventos en una vista genérica sencilla.
