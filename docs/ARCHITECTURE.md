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
| **Question** | Pregunta de un agente en una historia, con opciones y recomendación (MT-29). Bloquea por defecto | `story`, `actor` (quien pregunta), `title`, `context`, `options` (json), `recommended`, `reversible` (nulo = sin indicar), `blocking` (por defecto sí), `answer`, `answer_note`, `answered_by`, `answered_at`. Una respuesta libre (MT-30) no tiene `answer`: su texto es `answer_note` |
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
- Preguntar y responder también son hechos: `question.asked` y `question.answered` (con actor y fecha; el segundo guarda la opción (o el texto, si fue libre) y, con `--decide`, el `D-n`). Si preguntar suelta la historia, es además un `story.state_changed` con `released`.
- La QA también: `qa.passed` y `qa.failed` (actor, fecha, nota; el segundo guarda el número de la historia que crea). Pasar a Hecha escribe `qa: pending` en el evento `story.state_changed` y en `stories.qa` (`pending | passed | failed`; nulo en las hechas antes de MT-32, que no entran). Al salir de Hecha `qa` vuelve a nulo: lo que pasó con la QA solo queda en los eventos.
- El despliegue también (MT-46): `story.deployed` por historia (`sha`) y `project.deployed` por llamada a `mt deployed` (`sha`, `stories`, los números marcados aunque sea una lista vacía, y `warnings`, los avisos del CLI). La columna `stories.deployed_at` es nula al pasar a Hecha y al salir de ella, como `qa`. La daily y «Qué cambió» cuentan una sola frase por llamada (`Changes` deja fuera `story.deployed` salvo al pedir una historia).

- El coste también (MT-34, D-65): `usage.reported` por sesión, con `data: { source, session_id, models, tokens, cost_usd, estimated: true, unpriced_models, session_total }`. Lo reporta el hook `SessionEnd` de Claude Code (o wflow, con `source: wflow`) a `POST /api/projects/:key/usage`; el servidor calcula los dólares (`ModelPrice`, `config/model_prices.yml`), elige la historia (`Story.usage_target`: la última que ese actor empezó durante la sesión; sin ninguna, no hay evento) y guarda solo la diferencia con el último reporte de la misma sesión (`session_total` es el acumulado). El total de una historia (`Story#usage_total`) es la suma de sus eventos; no hay columna ni tabla `Run` (D-61).
- Los campos derivados (fecha de inicio y fin de una historia, PR actual, coste) se calculan a partir de los eventos y los runs, no los escribe nadie a mano.

### Roadmap como datos (propuesta)

- El roadmap es la estructura: hitos ordenados y, dentro de cada uno, historias ordenadas. El orden es la prioridad.
- El documento markdown del roadmap (lo que devuelve `mt roadmap`) se **genera en vivo** desde esa estructura. No hay un documento aparte que sincronizar.
- Reordenar es la misma operación desde la UI (arrastrar, en el Roadmap o dentro de una columna del Tablero) que desde un agente. A los agentes les pide un **motivo** (en la UI es opcional), que queda en el evento (`milestone.reordered`, `reason`). Si el cambio es importante, se registra además como decisión.

### "Necesita tu atención"

No es una tabla: se deriva al consultar.
- Paradas abiertas de un run (evento `run.stopped` sin `run.resumed` posterior), con sus opciones.
- Historias en Definiendo paradas más de N días o sin criterios.
- Preguntas abiertas de los agentes (`Question.open`, de todos los proyectos o de uno: `GET /api/questions`). Una historia con alguna pregunta abierta **bloqueante** está bloqueada por quien responde: es derivado, como `blocked_by`, no un estado nuevo.
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
- **La daily** (MT-42, D-44): `POST /api/projects/:key/daily` y `POST .../daily/ideas`. «Qué ha pasado desde X» sale de `Changes` (consulta sobre `Event`, en `app/models/changes.rb`), que también usará «Mientras no mirabas» (MT-31); `Daily` pone lo propio de la daily. La última daily de un actor en un proyecto es su último evento `daily.held` (sin tabla ni estado aparte), así que la de un agente no mueve la de otro. Los evolutivos que propone entran como ideas (`story.created` con `data.daily`), como mucho 3 desde la última daily del actor o en las últimas 24 h (D-55), para que repetir la daily no reinicie el tope. La daily solo avanza al lanzarla: lo que se lee llega hasta un `now` fijado al empezar y la daily se registra en ese mismo instante.
- La API se describe a sí misma (`GET /api`: versión y lista de operaciones).
- `warnings`: avisos que no bloquean (pasar a Lista con preguntas abiertas, empezar una historia bloqueada…).
- Lo que lee un agente (contexto, roadmap, una historia) va además en `data.markdown`. Una historia se lee y se escribe en el mismo formato que imprime `mt show`: frontmatter con sus propiedades y el cuerpo debajo.

