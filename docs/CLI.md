# Salida de `mt`

> Lo que ve un agente al usar `mt`. Es la "pantalla" de los agentes: se diseña con el mismo cuidado que una pantalla de la app. Los ejemplos usan los datos de las seeds (Postgram) y son la referencia de las historias #016 (API · leer) y #019 (CLI `mt`). Si cambia el formato, se cambia aquí primero. En Paper: `App` → `6.0 Agente · mt next y mt roadmap`.

## Idioma

**Todo lo que pone la herramienta va en inglés**: mensajes, avisos, errores, `Next:`, nombres de sección (`## Comments`), estados, claves del frontmatter y del JSON, comandos y flags. Es comunicación entre sistemas, como los nombres de tablas o el código (decisión de Fran del 2026-10-16).

**El contenido va en el idioma en que se escribió**: títulos, cuerpo de las historias (con los encabezados de su plantilla), brief y decisiones salen tal cual. En Postgram, en español.

La app sigue en español. Si enseña un comando o una clave (`mt next`, `ready`), va en inglés.

## Reglas

1. **Markdown compacto.** Titulares `#`/`##`, listas y columnas alineadas con espacios. Nada de tablas markdown (en la terminal son ruido), colores ni emojis. Se lee igual en la terminal de Fran que dentro de un agente.
2. **Primero lo que se busca.** La primera línea dice qué es y en qué estado está. El contexto viene después.
3. **Referencias siempre completas:** `PG-49`, `D-14`, `M2`. Así se pueden copiar a un commit o a otro comando.
4. **Fechas absolutas**, `2026-10-15 22:40` (y solo la hora si es de hoy). Un agente no sabe qué día es "ayer", y así puede compararlas con `git log`.
5. **Estados** en minúscula en la prosa (`ready`, `in progress`) y con su clave en el frontmatter (`ready`, `in_progress`), que es lo que acepta `mt`.
6. **El final es siempre igual:** primero los avisos (`Warning: …`), uno por línea, y después `Next:` con los comandos sugeridos (los `breadcrumbs` de la API), uno por línea y con sangría de dos espacios.
7. **Errores por stderr**, en dos líneas: `Error: …` y `Hint: …`. Salida con código 1, o 2 si el comando está mal escrito.
8. **`--json`** imprime el sobre de la API tal cual, sin nada más.
9. **Lo que se escribe se escribe corto:** `start`, `done`, `comment`… responden con una línea (el `summary`), los avisos y `Next:`.
10. **Frontmatter en YAML**, cuerpo en markdown. `mt` escribe con comillas los valores que lo necesiten (un `:` en el título, `no`, `on`…), y la API lee el YAML en modo seguro y solo acepta las claves conocidas.

## `mt context`

El onboarding del agente. Lo inyecta el hook `SessionStart`, así que tiene que caber en poco: brief entero, 5 decisiones vigentes, hito actual y lo que está en curso.

```markdown
# Postgram · PG

Project context. Brief last edited 2026-10-13 by fran.

## Visión

Postgram es el sitio donde un maker escribe una vez y publica en todas sus redes. Gana el que publica con constancia, no el que publica mejor; nuestro trabajo es quitar fricción hasta que publicar sea un hábito.

## Principios

- Menos de 10 minutos a la semana.
- Nada de dashboards que nadie mira: cada métrica sugiere una acción.
- Un solo editor; las redes se adaptan, el maker no.

## Fuera de alcance

Agencias y gestión de clientes. Generar contenido con IA por el usuario.

## Glosario

Post: lo que escribe el maker, una vez. Publicación: cada copia de un post en una red.

## Decisions in force

D-14  PDFs con Prawn, sin servicios externos
      Why: autoalojado y sin coste por documento. · claude · 2026-10-16 · PG-48
D-13  Publicar sin fricción va antes que Analítica
      Why: los usuarios beta lo piden primero. · fran · 2026-10-15
D-12  Imágenes en Active Storage local
      Why: un solo servidor; S3 cuando haga falta. · fran · 2026-10-02 · supersedes D-9

## Current milestone · M2 · Publicar sin fricción

Goal: Un maker programa una semana de posts en menos de 10 minutos.
4 of 12 done · 2 in progress · 2 ready · 2 defining · 2 ideas

## In progress

PG-48  Exportar post a PDF       claude  since 11:42
PG-45  Programar publicaciones   codex   since 2026-10-15 18:00

Next:
  mt next
  mt roadmap
```

