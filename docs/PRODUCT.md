# Maker Tracker · Producto

> Documento vivo. Es el contexto que cualquier agente debe leer antes de proponer, priorizar o construir algo en Maker Tracker. Si una decisión lo contradice, se actualiza este documento primero.

## Visión

Maker Tracker es la herramienta donde se **definen y organizan productos**, pensada desde el principio para trabajar **junto a agentes de IA**. Sustituye a Notion como fuente de verdad de los proyectos: definiciones, backlog y estado.

La referencia es Paper frente a Figma: una herramienta ligera, con un MCP de primera clase, en la que el agente es un usuario más y no un añadido.

## Cómo trabajo (el flujo que la herramienta debe servir)

1. **Definición del producto**: es donde está el esfuerzo humano. Itero con la IA las definiciones (en Maker Tracker) y los mockups (en Paper).
2. **Backlog**: cuando algo está claro, se convierte en historias con contexto suficiente para que un agente las ejecute sin preguntar.
3. **Desarrollo casi automático**: le pregunto al agente *"¿qué es lo siguiente que tenemos que hacer?"*. Para decidirlo, el agente cruza tres fuentes:
   - el **roadmap**: qué queremos construir y en qué orden;
   - las **historias** que aún no están hechas;
   - el **código**: lo que de verdad está hecho, aunque sea mirando solo el changelog.

   Elige la historia que más sentido tiene y la implementa. Maker Tracker guarda las dos primeras fuentes y se las sirve al agente. El código vive en el repo.
4. **Cierre**: el agente actualiza el estado y deja constancia (comentarios, decisiones) en la propia historia.

## Principios

- **Dos públicos, dos interfaces**: los agentes piden datos y leen JSON o markdown, así que la UI no les importa. La UI es para mí: para definir producto y para **enterarme de lo que está pasando** (qué han hecho los agentes, qué está en curso, qué necesita mi atención).
- **Agent-first**: todo lo que se puede hacer en la UI se puede hacer por MCP, con la misma semántica. Las respuestas son compactas y estructuradas, pensadas para el contexto de un LLM.
- **Quién escribe qué** (aprendido de wflow): los agentes escriben razonamiento y contenido (definiciones, notas, resúmenes). Maker Tracker es dueño de los hechos (transiciones, fechas, quién hizo qué, commits y PR enlazados) y no deja que un agente los reescriba.
- **Cada cosa que pide tu atención trae sus opciones**: qué ha pasado, qué leer y qué puedes hacer. Cada opción es también un comando, así que una persona y un agente ven lo mismo.
- **Ligero**: pocas entidades, pocas pantallas y cero configuración. Ante la duda, quitar. Sin campos ni flujos que no use nadie.
- **El contexto vive con el proyecto**: la visión, las decisiones y los principios de cada proyecto se guardan en Maker Tracker y los agentes los cargan antes de recomendar nada.
- **Las historias se escriben para ser ejecutadas**: qué, por qué y criterios de aceptación, con enlaces a mockups de Paper.
- **Dogfooding**: Maker Tracker se construye usando Maker Tracker.

## Ecosistema: Maker Tracker y wflow

