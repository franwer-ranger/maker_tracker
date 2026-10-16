## Visión

Maker Tracker es la herramienta donde se **definen y organizan productos**, pensada desde el principio para trabajar **junto a agentes de IA**. Sustituye a Notion como fuente de verdad de los proyectos: definiciones, backlog y estado. La referencia es Paper frente a Figma: ligera, con una interfaz para agentes de primera clase, en la que el agente es un usuario más y no un añadido.

El flujo que sirve: defino el producto con la IA (aquí) y los mockups (en Paper); lo que está claro se convierte en historias con contexto suficiente para que un agente las ejecute sin preguntar; le pregunto al agente "¿qué es lo siguiente?" y él cruza el roadmap, las historias abiertas y el código; al terminar, actualiza el estado y deja constancia en la historia.

## Principios

- **Dos públicos, dos interfaces.** Los agentes leen markdown y JSON (`mt`, la API); la UI es para Fran: definir producto y enterarse de lo que pasa.
- **Agent-first.** Todo lo que se hace en la UI se puede hacer con `mt`, con la misma semántica.
- **Quién escribe qué.** Los agentes escriben contenido (historias, brief, comentarios, decisiones). Maker Tracker es dueño de los hechos (transiciones, fechas, quién hizo qué) y nadie los reescribe.
- **Cada aviso trae sus opciones**, y cada opción es también un comando: una persona y un agente ven lo mismo.
- **Ligero.** Pocas entidades, pocas pantallas, cero configuración. Ante la duda, quitar.
- **El contexto vive con el proyecto.** Visión, decisiones y principios se guardan aquí y los agentes los cargan antes de recomendar nada.
- **Las historias se escriben para ser ejecutadas:** qué, por qué y criterios de aceptación, con enlace al mockup.
- **Dogfooding.** Maker Tracker se construye con Maker Tracker.

## Fuera de alcance

- Equipos grandes y permisos complejos: el primer usuario es Fran con sus agentes.
- Ser un editor de documentos generalista como Notion: solo lo necesario para definir y construir producto.
- Orquestar el desarrollo: Maker Tracker no lanza ni controla agentes ni wflow; recibe lo que pasa y lo muestra.

## Glosario

- **Historia:** algo a construir (`MT-14`). Estados: Idea, Definiendo, Lista, En curso, Hecha. Bloqueada no es un estado: se deriva de `blocked_by`.
- **Lista:** con contexto suficiente para construirla sin preguntar. Los agentes de desarrollo solo cogen historias Listas.
- **Hito:** un paso del roadmap (`M2`), con su objetivo. El orden de los hitos y de las historias dentro de cada uno es la prioridad.
- **Bandeja de ideas:** historias sin hito.
- **Decisión:** qué decidimos y por qué (`D-14`). Solo se añaden; para cambiar una, otra la sustituye.
- **Actor:** quién hace algo: Fran o un agente (claude, codex…).
- **Vertiente:** cada línea de trabajo en paralelo (producto, desarrollo, self-host), con su agente.
- **wflow:** la herramienta de ejecución de Fran (CLI en Go). Habla con Maker Tracker por un contrato genérico.