- Las decisiones sustituidas no salen. Los objetivos de hito y los porqués son contenido: salen tal cual, sin cambiar mayúsculas. Si hay más de 5 vigentes, se añade `… and 8 more: mt decisions`.
- Sin hito abierto, `## Current milestone` dice `No open milestone.` y sugiere `mt roadmap`.

## `mt next`

La primera historia Lista y no bloqueada del primer hito abierto, entera, con una línea que explica por qué es esa. Lo que viene después de esa línea es exactamente `mt show`.

```markdown
Next up: PG-49 · Plantillas de post reutilizables
Why this one: first ready, unblocked story in M2. PG-48 and PG-45 come before it and are in progress.

---
number: 49
version: 3
title: Plantillas de post reutilizables
milestone: Publicar sin fricción
state: ready
claimed_by:
mockup: https://app.paper.design/file/01M50CA4S5CN4Z8ERVW36XWDHF/p-C-0
labels: [editor, ui]
blocked_by: [47]
---

## Contexto
Los makers repiten el mismo formato cada semana.

## Historia
Como maker que publica cada semana, quiero guardar un post como plantilla para no reescribir el mismo formato una y otra vez.

## Criterios de aceptación
- [ ] Desde un post publicado, «Guardar como plantilla» crea una plantilla con el texto y las imágenes.
- [ ] Al crear un post nuevo puedo elegir una plantilla y se rellena el editor.
- [ ] Las variables {fecha} y {enlace} se sustituyen al usar la plantilla.

## Fuera de alcance
Compartir plantillas entre cuentas (M4).

## Preguntas abiertas

<!-- mt: read-only below this line; mt edit ignores it -->

## Related

Blocked by PG-47 Borradores automáticos (done): no longer blocking.

## Comments · 1

claude · 2026-10-15 22:31
He añadido los criterios y enlazado el mockup. Variables solo {fecha} y {enlace}: el resto, en otra historia.

## History

2026-10-15 22:40  fran    moved to ready
2026-10-15 22:31  claude  edited body, mockup
2026-10-09 10:05  fran    moved to defining
2026-10-03 16:20  fran    created as idea

Next:
  mt start PG-49
  mt show PG-47
```

Si se salta alguna por bloqueo: `Why this one: first ready, unblocked story in M2. PG-50 comes first but is blocked by PG-46 (in progress).`

Si no hay ninguna en ningún hito abierto (error, por stderr; nombra todos los hitos abiertos):

```text
Error: no ready, unblocked story in M2, M3 or M4.
Hint: 2 stories are being defined (PG-51, PG-54). See them with mt list --state defining, or ask fran.
```

## `mt show PG-49`

Igual que `mt next` sin las dos primeras líneas. Arriba, lo que se puede editar (frontmatter y cuerpo); debajo de la marca `<!-- mt: … -->`, lo que es solo lectura. Así `mt show PG-49 > f.md`, editar `f.md` y `mt edit PG-49 --file f.md` funciona sin limpiar nada.

