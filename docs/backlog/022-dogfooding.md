---
number: 22
title: Maker Tracker se gestiona en Maker Tracker
milestone: M2
state: defining
claimed_by:
mockup:
labels: [agentes]
blocked_by: [19, 21]
---

## Contexto

El objetivo de M2 es que, a partir de aquí, Maker Tracker se construya con Maker Tracker. El backlog vive en `docs/backlog/*.md` y el orden en `docs/ROADMAP.md`. El formato de esas historias (frontmatter + markdown) es a propósito el mismo que acepta `mt create --file`, así que migrar es crear cada historia desde su fichero.

## Historia

Como Fran, quiero el roadmap y el backlog de Maker Tracker dentro de mi Maker Tracker de la torre, para que los agentes de las tres vertientes trabajen con `mt next` y no con ficheros.

## Criterios de aceptación

- [ ] Proyecto **Maker Tracker** (`MT`) creado por Fran en la torre, con el brief escrito a partir de `PRODUCT.md` (visión, principios, no-objetivos y glosario).
- [ ] Los hitos M1–M4 y "Después", en orden y con su objetivo, como en `ROADMAP.md`.
- [ ] Cada `docs/backlog/NNN-*.md` creado con `mt create --file`, conservando su número (`MT-14` es la #014), estado, labels, bloqueos y su Cierre. Las hechas, como Hechas.
- [ ] El repo tiene `.mt` (`project: MT`) y la skill y el hook de la #020.
- [ ] `docs/backlog/` se queda con un README que apunta a la app, y `docs/ROADMAP.md` pasa a ser un enlace a `mt roadmap`. Los ficheros de historias se borran (están en git).
- [ ] Las tres vertientes cambian sus instrucciones (`docs/workstreams/`) a `mt`.

## Fuera de alcance

- Migrar los backlogs de Notion.
- La documentación (`PRODUCT.md`, `DESIGN.md`, `ARCHITECTURE.md`, `workstreams/`): sigue en el repo con el mismo flujo de commits por vertiente (decisión de Fran del 2026-10-16). Solo se mueven el backlog y el roadmap.

## Notas para quien lo construya

- Lo hace la vertiente de Producto con `mt`, con el OK de Fran.

## Preguntas abiertas

- Las decisiones de `PRODUCT.md`, ¿se pasan a `Decision` (`D-1`…) o se quedan en el documento y solo las nuevas van a la app?
- ¿Conservar el número de la historia exige que `create` acepte `number`? Hoy la API no lo permite. Alternativa: aceptar que MT empiece en 1 en el orden actual.

## Cierre
