# Maker Tracker · Roadmap

> Qué construimos y en qué orden. Cuando Maker Tracker pueda guardar su propio roadmap (M2), este fichero se migra allí y queda solo como enlace (dogfooding). Contexto en [`PRODUCT.md`](PRODUCT.md) y diseño en [`ARCHITECTURE.md`](ARCHITECTURE.md).

## Punto de partida

La v1: proyectos, sprints, items y comentarios en un kanban estilo Pivotal Tracker, con Devise. Ya está en Ruby 3.4.8 y Rails 8.1. Tiene bugs conocidos (velocidad calculada con el último sprint de cualquier proyecto, redirección rota al borrar items, falta `done_controller.js`, sin autorización), pero **no se arreglan**: la v2 sustituye ese modelo.

Supuesto: no hay datos reales en la v1 que conservar, solo seeds. Si los hay, se añade una migración de datos a M1.

## Cómo se trabaja

Tres vertientes en paralelo, cada una con su agente: **producto y diseño**, **desarrollo** y **self-host y distribución**. Reglas y briefs en [`workstreams/`](workstreams/README.md). Hasta que M2 permita guardar el backlog en la propia app, las historias viven en [`backlog/`](backlog/) y este roadmap las enlaza en orden.

En paralelo a los hitos, la vertiente de self-host despliega en la torre lo que haya en cada momento (se adelanta a M2), prepara el repo para hacerse público (MIT) y construye la landing pública.

## M1 · Núcleo v2

Objetivo: el modelo nuevo funcionando, con la UI mínima para definir producto.

Historias, en orden:
1. [#001 Sistema de diseño v3 en código](backlog/001-design-system-tokens.md) · Hecha
2. [#002 Quitar el login y la v1](backlog/002-remove-login-and-v1.md) · Lista
3. [#003 Modelo v2 · proyectos, hitos e historias](backlog/003-projects-milestones-stories.md) · Lista
4. [#004 Modelo v2 · actores, decisiones y comentarios](backlog/004-actors-decisions-comments.md) · Lista
5. [#005 Eventos · el registro de los hechos](backlog/005-events.md) · Lista
6. [#006 Seeds · Postgram como en los mockups](backlog/006-seeds-postgram.md) · Lista
7. [#007 Proyectos y estructura de la app](backlog/007-projects-and-shell.md) · Definiendo (falta mockup v3)
8. [#008 Tablero por estados](backlog/008-board.md) · Definiendo (falta mockup v3)
9. [#009 Roadmap · hitos e historias en orden](backlog/009-roadmap.md) · Definiendo (falta mockup v3)
10. [#010 Historia · ver y definir una historia](backlog/010-story-page.md) · Definiendo (falta mockup v3)
11. [#011 Brief · visión y decisiones del proyecto](backlog/011-brief.md) · Definiendo (falta mockup v3)

Las de UI pasan a Lista cuando sus pantallas estén en Paper (`v3 · App`). Decisiones de esta fase en [`PRODUCT.md`](PRODUCT.md#2026-10-16--arranque-de-m1).

## M2 · Interfaz para agentes

Objetivo: un agente puede responder "¿qué es lo siguiente?" y cerrar el ciclo. **A partir de aquí, Maker Tracker se construye con Maker Tracker.**

- API JSON con sobre (`ok`, `data`, `summary`, `breadcrumbs`), errores con `hint` y tokens por agente.
- CLI `mt`: `context`, `next`, `roadmap`, `show`, `start`, `done`, `comment`, `decide`.
- Skill para Claude Code y hook SessionStart con `mt context`.
- Desplegar la v2 en la torre (red local / Tailscale), usando el camino que ya habrá montado la vertiente de self-host.
- Migrar este roadmap y el backlog de Maker Tracker a la propia app.

## M3 · Actividad

Objetivo: enterarme de qué está pasando sin preguntar.

- Pantalla Actividad como portada: "Necesita tu atención", "En curso ahora" y el registro cronológico.
- Atención derivada de los datos: historias atascadas en Definiendo, preguntas de agentes.
- Decidir la pregunta abierta de las propuestas: ¿los cambios de producto de un agente se aplican directamente o pasan por mí?

## M4 · Ejecución y wflow

Objetivo: el flujo completo de producto a tecnología, con cada pieza viviendo sola.

- Maker Tracker: entidad `Run`, endpoint de eventos (genérico, idempotente) y vista genérica de runs en la historia.
- Maker Tracker: módulo `app/integrations/wflow/` con interruptor por proyecto (pestaña Ejecución, tarjetas de parada con sus comandos).
- Stats: coste total, por historia y por hito; tiempo de agente frente a tiempo esperando por mí. El desglose por fase y modelo, en el módulo de wflow.
- wflow (en su repo): fuente de historias intercambiable (Notion / markdown local / Maker Tracker), emisor de eventos opcional, registrar entrada y salida de cada parada, quitar lo específico de Webel.

## Después

Sin orden decidido:

- MCP fino sobre la API (Claude Desktop, móvil).
- Migrar los backlogs desde Notion.
- Paradas nivel 2: Maker Tracker guarda la decisión y wflow la recoge al reanudar.
