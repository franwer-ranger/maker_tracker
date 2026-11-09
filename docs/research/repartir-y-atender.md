# Repartir y atender · cómo lo hacen los demás

> Investigación de MT-62 (2026-11-09) para el hito «Repartir y atender» (D-79). Fuentes al final. Lo marcado como **(suposición)** no está en ninguna fuente pública y conviene comprobarlo.

## La pregunta

Cómo coge trabajo un agente, cómo se evita que dos se pisen o que uno se quede colgado, cómo pide permiso o pregunta, cómo le llega eso a la persona y qué se mide. No miramos su UI, sino sus mecanismos.

## Herramienta por herramienta

### Linear (Agents, en developer preview)

- **Coger trabajo:** se le *delega* una issue al agente, o se le menciona. Delegar no es asignar: la persona sigue siendo la responsable y el agente actúa en su nombre. Cada delegación o mención abre una **AgentSession**.
- **No pisarse:** la sesión es por agente y por issue. Los documentos no explican qué pasa si se delega la misma issue dos veces.
- **Preguntar:** el agente publica *activities* tipadas (`thought`, `action`, `elicitation`, `response`, `error`). La pregunta es una `elicitation`. Cuando la persona contesta en la sesión, al agente le llega un evento `prompted` y sigue.
- **Estado:** la sesión tiene 6 estados visibles: `pending`, `active`, `awaitingInput`, `error`, `complete` y **`stale`**. **Linear los deduce de la última activity**: el agente no los fija. Quien deja de hablar acaba en `stale`.
- **Llegar a la persona:** dentro de Linear, en la issue y en su bandeja de notificaciones.
- **Medir:** nada público.

### Coding agent de GitHub Copilot

- **Coger trabajo:** asignar la issue a Copilot. Abre al momento un PR en borrador enlazado. El PR es la reserva visible: cualquiera ve que alguien la está haciendo.
- **No pisarse:** Copilot solo trabaja en los PR que abrió él. No hay reserva fuera de eso.
- **Preguntar e iterar:** no pregunta durante el trabajo. Termina, deja «Copilot finished work» en el PR y **te pide revisión**, que es la notificación. Para corregir, se le menciona en un comentario *del PR*; los de la issue no le llegan.
- **Permiso:** quien le pidió el trabajo no puede aprobar su PR. Se mantiene la regla de revisión independiente.
- **Medir:** nada público por tarea.

### Cursor (agentes en segundo plano)

- **Coger trabajo:** desde Slack o Linear, mencionando o asignando a @Cursor, o con reglas de triaje automático (por etiqueta, prioridad…).
- **No pisarse:** hay informes en el foro de que asignar una issue de Linear a veces arranca **dos agentes con la misma tarea**. Es justo el problema que una reserva evita.
- **Llegar a la persona:** al terminar, un aviso en Slack con el enlace al PR. Algunos usuarios dicen que el aviso no siempre llega.
- **Medir:** nada público.

### Devin

- **Coger trabajo:** sesiones lanzadas desde Slack, la web, la API o automatizaciones. Hay *playbooks*: prompts reutilizables para tareas que se repiten.
- **Estado:** la API tiene un estado `blocked` que significa «esperando a la persona».
- **Colgado o sin presupuesto:** una sesión inactiva o que llega a su límite de ACU **se duerme** en vez de terminar, y se despierta con cualquier mensaje. Avisa antes de dormirse.
- **Llegar a la persona:** en Slack, en el hilo. Su propio blog reconoce el problema: informar de todo en Slack crea ruido.
- **Medir:** ACU (coste) por sesión.

### Factory (Droids)

- **Coger trabajo:** asignar la issue de Linear o Jira a Factory, mencionarlo, o reglas de triaje automático. Abre una sesión que investiga, implementa, prueba y abre PR.
- **No pisarse, preguntar:** nada público.

### Claude Code: permisos desde el móvil

- **Pedir permiso:** cada herramienta que no está permitida para y espera aprobación. Con Remote Control se puede contestar desde la app o la web, y la app avisa. Las herramientas de la comunidad (por ejemplo, `claude-remote-approver` con ntfy) mandan cada petición al móvil con **Aprobar / Aprobar siempre / Denegar** y, si nadie contesta a tiempo, vuelven al terminal.
- Es la prueba de que el problema es real: hay gente construyendo a mano el «contestar desde la notificación».

### Colas de trabajo clásicas (no son de agentes, pero resuelven la reserva)

- SQS: un mensaje recibido queda invisible durante un *visibility timeout*. Si el consumidor no lo borra ni lo prorroga, vuelve a la cola solo.
- Leases de Kubernetes: quien tiene el lease lo renueva cada poco. Si deja de renovarlo, otro lo coge.
- La idea común es que **la reserva caduca sola, y quien la tiene la renueva**, sin que una persona tenga que intervenir.

## Comparativa

