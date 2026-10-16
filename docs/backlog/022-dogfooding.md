---
number: 22
title: Maker Tracker se gestiona en Maker Tracker
milestone: M2
state: ready
claimed_by:
mockup:
labels: [agentes]
blocked_by: [21, 24, 25]
---

## Contexto

El objetivo de M2 es que, a partir de aquí, Maker Tracker se construya con Maker Tracker. El backlog vive en `docs/backlog/*.md` y el orden en `docs/ROADMAP.md`. El formato de esas historias (frontmatter + markdown) es a propósito el mismo que acepta `mt create --file`, así que migrar es crear cada historia desde su fichero.

## Historia

Como Fran, quiero el roadmap y el backlog de Maker Tracker dentro de mi Maker Tracker de la torre, para que los agentes de las tres vertientes trabajen con `mt next` y no con ficheros.

## Criterios de aceptación

- [ ] Proyecto **Maker Tracker** (`MT`) creado por Fran en la torre, con el brief escrito a partir de `PRODUCT.md` (visión, principios, no-objetivos y glosario).
- [ ] Los hitos M1–M4 y "Después", en orden y con su objetivo, como en `ROADMAP.md`.
- [ ] Cada `docs/backlog/NNN-*.md` creado con `mt create --file`, **conservando su número** (`MT-14` es la #014, decisión de Fran del 2026-10-16), estado, labels, bloqueos y su Cierre. Las hechas, como Hechas. La siguiente historia nueva es `MT-24` (o la que siga a la última).
- [ ] **Las decisiones de `PRODUCT.md` se mueven a la app** (decisión de Fran del 2026-10-16), con `mt decide`, de la más antigua a la más reciente: primero "Anteriores" y después cada bloque por fecha. Una viñeta es una decisión: el título es la frase en negrita y el porqué, el resto. Las que sustituyeron a otra (Heroicons a Lucide, Instrument Serif a Apple Garamond…) se registran con `--supersedes`.
- [ ] `PRODUCT.md` → Decisiones se sustituye por una línea que enlaza a `mt decisions`. El documento se queda con la visión, cómo trabajo, los principios, el ecosistema, los no-objetivos y las preguntas abiertas.
- [ ] El repo tiene `.mt` (`project: MT`) y la skill y el hook de la #020.
- [ ] `docs/backlog/` se queda con un README que apunta a la app, y `docs/ROADMAP.md` pasa a ser un enlace a `mt roadmap`. Los ficheros de historias se borran (están en git).
- [ ] Las tres vertientes cambian sus instrucciones (`docs/workstreams/`) a `mt`.

## Fuera de alcance

- Migrar los backlogs de Notion.
- La documentación (`PRODUCT.md`, `DESIGN.md`, `ARCHITECTURE.md`, `workstreams/`): sigue en el repo con el mismo flujo de commits por vertiente (decisión de Fran del 2026-10-16). Solo se mueven el backlog y el roadmap.

## Notas para quien lo construya

- Lo hace la vertiente de Producto con `mt`, con el OK de Fran.
- Las decisiones migradas llevan fecha de hoy (la API no acepta fechas pasadas). Si la viñeta tenía fecha, se pone al final del porqué: "(decidida el 2026-10-16)".
- Las referencias antiguas (#014, "ver PRODUCT.md → Decisiones") en commits y Cierres no se reescriben: los números se conservan y `PRODUCT.md` enlaza a la app.

## Preguntas abiertas


## Cierre
