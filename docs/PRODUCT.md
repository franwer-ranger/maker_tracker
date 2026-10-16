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

- ¿Qué forma tiene el "contexto de proyecto": un único documento de visión por proyecto, o varios docs (visión, decisiones, glosario)?
- ¿El kanban sigue teniendo sentido? La propuesta de los mockups v2 (Paper, página "v2 · Agent-first") lo sustituye por cinco secciones: Actividad, Roadmap, Historias, Brief y Stats. Pendiente de validar usándolo.
- Además de los criterios de aceptación y los mockups de Paper, ¿qué necesita una historia para que un agente la ejecute sin preguntar?
- ¿Cómo se migra el backlog actual de Notion?
- ¿Los cambios de producto que hace un agente (reordenar el roadmap, tocar el brief, marcar una historia como Lista) se aplican directamente o llegan como **propuesta** que apruebo desde "Necesita tu atención"? Lo segundo me deja de editor, pero añade un paso y choca con "ligero".

## Decisiones

- **Autoalojado en mi torre**, como proyecto aparte de Home Assistant. Solo es accesible desde la red local o Tailscale. Por eso la autenticación de agentes puede ser simple: un token por agente, sin OAuth.
- **Fuera sprints, puntos y velocidad.** Servían para medir a un equipo humano. Construyen los agentes, y el cuello de botella es cuánto defino yo.
- **Sin login para humanos.** Al estar autoalojado, sobra. Lo que sí importa es saber **quién hizo qué** (yo, Claude, Codex…) para el registro de actividad.
- **Maker Tracker y wflow, desacoplados por contrato.** Leer historias y recibir eventos genéricos; nada de base de datos compartida, ni leer los `state.md` de wflow, ni conceptos de wflow (review-tech, apply…) en el modelo del núcleo: las fases son texto libre que trae el evento.
- **La UI de wflow es un módulo aislado con interruptor, no un sistema de plugins.** Dependencia en un solo sentido: el núcleo nunca usa nada de `Wflow::`. Si sobra, se borra la carpeta. Un Rails engine o un sistema de plugins genérico solo si aparece una segunda integración y se repite el patrón.
- **Open source, con landing pública.** El repo será abierto (MIT) con instrucciones para autoalojarlo. La landing es pública e importante: es lo que enseñamos a Romer y Christian (cofundadores) y la puerta al repo. Su única acción es "autoalójalo".
- **Sistema de diseño v3** (Paper, páginas "v3 · Sistema" y "v3 · Landing"): solo modo oscuro por ahora. Dos voces: Instrument Serif para titulares grandes (sustituye a Apple Garamond, que no tiene licencia web) y Geist / Geist Mono para todo lo demás. El naranja `#FF3F01` se reserva para acción y atención. Iconos Lucide; fuera Font Awesome.
- **Las paradas de wflow, primero como comandos.** Cada opción de una parada muestra su comando (`wflow decide 48 …`) y lo ejecuto yo en la terminal. Si se queda corto, el siguiente paso es que Maker Tracker guarde la decisión y wflow la recoja al reanudar. Maker Tracker nunca ejecuta wflow.

## Más documentación

- [`ROADMAP.md`](ROADMAP.md): qué construimos y en qué orden.
- [`ARCHITECTURE.md`](ARCHITECTURE.md): modelo de datos v2, interfaz para agentes, contrato de eventos y módulo de wflow.
