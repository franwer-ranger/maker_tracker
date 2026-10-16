---
number: 16
title: API · leer contexto, siguiente, roadmap e historias
milestone: M2
state: ready
claimed_by:
mockup:
labels: [api]
blocked_by: [15]
---

## Contexto

Es la mitad de "¿qué es lo siguiente?": lo que un agente lee al empezar una sesión y antes de coger trabajo. Lo que lee un agente es **markdown compacto**, no JSON anidado: es lo que mejor entiende. Por eso estas operaciones devuelven `data.markdown` además de los datos estructurados.

## Historia

Como agente, quiero leer el contexto del proyecto, la siguiente historia y el roadmap en markdown, para arrancar sabiendo qué buscamos y qué toca.

## Criterios de aceptación

- [ ] **Contexto** (`GET /api/projects/PG/context`): el brief entero, las 5 últimas decisiones vigentes (sin las sustituidas), el hito actual con su objetivo y lo que está en curso (referencia, título y quién la tiene). En Postgram cabe en menos de 150 líneas.
- [ ] **Siguiente** (`GET /api/projects/PG/next`): la historia de `Project#next_story` en el mismo markdown que **ver**, más un motivo en una frase: "Primera Lista no bloqueada de M2. Antes en el orden: PG-48 y PG-45 (en curso)". Si una Lista se salta por bloqueo, el motivo lo dice. Si no hay ninguna, error `NOTHING_READY` con un hint ("Hay 2 historias en Definiendo en M2: mt list --state defining").
- [ ] **Roadmap** (`GET /api/projects/PG/roadmap`): los hitos abiertos en orden, cada uno con su objetivo y sus historias en orden (referencia, estado, título, quién la tiene y si está bloqueada). Al final, la bandeja de ideas. Con `?closed=true` incluye los hitos cerrados. Se genera en vivo.
- [ ] **Ver** (`GET /api/projects/PG/stories/49`): la historia como markdown con frontmatter, en el mismo formato que `docs/backlog/` (`number`, `title`, `milestone`, `state`, `claimed_by`, `mockup`, `labels`, `blocked_by`) y el cuerpo debajo. Añade "Bloqueada por PG-47 (Lista)" si aplica, los comentarios y los 10 últimos eventos.
- [ ] **Listar** (`GET /api/projects/PG/stories`): filtros `state`, `milestone` (título o `inbox`), `label` y `claimed_by`. Devuelve referencia, estado, título, hito y quién la tiene.
- [ ] **Decisiones** (`GET /api/projects/PG/decisions`): todas, de la más reciente a la más antigua, marcando las sustituidas.
- [ ] Cada respuesta trae `breadcrumbs` útiles. Por ejemplo, en **siguiente**: `mt start PG-49` y `mt show PG-47`.
- [ ] `bin/ci` en verde.

## Fuera de alcance

- "Commits relacionados" en `next` (la propuesta de `ARCHITECTURE.md`): no guardamos commits hasta `done` (#017). Se retoma cuando haya runs (M4).

## Notas para quien lo construya

- Los markdown salen de una clase por documento (`Api::Markdown::Context`, `::Roadmap`, `::Story`…), no de las vistas HTML. Así la UI y la API no se rompen la una a la otra.
- El formato de **ver** es el mismo que acepta la escritura (#018) con `--file`: lo que se lee se puede editar y devolver.

## Preguntas abiertas

## Cierre
