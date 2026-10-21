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
- **La autonomía de los agentes se escribe en el brief** (D-48): la sección `## Autonomía` de cada proyecto dice qué pueden decidir solos. Lo que permite lo hacen, y queda registrado; lo demás lo preguntan en la historia. Los cambios de producto de un agente no pasan a ser propuestas, y no hay un motor de reglas: es texto que `mt context` carga en cada sesión.
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

## Decisiones

Viven en **Maker Tracker** (proyecto `MT`), desde el 2026-10-16: `mt decisions` en este repo, o la pantalla **Brief**. Se registran con `mt decide "…" --why "…"` y solo se añaden: para cambiar una, otra la sustituye (`--supersedes D-n`). Las 35 que había aquí son D-1 a D-35, en el mismo orden; el texto antiguo está en el historial de git.

## Más documentación

- [`ROADMAP.md`](ROADMAP.md): qué construimos y en qué orden.
- [`ARCHITECTURE.md`](ARCHITECTURE.md): modelo de datos v2, interfaz para agentes, contrato de eventos y módulo de wflow.
