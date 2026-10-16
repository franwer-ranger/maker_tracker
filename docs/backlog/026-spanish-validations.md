---
number: 26
title: Mensajes de validación en castellano en la UI
milestone: M2
state: done
claimed_by: development
mockup:
labels: [ui]
blocked_by: []
---

## Contexto

Desarrollo avisó al cerrar M2 de que los mensajes de validación de Rails salen en inglés ("Title can't be blank") en la UI y en la API, porque no hay locale `es`. La UI va en castellano y la API en inglés (decisión de Fran del 2026-10-16, ver `docs/CLI.md` → Idioma).

## Historia

Como Fran, quiero que los errores de los formularios estén en castellano, como el resto de la app.

## Criterios de aceptación

- [x] La UI usa el locale `es`: mensajes de validación y nombres de atributos en castellano ("El título no puede estar vacío").
- [x] La API sigue respondiendo en inglés (fuerza `en` en `/api`).
- [x] Probado al crear un proyecto sin nombre, una historia sin título y una decisión sin título.
- [x] `bin/ci` en verde.

## Fuera de alcance

- Traducir la app a otros idiomas o hacerla multilingüe.

## Notas para quien lo construya

- Basta con un `config/locales/es.yml` con lo que usa la app; si prefieres la gema `rails-i18n`, que no añada más de lo necesario.

## Preguntas abiertas

## Cierre

Commit «Pasa a castellano los mensajes de validación de la UI» en `dev/m2-cli-output`.

- `config.i18n.default_locale = :es`. `config/locales/es.yml` lleva solo lo que usa la app: los mensajes de Rails que salen (`blank`, `taken`, `invalid`, `inclusion`, `required`), los propios de los modelos (claves desde la #024) y los nombres de los atributos con su artículo («El título», «La clave»), para que se lea «El título no puede estar vacío». Las excepciones femeninas («La clave no puede estar vacía») van por atributo. Sin la gema `rails-i18n`.
- La API fuerza `en` envolviendo `process_action` en `Api::BaseController`. Un `around_action` no basta, porque los `rescue_from` (que construyen el mensaje de `VALIDATION_FAILED`) se ejecutan fuera de él.
- Probado en la UI: proyecto sin nombre («El nombre no puede estar vacío»), historia sin título («El título no puede estar vacío») y decisión sin título (lo mismo). En la API, los mismos casos dan «Title can't be blank.». La UI sigue en castellano después de una llamada a la API.
- De paso: `mt edit --file` con un fichero sin cuerpo daba `INTERNAL`. Ahora el cuerpo queda vacío y valida como siempre (`Api::StoryDocument`).
- Fuera: el aviso «El slug no puede estar vacío» se añade a los errores de un proyecto sin nombre, pero la pantalla de proyectos enseña los errores campo a campo, así que no se ve.
