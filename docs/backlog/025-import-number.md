---
number: 25
title: Crear una historia con un número dado
milestone: M2
state: ready
claimed_by:
mockup:
labels: [api]
blocked_by: [18]
---

## Contexto

Fran decidió el 2026-10-16 que, al migrar el backlog de Maker Tracker a la app (#022), cada historia **conserva su número**: la #014 pasa a ser `MT-14`. Así siguen valiendo las referencias de commits, Cierres y documentos. Hoy la API ignora `number` al crear.

## Historia

Como agente que migra un backlog, quiero crear una historia con su número de siempre, para que las referencias antiguas sigan apuntando a la misma historia.

## Criterios de aceptación

- [ ] Crear historia (#018) acepta `number` opcional, como campo o en el frontmatter del `markdown`.
- [ ] Si está libre, la historia lo usa. Si ya existe, error `VALIDATION_FAILED` con "PG-49 already exists".
- [ ] Las historias nuevas siguen después del mayor número usado y nunca se reutiliza uno (`Project#reserve_number!` ya lo admite).
- [ ] Editar sigue ignorando `number`.
- [ ] `bin/ci` en verde.

## Fuera de alcance

- Fechas pasadas en historias o decisiones importadas.

## Notas para quien lo construya

## Preguntas abiertas

## Cierre