- `milestone` es el título del hito, sin el código (`M2`), porque el código cambia al reordenar. En la bandeja de ideas, vacío.
- `version` sube cada vez que alguien edita el contenido (título, cuerpo, mockup, labels, bloqueos). `mt edit` la manda de vuelta y, si ya no es la actual, no guarda nada (ver «Conflictos de edición»). Mover, reordenar o cerrar no la cambian.
- `state` y `milestone` se pueden leer, pero `mt edit` no los cambia: para eso están `mt move` y `mt reorder` (decisión de la #018).
- El historial muestra los 10 últimos eventos. Si un evento tiene motivo, va al final de su línea: `reordered it in its milestone: "lo pide la beta"`.
- `## Related` lista lo que la bloquea y lo que bloquea, cada una con su estado: `Blocked by PG-45 Programar publicaciones (in progress).` / `Blocks PG-54 Reprogramar arrastrando en el calendario (defining).`

## `mt roadmap`

Los hitos abiertos en orden, cada uno con sus historias en orden. Columnas fijas: estado (12), referencia (6), título (42) y metadato. El metadato es el mismo que en el Tablero y por el mismo orden de prioridad: quién la tiene, `← next`, `blocked by …`, `no criteria` o `mockup` (tiene mockup).

```markdown
# Roadmap · Postgram

## M2 · Publicar sin fricción · in progress · 4/12
Goal: Un maker programa una semana de posts en menos de 10 minutos.

in progress  PG-48  Exportar post a PDF                         claude
in progress  PG-45  Programar publicaciones                     codex
ready        PG-49  Plantillas de post reutilizables            ← next
ready        PG-50  Vista previa por red social                 mockup
defining     PG-51  Métricas de engagement                      no criteria
defining     PG-54  Reprogramar arrastrando en el calendario    blocked by PG-45
idea         PG-52  Hilos de X en un solo post
idea         PG-53  Programar desde el móvil
done         PG-47 PG-43 PG-42 PG-41

## M3 · Analítica para makers · 6 stories
Goal: Saber qué post funciona y por qué.

ready        PG-31  Exportar métricas a CSV
defining     PG-27  Panel de rendimiento por post               no criteria
defining     PG-28  Comparar redes                              blocked by PG-51
defining     PG-29  Resumen semanal por email                   no criteria
defining     PG-30  Mejores horas para publicar                 no criteria
idea         PG-32  Alertas cuando un post despega

## M4 · Equipos · 3 ideas
Goal: Varias personas publicando en la misma cuenta.

idea         PG-24  Invitar a otra persona a la cuenta
idea         PG-25  Roles: editor y publicador
idea         PG-26  Aprobar posts antes de publicar

## Inbox · 14 ideas

PG-10  Hilos de X desde un post largo
PG-11  Atajos de teclado en el editor
PG-12  Publicar en Bluesky
… and 11 more: mt list --milestone inbox

Closed: M1 · Cuentas y primer post (9/9, 2026-09-12). Show them with mt roadmap --closed.

Next:
  mt next
  mt show PG-49
```

- Las Hechas de un hito abierto van en una sola línea (en la app también van plegadas).
- La bandeja enseña las 3 primeras: es lo que menos importa al decidir qué hacer.
- Los anchos de columna son mínimos (título 42 en roadmap y `list`): si un título es más largo, la columna crece en ese listado y no se corta nada. Así se alinean las filas sin perder texto.

## `mt list`

Para buscar. Una línea por historia, con las mismas columnas que el roadmap más el hito. Sin `--state`, la primera columna es el estado.

```text
$ mt list --state ready
3 ready stories

PG-49  Plantillas de post reutilizables            M2  editor, ui
PG-50  Vista previa por red social                 M2  editor
PG-31  Exportar métricas a CSV                     M3  exportación
```

## `mt decisions`

```text
D-14  PDFs con Prawn, sin servicios externos           claude  2026-10-16  PG-48
      Why: autoalojado y sin coste por documento.
D-13  Publicar sin fricción va antes que Analítica     fran    2026-10-15
      Why: los usuarios beta lo piden primero.
D-12  Imágenes en Active Storage local                 fran    2026-10-02  supersedes D-9
      Why: un solo servidor; S3 cuando haga falta.
D-9   Imágenes en S3 desde el principio                fran    2026-09-16  superseded by D-12
      Why: para no migrar cuando crezca el número de imágenes.
```

## Escribir

Una línea con lo que ha pasado, los avisos y `Next:`. Con una historia con la label `ui` y sin mockup, `move … ready` añade también `Warning: it has the ui label but no mockup.`

```text
$ mt start PG-49
PG-49 is in progress, claimed by claude.

Next:
  mt show PG-49
  mt comment PG-49 "…"
  mt done PG-49 --commit <sha>
```

```text
$ mt start PG-51
PG-51 is in progress, claimed by claude.
Warning: PG-51 was still being defined; it may lack context.
Warning: it has no acceptance criteria.

Next:
  mt show PG-51
  mt release PG-51 --reason "…"
```

```text
$ mt done PG-49 --commit 4f3e2a1 --pr https://github.com/acme/postgram/pull/63
PG-49 done by claude, with 1 commit and PR #63.

Next:
  mt next
```

```text
$ mt move PG-52 ready
PG-52 moved to ready.
Warning: it has open questions.

Next:
  mt edit PG-52 --file <f.md>
  mt next
```

Crear un proyecto (#027). La clave tiene de 2 a 5 letras y da nombre a sus historias:

```text
$ mt project create "Postgram" --key PG
PG · Postgram created by claude.

Next:
  mt init PG --claude
  mt brief --file <f.md>
```

```text
$ mt project create "Postgram" --key PG
Error: project PG already exists.
Hint: pick another key, or use mt init PG if it is yours.
```

La skill de Maker Tracker se instala una vez, de forma global, para que un agente la tenga en cualquier carpeta (`$CLAUDE_CONFIG_DIR` si está definida). Repetirlo la actualiza (`… skill updated`) o dice `already up to date`. `mt init PG --claude` deja en el repo `.mt` y el hook `SessionStart`, y la skill solo si no está la global:

```text
$ mt skill install
/Users/fran/.claude/skills/maker-tracker/SKILL.md: maker-tracker skill installed

Next:
  mt init <KEY> --claude   (at the root of the project's repo)
```

Si la historia es de otro actor (aquí, lanzado como codex; si es tuya, `PG-48 was already in progress and is yours.`):

```text
$ mt start PG-48
Error: PG-48 is claimed by claude since 11:42.
Hint: pick another one with mt next, or ask fran to release it.
```

```text
$ mt reorder PG-50 --position 1
Error: reordering needs a reason.
Hint: mt reorder PG-50 --position 1 --reason "why it goes first"
```

## Conflictos de edición

Historias, brief y hitos llevan una versión (MT-37, decisión D-43: la protección está en la API; la UI nunca se bloquea). Se lee en `mt show` (`version:` del frontmatter), en `mt brief` (frontmatter `---\nversion: 3\n---` encima del texto) y en `mt milestone show M2`. `mt edit --file` y `mt brief --file` la mandan sin que el agente haga nada, porque ya va en el fichero; `mt milestone edit M2 --version 3 …` la lleva como opción. Si no se manda versión no se comprueba.

Si la versión no es la actual, la API responde `CONFLICT` (HTTP 409, no reintentable tal cual) y no guarda nada. Quién cambió y cuándo salen del último evento de edición:

```text
$ mt edit PG-49 --file f.md
Error: PG-49 changed since you read it: fran edited it at 10:42 (you had version 3, it is on 4). Nothing was saved.
Hint: Someone changed it (fran, 10:42). Read it again with mt show PG-49 and apply your changes on top.
```

El mismo error en `mt brief --file` (`Read it again with mt brief …`) y `mt milestone edit` (`… mt milestone show M2 …`). Con `--json`, `error.details` trae `expected_version` y `current_version`. `mt milestone show` imprime:

```text
$ mt milestone show M2
---
version: 3
code: M2
title: Publicar sin fricción
status: open
---

Un maker programa una semana de posts en menos de 10 minutos.
```
