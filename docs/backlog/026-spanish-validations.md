---
number: 26
title: Mensajes de validación en castellano en la UI
milestone: M2
state: ready
claimed_by:
mockup:
labels: [ui]
blocked_by: []
---

## Contexto

Desarrollo avisó al cerrar M2 de que los mensajes de validación de Rails salen en inglés ("Title can't be blank") en la UI y en la API, porque no hay locale `es`. La UI va en castellano y la API en inglés (decisión de Fran del 2026-10-16, ver `docs/CLI.md` → Idioma).

## Historia

Como Fran, quiero que los errores de los formularios estén en castellano, como el resto de la app.

## Criterios de aceptación

- [ ] La UI usa el locale `es`: mensajes de validación y nombres de atributos en castellano ("El título no puede estar vacío").
- [ ] La API sigue respondiendo en inglés (fuerza `en` en `/api`).
- [ ] Probado al crear un proyecto sin nombre, una historia sin título y una decisión sin título.
- [ ] `bin/ci` en verde.

## Fuera de alcance

- Traducir la app a otros idiomas o hacerla multilingüe.

## Notas para quien lo construya

- Basta con un `config/locales/es.yml` con lo que usa la app; si prefieres la gema `rails-i18n`, que no añada más de lo necesario.

## Preguntas abiertas

## Cierre