| | Linear | Copilot | Cursor | Devin | Maker Tracker hoy |
|---|---|---|---|---|---|
| Coger trabajo | Delegar o mencionar | Asignar | Mencionar, asignar o triaje | Sesión | `mt next` + `mt start` (el agente elige el primero Listo) |
| Evitar duplicados | Una sesión por agente e issue | El PR enlazado | Fallos conocidos | — | Reserva + `CLAIMED_BY_OTHER` |
| Si el agente desaparece | Pasa a `stale` | — | — | Se duerme y se reanuda | **Nada: se queda En curso** |
| Estado | Deducido de la última activity | Eventos del PR | — | Incluye `blocked` | Hecho por los comandos + presencia (D-73) |
| Preguntar | `elicitation` | No; itera en revisión | — | En el hilo de Slack | `mt ask` con opciones, bloqueante o no |
| Pedir permiso | — | Revisión obligatoria del PR | — | — | Texto del brief (D-48); sin canal propio |
| Dónde llega | Bandeja de Linear | Notificación de revisión | Slack | Slack | «Te toca» + push (abre la app) |
| Contestar sin abrir | No | No | No | En Slack | No |
| Medir | — | — | — | Coste por sesión | Coste y Stats; **no la espera** |

## Copiar, no copiar, no sabemos

**Copiar**
- **Deducir el estado de las señales que ya hay, no pedir latidos** (Linear). Encaja con MT-63: la presencia y las llamadas a la API ya son señales.
- **Un estado intermedio antes de soltar** (`stale` en Linear, «se duerme» en Devin). Avisar antes de quitarle algo a un agente es más barato que equivocarse. Es la tarjeta «¿sigue viva?» de MT-63.
- **La reserva caduca sola y se renueva usándola** (SQS, leases). Es la forma de pensar MT-63.
- **Una pregunta es un tipo de mensaje, no un comentario** (`elicitation`). Ya lo tenemos con `mt ask`; pedir permiso merece el mismo trato (MT-64).
- **Aprobar desde la notificación, con «aprobar siempre»** (las herramientas de Claude Code). «Aprobar siempre» es interesante para MT-64: convertiría un permiso repetido en una línea de Autonomía del brief, con tu OK.

**No copiar**
- **Slack como bandeja** (Devin, Cursor). Su propio equipo reconoce el ruido. Sin canal externo, «Te toca» filtra mejor.
- **Asignar el trabajo a mano a cada agente** (todos). Para Fran el orden del roadmap ya decide qué va antes; con `mt next` no hay que asignar.
- **No preguntar nunca y corregir en la revisión** (Copilot). Funciona para cambios pequeños, pero mueve la atención al final, que es lo más caro.

**No sabemos**
- Cuánto tarda Linear en pasar una sesión a `stale`. No es público.
- **Botones en las notificaciones de una PWA en iOS.** Las fuentes se contradicen. Las más fiables (foros de Apple, la documentación de OneSignal) dicen que no; algunas guías de 2026 dicen que sí sin citar fuentes.

## Qué cambia en las historias del hito

Revisado con Fran el 2026-11-09:

- **MT-63 (reserva que caduca): se confirma.** Entra el estado intermedio «¿sigue viva?» como en Linear y Devin, sin pedir latidos (D-83). N sigue abierto (propuesta: 4 h).
- **MT-64 (pedir permiso): se confirma, con un añadido.** Valorar «aprobar siempre» → propone añadir esa acción a la Autonomía del brief. Sería otra historia o un criterio opcional.
- **MT-65 (medir la espera): descartada.** Ninguna herramienta lo mide, pero no es porque falte: a Fran no le importa (D-79).
- **MT-66 («casi listas»): descartada.** Una historia está en Definiendo o Lista (D-80).
- **MT-67 (contestar desde la notificación): a la bandeja de ideas.** Con una PWA no compensa; espera a que haya app nativa (D-81).
- **Slack u otro canal externo como bandeja: no** (D-82).

## Fuentes

- Linear · [Agents](https://linear.app/developers/agents) · [Agent interaction](https://linear.app/developers/agent-interaction) · [Cómo se integró Cursor](https://linear.app/blog/how-cursor-integrated-with-linear-for-agents)
- GitHub · [Usar Copilot en una issue](https://docs.github.com/en/copilot/using-github-copilot/coding-agent/using-copilot-to-work-on-an-issue) · [Agentes de Copilot en GitHub](https://docs.github.com/en/copilot/how-tos/copilot-on-github/use-copilot-agents/overview)
- Cursor · [Cursor en Linear](https://cursor.com/blog/linear) · [Integraciones](https://cursor.com/help/integrations/third-party) · [Foro: dos agentes a la vez](https://forum.cursor.com/t/cursor-linear-integration-starting-two-background-agents-at-once/135033) · [Foro: sin aviso en Slack](https://forum.cursor.com/t/no-slack-notification-background-agent/152122)
- Devin · [Slack](https://docs.devin.ai/integrations/slack.md) · [API](https://docs.devin.ai/openapi.yaml) · [Etiqueta en Slack](https://devin.ai/blog/devins-slack-etiquette) · [Límites de ACU](https://knowledge.cognition.ai/articles/1715208244-for-people-confused-about-session-credit-limits)
- Factory · [Asignar tickets](https://factory.ai/product/ai-project-manager) · [Factory en Jira](https://www.atlassian.com/blog/jira/factory-in-jira)
- Claude Code · [claude-remote-approver](https://github.com/yuuichieguchi/claude-remote-approver) · [Remote Control desde el móvil](https://pasqualepillitteri.it/en/news/316/claude-code-remote-control-mobile)
- Push en iOS · [Foros de Apple](https://developer.apple.com/forums/thread/726793) · [OneSignal: botones](https://documentation.onesignal.com/docs/en/action-buttons.md) · [MobiLoud](https://www.mobiloud.com/blog/progressive-web-apps-ios) · [MagicBell](https://www.magicbell.com/blog/pwa-ios-limitations-safari-support-complete-guide)