- **wflow** (CLI en Go que hice para Webel) automatiza la **ejecución** de una card: implement → QA humana → rondas de revisión → PR → merge → actualizar la card. Cada fase es un proceso de agente con contexto limpio. Hoy lee las cards de Notion.
- **Reparto**: Maker Tracker es el lado de **producto** (qué, por qué y en qué orden) y wflow el de **ejecución** (cómo una card se convierte en código mergeado).
- **Cada uno vive sin el otro, y juntos dan el flujo completo** de producto a tecnología. Ninguno conoce al otro por dentro: hablan un contrato pequeño y genérico (detalle en [`ARCHITECTURE.md`](ARCHITECTURE.md#contrato-con-herramientas-de-ejecución)):
  1. **Leer una historia**: wflow pide una historia y recibe markdown (qué, por qué, criterios, enlaces).
  2. **Reportar lo que pasa**: wflow manda eventos (fase empezada o terminada, coste, commit, PR, parada con opciones, merge). Maker Tracker los guarda como eventos genéricos de un actor; los podría mandar cualquier otra herramienta.
- **wflow sin Maker Tracker**: su fuente de historias es intercambiable (Notion, un fichero markdown local o Maker Tracker) y el reporte de eventos es opcional.
- **Maker Tracker sin wflow**: se define producto y cualquier agente trabaja con `mt next` / `mt start` / `mt done`. La pestaña Ejecución y el desglose de Stats solo aparecen si llegan eventos.
- **La UI de wflow es un módulo opcional de Maker Tracker**, no un sistema de plugins: todo lo específico de wflow vive aislado en `app/integrations/wflow/` y se activa por proyecto.
- Maker Tracker **no orquesta el desarrollo**: no lanza ni controla procesos de wflow. Recibe lo que pasa y lo muestra. Así su UI es el "panel en el navegador" que wflow tiene pendiente, sin que wflow necesite un servidor.
- Adaptaciones pendientes en wflow: fuente de historias intercambiable, emisor de eventos opcional, registrar cuándo entra y sale de cada parada (para medir el tiempo esperando por mí) y quitar lo específico de Webel (HIPPO, NotionAI, ramas development/testing/master).

## No-objetivos (por ahora)

- No es una herramienta de equipos grandes ni tiene permisos complejos. El primer usuario soy yo con mis agentes.
- No es un editor de documentos generalista como Notion. Solo guarda lo necesario para definir y construir producto.

## Preguntas abiertas

- Colaboración: tras cerrar el MVP, el tablero podrá ser colaborativo (varias personas). Cómo, se piensa entonces; hasta ahí, un único actor humano.
- ¿Cómo se migra el backlog actual de Notion?
- ¿Los cambios de producto que hace un agente (reordenar el roadmap, tocar el brief, marcar una historia como Lista) deberían pasar a ser **propuestas** que apruebo desde "Necesita tu atención"? En M2 se aplican directamente y quedan registrados (ver Decisiones); se revisa en M3 con la pantalla Actividad delante.

## Decisiones

### 2026-10-16 · Definición de M2

- **Los agentes escriben producto directamente, con registro**: crean y editan historias, las mueven de estado (también a Lista), las reordenan con motivo y editan el brief. Cada cambio deja su evento a su nombre. Sin esto, Maker Tracker no se puede construir con Maker Tracker. Si hacen falta propuestas que apruebe, se decide en M3.
- **El CLI `mt` es un binario en Go**, en este mismo repo (`cli/`), para que cambie a la vez que la API. Sin dependencias para quien lo instala. Publicar binarios (Releases, Homebrew) se decide después.
- **Tokens de agente con un comando en el servidor** (`bin/rails "mt:token[claude]"`), sin pantalla. El token identifica, no protege: la app sigue solo en la red local o Tailscale. La UI de agentes llega más adelante.
- **Lo que lee un agente es markdown.** La API devuelve el sobre en JSON, pero contexto, roadmap e historias van en markdown, y `mt` imprime texto legible por defecto (`--json` para el sobre). Una historia se lee y se escribe en el mismo formato que `docs/backlog/` (frontmatter + cuerpo).
- **Proyectos por su clave** en la API y en `mt` (`PG`, `PG-49`), no por el slug.
- **Skill y hook por repo**: `mt init PG --claude` deja `.mt`, la skill y el hook `SessionStart` en el repo del proyecto, no en la configuración global.

### 2026-10-16 · Arranque de M1

- **El contexto de proyecto es un único `brief`** en markdown (visión, principios, fuera de alcance, glosario). Las decisiones van aparte, en `Decision`. Si algún día hace falta otro tipo de documento, se añade entonces.
- **Un único actor humano** (`fran`, creado en seeds) al que se atribuye todo lo que pasa en la UI. Colaboración multi-persona, después del MVP.
- **Fuera el login ya**: quitar Devise es de las primeras historias de M1, para que los agentes de desarrollo prueben su trabajo sin autenticarse. Sustituye a la regla anterior de esperar a la confirmación de self-host; la condición pasa a self-host (la torre no se expone fuera de la red local / Tailscale).
- **Esquema v2 desde cero**: se borran las tablas v1 (sprints, items, users…) sin migrar datos; no hay datos reales.
- **Fuera el kanban v1** (icebox/backlog/sprints). En su lugar, **dos vistas del mismo proyecto**:
  - **Tablero** (portada para la persona): columnas por estado (Idea · Definiendo · Lista · En curso · Hecha), filtrado por hito (por defecto el primer hito abierto; también "Todos" y la bandeja de ideas). Dentro de cada columna, el orden es el del roadmap. Arrastrar entre columnas cambia el estado; mover arriba o abajo reordena la historia en su hito. Ambas cosas generan su evento.
  - **Roadmap**: los hitos en orden, cada uno con sus historias. Es donde se decide el orden entre hitos y lo que leen los agentes (`mt roadmap`).
- **Reordenar pide motivo a los agentes** y es opcional en la UI. El evento se registra siempre.
- **Historias: propiedades arriba, markdown libre abajo** (idea tomada de las tarjetas de Notion de la guardería).
  - Identificador: `number` por proyecto con la clave corta del proyecto (`MT-36`), citable en commits y en `mt show MT-36`.
  - Propiedades (`properties`, json) que la app conoce: `mockup` (url de Paper; necesaria para Lista si la historia tiene UI), `labels` (lista libre: plataforma, épica…) y `blocked_by` (números de historia; "bloquea" se calcula al revés).
  - **Bloqueada no es un estado**: se deriva de `blocked_by`. `mt next` nunca propone una historia bloqueada y el tablero la marca.
  - Fuera, respecto a Notion: Now/Next/Later (lo sustituyen los hitos), Prioridad (la prioridad es el orden en el hito), coste a mano (llega en M4 desde los runs) y relación con fichas de pantalla.
  - Plantilla del cuerpo: Contexto · Historia (Como…, quiero…, para…) · Criterios de aceptación (numerados y comprobables) · Fuera de alcance · Notas para quien lo construya · Preguntas abiertas. Lo que se hace al terminar una historia es igual para todas y vive en las instrucciones del agente, no en cada historia.
  - Para pasar a Lista: ninguna pregunta abierta y mockup si tiene UI. En M1 es una regla visible, no una validación que bloquee.
- **Decisiones**: solo se añaden, desde el Brief. Para cambiar una, se escribe otra que la sustituye.
- **Bandeja de ideas**: las historias sin hito se ven al final del Roadmap.
- **Eventos en M1**: se generan todos; la Historia muestra su historial. La pantalla Actividad llega en M3.
- **Edición de markdown**: textarea con vista previa.
- **Las historias de UI de M1 esperan a sus mockups** en Paper; las de modelo, eventos y seeds salen Listas antes. (Hechos y aprobados el mismo día: página `App`.)
- **Una sola versión en Paper.** Lo que construimos ahora es la v2 del producto; el sistema de diseño no lleva número. Los diseños antiguos se borran en cuanto tienen sustituto.
- **Iconos: Heroicons** en lugar de Lucide.

### Anteriores

- **Autoalojado en mi torre**, como proyecto aparte de Home Assistant. Solo es accesible desde la red local o Tailscale. Por eso la autenticación de agentes puede ser simple: un token por agente, sin OAuth.
- **Fuera sprints, puntos y velocidad.** Servían para medir a un equipo humano. Construyen los agentes, y el cuello de botella es cuánto defino yo.
- **Sin login para humanos.** Al estar autoalojado, sobra. Lo que sí importa es saber **quién hizo qué** (yo, Claude, Codex…) para el registro de actividad.
- **Maker Tracker y wflow, desacoplados por contrato.** Leer historias y recibir eventos genéricos; nada de base de datos compartida, ni leer los `state.md` de wflow, ni conceptos de wflow (review-tech, apply…) en el modelo del núcleo: las fases son texto libre que trae el evento.
- **La UI de wflow es un módulo aislado con interruptor, no un sistema de plugins.** Dependencia en un solo sentido: el núcleo nunca usa nada de `Wflow::`. Si sobra, se borra la carpeta. Un Rails engine o un sistema de plugins genérico solo si aparece una segunda integración y se repite el patrón.
- **Open source, con landing pública.** El repo será abierto (MIT) con instrucciones para autoalojarlo. La landing es pública e importante: es lo que enseñamos a Romer y Christian (cofundadores) y la puerta al repo. Su única acción es "autoalójalo".
- **Repos públicos separados** (2026-10-16): la landing va en su propio repo (Astro o similar, estático) y la app en el suyo (`franwer-ranger/maker_tracker`). wflow podría publicarse aparte, con otro nombre. La landing describe el producto completo aunque aún no exista todo; publicar no es comunicar, y comunicarlo lo decide Fran.
- **Filosofía de fondo** (sdvns, de Fran y Romer): ser dueño de tu código, tu infraestructura y tus datos, en lugar de pagar a otras empresas por lo que hoy resuelves tú con tus agentes y tu hardware. La landing la toca en una línea ("Are we free?"), sin hacer de ello el tema.
- **Sistema de diseño** (Paper, páginas "Sistema" y "Landing"): solo modo oscuro por ahora. Dos voces: Instrument Serif para titulares grandes (sustituye a Apple Garamond, que no tiene licencia web) y Geist / Geist Mono para todo lo demás. El naranja `#FF3F01` se reserva para acción y atención. Iconos Heroicons (outline, trazo 1.5; sustituye a Lucide el 2026-10-16); fuera Font Awesome.
- **Las paradas de wflow, primero como comandos.** Cada opción de una parada muestra su comando (`wflow decide 48 …`) y lo ejecuto yo en la terminal. Si se queda corto, el siguiente paso es que Maker Tracker guarde la decisión y wflow la recoja al reanudar. Maker Tracker nunca ejecuta wflow.

## Más documentación

- [`ROADMAP.md`](ROADMAP.md): qué construimos y en qué orden.
- [`ARCHITECTURE.md`](ARCHITECTURE.md): modelo de datos v2, interfaz para agentes, contrato de eventos y módulo de wflow.