**Presencia de actores** (MT-36, D-46): la API es petición-respuesta y no hay sesiones ni heartbeats, así que la presencia se deduce de la actividad. Cada petición autenticada marca al actor en `Presence` (proyecto, historia o entidad de la ruta, y «leyendo» si es GET o «escribiendo» si no; al hacerse la escritura, `Event` completa qué ha cambiado). Solo cuentan las respuestas 2xx (un 404 o un 422 no dejan presencia). Un actor está activo 60 s desde su última petición y deja de estarlo solo: un barrido cada 5 s retira a quien caduca y lo emite. Las emisiones son en diferido y agrupadas, y un fallo al emitir se reporta sin romper la petición. Es estado efímero en memoria del proceso: no es una tabla, no escribe en SQLite al leer y no genera eventos. Con varios workers de Puma habría que moverlo a una caché compartida. Cada entrada guarda además `since` (desde cuándo está activo sin cortes: la «sesión») y `wrote_at` (su última escritura): «escribiendo» dura 60 s desde la última escritura, y el barrido baja a «leyendo» a quien sigue activo sin escribir. En directo, por Turbo Streams (MT-38): cada cambio de presencia y cada evento creado emiten un `refresh` a `[project, :live]` y a `:live` (portada; `Presence.stream`), y la página que lo escucha (`layouts/_live`, salvo en los formularios de edición) se vuelve a pintar con morph: lo nuevo aparece en su sitio y lo que enseña la presencia (indicador, «Agentes», puntos de la navegación, bordes) sale del servidor, sin estado en el navegador. `live_controller` cuida en ese repintado el campo con el foco, los `<details>` abiertos y los cambios sin guardar del Roadmap.

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
| `mt ask <n> "…" --option … --recommend 2` | Pregunta con opciones y recomendación; bloquea la historia y la suelta, salvo con `--no-bloqueante` |
| `mt answer <n> 2 [--question id] [--decide]` o `mt answer <n> --text "…"` (respuesta libre; solo una persona; un agente recibe `FORBIDDEN`, D-52) · `mt questions` | Responde una pregunta (y, si quiere, la registra como decisión) · lista las abiertas de todos los proyectos |
| `mt deployed [sha]` (cualquier actor) | Avisa de que un sha está desplegado: las Hechas que contiene salen en «Por probar» (MT-46) |
| `mt qa` · `mt qa <n> ok [--note]` · `mt qa <n> fail --note "…"` (solo una persona; un agente recibe `FORBIDDEN`) | Lista la QA pendiente de todos los proyectos · la da por probada · falla: crea una historia en Definiendo enlazada |
| `mt usage <transcript> [--story n]` · `mt usage --hook` | Reporta el uso (tokens, coste estimado) de una sesión de Claude Code; el hook `SessionEnd` lo hace solo |
| `mt create` · `mt edit` · `mt move` · `mt reorder` · `mt brief` | Escriben producto (crear y editar historias con `--file`, cambiar estado, ordenar con motivo, editar el brief) |

**Skill + hooks**: la skill enseña al agente a usar `mt`, el hook `SessionStart` inyecta `mt context` al empezar cada sesión y el `SessionEnd` reporta su coste (`mt usage --hook`), así cada conversación arranca sabiendo la filosofía del proyecto. `mt init PG --claude` los deja en el repo del proyecto.

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

