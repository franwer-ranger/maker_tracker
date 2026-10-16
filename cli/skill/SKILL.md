---
name: maker-tracker
description: Cómo trabajar con Maker Tracker desde este repo con el CLI mt. Úsala cuando pregunten «¿qué es lo siguiente?», al coger, construir o cerrar una historia, al dejar una duda o una decisión, y al escribir o reordenar el backlog (historias, hitos, brief).
---

# Maker Tracker con `mt`

Maker Tracker guarda la definición del producto de este repo: brief, decisiones, roadmap (hitos en orden) e historias. El código vive aquí; el qué y el porqué, allí. `mt` habla con su API. El proyecto sale de `.mt` en la raíz del repo, y las historias se citan como `PG-49` o solo `49`.

Al empezar la sesión ya tienes el resultado de `mt context` (brief, últimas decisiones, hito actual y lo que está en curso). Si no está, ejecútalo antes de recomendar nada: las decisiones y los principios del brief mandan.

## Cómo leer las respuestas

- Cada comando imprime el resultado y, al final, **«Siguiente:»**: los comandos que tiene sentido ejecutar después. Úsalos en lugar de adivinar.
- **«Avisos:»** no bloquean, pero hay que leerlos: una historia sin contexto, bloqueada, sin commits… Si un aviso cambia lo que vas a hacer, dilo.
- Un error trae su código y cómo arreglarlo (la línea de debajo). Sigue esa pista antes de probar otra cosa.
- `--json` da el sobre de la API tal cual, si necesitas los datos estructurados.

## El ciclo de desarrollo

1. **«¿Qué es lo siguiente?»** → `mt next`. Te da la primera historia Lista y no bloqueada del roadmap, entera y con el motivo. No elijas otra por tu cuenta salvo que te lo pidan.
2. `mt start PG-49`: la reclama a tu nombre y la pasa a En curso. Si es de otro (`CLAIMED_BY_OTHER`), coge otra.
3. Lee la historia entera (`mt show PG-49`): contexto, criterios de aceptación, fuera de alcance, notas y el mockup si lo tiene. Constrúyela en este repo cumpliendo cada criterio.
4. `mt done PG-49 --commit <sha> [--commit <sha>…] [--pr <url>]`: la cierra enlazando el código. Sin commits ni PR nadie sabrá dónde está.

Una historia se hace entera o no se cierra. Si al terminar queda algo fuera, dilo en un comentario antes de `mt done`.

## Dudas y bloqueos

- Pregunta en la historia: `mt comment PG-49 "…"` (markdown; `-` lee de stdin). Es donde la persona que define el producto lo ve, no en el chat.
- Si la duda te bloquea, suéltala y sigue con otra: `mt release PG-49 --reason "Falta decidir …"` y `mt next`.
- No inventes alcance para desbloquearte.

## Decisiones

Registra una decisión cuando elijas entre opciones que alguien querría conocer después (una librería, un formato, un límite, algo que queda fuera): `mt decide "Plantillas en JSON" --why "…" --story PG-49`. Si sustituye a otra, `--supersedes D-9`. Las decisiones no se editan: para cambiar una, escribe otra que la sustituya. Los detalles de implementación que no cambian el producto van en el comentario de cierre, no aquí.

## Escribir producto

Los agentes también escriben el backlog, directamente y con registro (cada cambio queda a tu nombre):

- **Crear**: `mt create "Título" [--milestone M2] [--state defining]`, o con un fichero: `mt create --file f.md`. Sin hito va a la bandeja de ideas; sin estado, nace como Idea.
- **Editar**: `mt show PG-49 > f.md`, cambia el fichero y `mt edit PG-49 --file f.md`. Lo que va tras la marca de solo lectura (comentarios, historial) se ignora. El estado y el hito no se cambian editando.
- **Plantilla** del cuerpo: `## Contexto` (por qué y qué existe ya) · `## Historia` (Como…, quiero…, para…) · `## Criterios de aceptación` (`- [ ] …`, comprobables) · `## Fuera de alcance` · `## Notas para quien lo construya` · `## Preguntas abiertas`.
- **Estado**: `mt move PG-49 ready` solo si no tiene preguntas abiertas y, si es de UI (label `ui`), tiene mockup. Si `mt` avisa de que no cumple la regla, vuelve a Definiendo o arréglalo.
- **Orden**: el orden es la prioridad. `mt reorder PG-49 --position 1 [--milestone M3] --reason "…"` y `mt milestone reorder M3 --position 2 --reason "…"`. **Siempre con motivo**: es lo que se lee después. Si el cambio es importante, regístralo además con `mt decide`.
- **Hitos y brief**: `mt milestone create|edit|close|reopen`, `mt brief` para leerlo y `mt brief --file f.md` para sustituirlo.

## Comandos

| Leer | Trabajar | Definir |
|---|---|---|
| `mt context` · `mt next` · `mt roadmap [--closed]` · `mt show PG-49` · `mt list [--state …] [--milestone …] [--label …] [--mine]` · `mt decisions` | `mt start` · `mt done --commit` · `mt release --reason` · `mt comment` · `mt decide --why` | `mt create` · `mt edit --file` · `mt move` · `mt reorder --reason` · `mt brief` · `mt milestone …` |

`mt help` y `mt <comando> --help` tienen el detalle y un ejemplo de cada uno.
