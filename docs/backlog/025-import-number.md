---
number: 25
title: Crear una historia con un número dado
milestone: M2
state: done
claimed_by: development
mockup:
labels: [api]
blocked_by: [18]
---

## Contexto

Fran decidió el 2026-10-16 que, al migrar el backlog de Maker Tracker a la app (#022), cada historia **conserva su número**: la #014 pasa a ser `MT-14`. Así siguen valiendo las referencias de commits, Cierres y documentos. Hoy la API ignora `number` al crear.

## Historia

Como agente que migra un backlog, quiero crear una historia con su número de siempre, para que las referencias antiguas sigan apuntando a la misma historia.

## Criterios de aceptación

- [x] Crear historia (#018) acepta `number` opcional, como campo o en el frontmatter del `markdown`.
- [x] Si está libre, la historia lo usa. Si ya existe, error `VALIDATION_FAILED` con "PG-49 already exists".
- [x] Las historias nuevas siguen después del mayor número usado y nunca se reutiliza uno (`Project#reserve_number!` ya lo admite).
- [x] Editar sigue ignorando `number`.
- [x] `bin/ci` en verde.

## Fuera de alcance

- Fechas pasadas en historias o decisiones importadas.

## Notas para quien lo construya

## Preguntas abiertas

## Cierre

Commit «Permite crear una historia con un número dado» en `dev/m2-cli-output`.

- `POST /api/projects/:key/stories` acepta `number` como campo o como `number:` en el frontmatter, y `mt create` tiene `--number n`. Si se pasan los dos, manda el campo, como con el resto de opciones.
- Si el número está ocupado, la respuesta es `VALIDATION_FAILED` con «PG-49 already exists.» y como hint el siguiente número libre (`PG-102`). Un número que no es un entero positivo también da `VALIDATION_FAILED`.
- Las historias nuevas siguen después del mayor número usado, aunque el importado quede por debajo (un hueco como PG-35 no mueve el contador). Lo hace `Project#reserve_number!` sin cambios.
- Editar sigue ignorando `number`, y ahora `GET /api` lo dice.
- Ojo: `mt show PG-49 > f.md` y luego `mt create --file f.md` ya no crea una copia, porque el fichero lleva `number: 49` y da el error de arriba. Para copiar una historia hay que quitar esa línea.
- Probado sobre las seeds: con número libre, con número ocupado, con un hueco por debajo del mayor, desde fichero y editando con otro número.