## Actividad, la portada (MT-30)

`/` es Actividad, con todos los proyectos. No tiene tabla: `Activity` (`app/models/activity.rb`) lo calcula al consultar y devuelve tarjetas (`Activity::Card`) ordenadas por desde cuándo esperan. «Te toca» junta tres tipos: preguntas abiertas de agentes (esperan desde que se hicieron), historias En Definiendo con preguntas abiertas en el cuerpo o paradas, es decir, 3 días sin cambios (esperan desde su último cambio: `updated_at` o su último evento), y proyectos sin ninguna historia Lista y desbloqueada en sus hitos abiertos (esperan desde su último evento). El contador de la barra es el número de tarjetas, y se memoiza por petición en `Current.activity_for_you`. Cada tipo es un partial en `app/views/activity/` (`card.partial`): los bloques de MT-31, MT-32 y MT-33 añaden su método a `Activity` y su partial. «En marcha» son las historias En curso de todos los proyectos.

Las preguntas se responden desde la UI con `POST /p/:slug/stories/:n/questions/:id/answer` (`Questions::AnswersController`): `option` (botón), `note`, `decide=1` o `free=1` con `note` (respuesta libre). Responde el actor humano (D-52) y vuelve a la pantalla de origen; la página refresca con morph y conserva el scroll.

## QA pendiente (MT-32)

Es derivado de Hecha, no un estado y no bloquea nada: `Story::Qa` (`app/models/story/qa.rb`) y la columna `stories.qa`. `move_to!(:done)` la deja en `pending` (y salir de Hecha la vuelve a nulo; lo que pasó solo queda en los eventos); las historias hechas antes tienen `qa` nulo y no entran. `qa_pass!` y `qa_fail!` (solo actor humano) cambian `qa` y registran `qa.passed` / `qa.failed`; `qa_fail!` crea además, en la misma transacción, una historia en Definiendo en el mismo hito (`create_story!` con `qa_failed_from` en su evento) y su número va en `qa.failed`. Dónde se prueba: `Project#qa_url`, la primera URL bajo `## Dónde se prueba` del brief (sin configuración).

En Actividad, `Activity#qa_pending` (tres consultas para todos los proyectos: historias con proyecto e hito, y sus eventos de Hecha; no entra en `for_you`, así que no cuenta en el contador ni añade consultas al resto de pantallas) pinta el grupo «Por probar» al final de «Te toca» (`activity/_qa_group`, `_qa_card`). La UI usa `POST /p/:slug/stories/:n/qa` (`Stories::QaController`, `result=ok|fail`, `note`) y la API `GET /api/qa` y `POST /api/projects/:key/stories/:n/qa`. La Historia enseña el bloque «QA pendiente» (`stories/_qa`) y la propiedad «QA».

### La QA espera al despliegue (MT-46)

Hecha es mergeada, no desplegada, así que «Por probar» solo enseña lo desplegado donde se prueba (D-62). `stories.deployed_at` la pone `Story::Qa#deployed!` (evento `story.deployed`) y `Story::Operations#move_to!` la deja a nulo al entrar o salir de Hecha. `Project#deploys?` (existe un evento `project.deployed`) activa la espera por proyecto sin configuración (D-64): `Story.qa_testable` (QA pendiente y, o el proyecto no despliega, o `deployed_at`) es lo que listan `Activity#qa_pending` y `GET /api/qa`; `Story.qa_undeployed` (pendiente, sin `deployed_at`, en proyecto con espera) alimenta la línea atenuada «N hechas sin desplegar» (`activity/_undeployed`, fuera del contador de «Te toca», con `Activity#qa_undeployed_count`) y `GET /api/qa?undeployed=true`. Ambos scopes llevan la comprobación de `project.deployed` como subconsulta: sin consultas extra por proyecto.

La API (`Api::DeploysController`): `GET /api/projects/:key/deployed` devuelve `{active, stories: [{reference, number, title, done_at, commits: [sha], pr}]}` (leídos con `Event#commits`) y `POST` con `{sha, stories: [números] (máx. 500), warnings}` llama a `Project#deploy!`, que marca las que esperan (idempotente: lo ya desplegado no se vuelve a marcar) y registra `project.deployed`. El servidor no necesita el repo: qué contiene un sha lo calcula el CLI con git (D-63, `cli/internal/mt/deployed.go`). Cualquier actor con token puede llamarla. **Para avisar al desplegar (MT-47)**: el evento es `project.deployed` (con `data["stories"]`, los números que pasan a poder probarse); `Project#deploy!` devuelve esas historias y es el sitio donde engancharlo.

## Avisos push (MT-47)

Qué avisa (D-66): solo hechos de agentes. `question.asked` bloqueante (abre la historia); la historia que pasa a estar por probar, con la misma lista que «Por probar» (`Story.qa_testable`): `project.deployed` en un proyecto que despliega con `mt deployed` (MT-46) o `story.state_changed` a Hecha en uno que nunca ha desplegado; y un proyecto que entra en poco trabajo (`ReadyWork#low?`, una vez hasta rearmarse, `projects.ready_low_notified_at`). Como mucho un aviso por proyecto cada 10 min (`Push::WINDOW`, `projects.last_pushed_at`): lo aplazado sale en un resumen al cerrar la ventana, contando solo lo aplazado que `Activity` aún tiene pendiente.
Cómo: `Event` llama a `Push::Notifier` tras el commit; el envío va en jobs (`Push::DeliverJob`, uno por `push_subscriptions` y aviso, sin reintentos y con 5 s de espera; 410/404 o claves mal formadas borran la suscripción) con el adaptador `:async` de Active Job, en el proceso de Puma. Las suscripciones solo aceptan endpoints de los servicios de push conocidos (`PushSubscription::PUSH_HOSTS`, HTTPS en el 443, sin userinfo), 50 como mucho, y no se les cambian las claves. Claves VAPID en el entorno (`bin/rails mt:vapid`); el service worker (`/service-worker`) solo gestiona `push` y `notificationclick`, sin caché.

## Mientras no mirabas (MT-31)

Tabla `visits`: una fila por pantalla que Fran abre (`story_id` nulo = la portada), con `seen_at` (última apertura) y `since` (desde cuándo se enseña lo cambiado). No hay modelo de usuarios: hay un solo humano. Abrir la pantalla **es** mirarla (`Visit.open!`): no hay botón «visto». Recargar no la vacía: las aperturas separadas por menos de 30 minutos (`Visit::SESSION_GAP`) cuentan como una visita; pasado ese hueco, `since` pasa a ser la última apertura. La primera vez no enseña nada.

Lo cambiado sale de `Changes` (la misma consulta que la daily), sin lo que hizo el actor humano: `WhileAway.home` agrupa por proyecto, resume por actor («claude cerró 3 historias y empezó MT-33») y separa «Decidido por agentes» (`decision.recorded`, orden y movimientos del roadmap, paso a Lista y ediciones del brief o de hitos hechos por agentes); `WhileAway.story` da los eventos de una historia. Las frases salen de `event_sentence`. Al editar el cuerpo de una historia con criterios, `story.edited` guarda `data.criteria = { checked, unchecked, done, total }` (los marcados y desmarcados en esa edición, y cómo queda: «marcó 2 criterios · 2 de 3»); los eventos anteriores a ese dato se enseñan como «edita el cuerpo». Los commits guardan el sha y, desde MT-44, su asunto (`{sha, message}`; los eventos viejos son strings). Se leen siempre con `Event#commits`, que normaliza ambas formas y calcula la URL del commit a partir del PR de GitHub del mismo evento. La precarga de Turbo (`X-Sec-Purpose: prefetch`) no marca la visita; `visits.key` (`home` o `story-<id>`) es única; la primera apertura de una historia parte de la visita de la portada; no se escribe si la última apertura fue hace menos de un minuto.
