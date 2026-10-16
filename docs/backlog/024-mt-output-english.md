---
number: 24
title: La salida de mt y de la API, como en docs/CLI.md
milestone: M2
state: done
claimed_by: development
mockup: https://app.paper.design/file/01M50CA4S5CN4Z8ERVW36XWDHF/p-C-0
labels: [api, cli]
blocked_by: [20]
---

## Contexto

La #015–#020 se construyeron antes de que existiera `docs/CLI.md` (2026-10-16). Desde entonces Fran decidió que **todo lo que habla con máquinas va en inglés** (salida de `mt`, mensajes de la API, la skill) y el contenido, en el idioma en que se escribió. `docs/CLI.md` fija además el formato de cada comando, con ejemplos sobre las seeds. Hoy la API y `mt` responden en español ("Elige otra con mt next…", "_Ninguna historia con esos filtros._") y con su propio formato.

## Historia

Como agente, quiero que `mt` y la API hablen en inglés y con el formato de `docs/CLI.md`, para leer lo mismo en cualquier proyecto y que lo que está documentado sea lo que pasa.

## Criterios de aceptación

- [x] Todo lo que pone la herramienta va en inglés: `summary`, `message`, `hint`, `warnings`, los textos de `data.markdown` que no son contenido (`## Comments`, `## History`, `Why this one:`, `Goal:`…), la ayuda de `mt` y la skill de la #020. Los títulos, cuerpos, brief y decisiones salen tal cual.
- [x] Las excepciones de dominio, que están en español para la UI, se traducen al pasar por la API.
- [x] Con las seeds, `mt context`, `mt next`, `mt show PG-49`, `mt roadmap`, `mt list --state ready`, `mt decisions` y los ejemplos de "Escribir" dan **exactamente** lo de `docs/CLI.md` (salvo horas y fechas que dependen de cuándo se siembra).
- [x] Reglas comunes de `docs/CLI.md`: fechas absolutas, `Warning:` y `Next:` al final, errores en dos líneas (`Error:` / `Hint:`) por stderr, la marca `<!-- mt: read-only below this line; mt edit ignores it -->` en `show` y `next`, y `mt edit --file` ignora lo que hay debajo.
- [x] `bin/ci` en verde.

## Fuera de alcance

- La UI: sigue en español.
- Comandos nuevos.

## Notas para quien lo construya

- Si algo de `docs/CLI.md` no se puede hacer o queda peor en la práctica, no lo cambies por tu cuenta: déjalo en el inbox para Producto. El documento manda, pero se puede corregir.
- Paper → `App` → `6.0 Agente · mt next y mt roadmap` tiene dos salidas dibujadas en terminal.

## Preguntas abiertas

## Cierre

Commit «Pasa la salida de mt y de la API a inglés, como en docs/CLI.md» en `dev/m2-cli-output`.

- **Comprobado contra el documento** con un script que ejecuta cada ejemplo sobre las seeds recién sembradas y lo compara con el bloque de `docs/CLI.md`, quitando las horas: `context`, `next`, `show PG-49` (= `next` sin las dos primeras líneas), `roadmap`, `list --state ready`, `decisions` y los ejemplos de «Escribir» salen idénticos. Falta un `Warning:` de `mt move PG-52 ready` (PG-52 no tiene la label `ui` en las seeds) y `mt start PG-48` da ese error solo si lo lanza otro actor (codex), porque la PG-48 es de claude. Ambas cosas están en el inbox.
- **Presentadores** (`app/presenters/api/`): `Formatting#table` alinea columnas con dos espacios. Roadmap y `list`: estado 11, título 42 cortado con `…`. En `context` (En curso) y `decisions` el documento usa 24 y 47: los he puesto como anchos mínimos que crecen si un título es más largo, para no cortar. El historial en inglés sale de `Api::Markdown::EventSentence`, aparte del helper de la UI.
- **Excepciones de dominio**: `Story::ClaimedByOther` expone la historia y la API escribe su mensaje («PG-48 is claimed by claude since 11:42.»). `ReasonRequired` da como hint el comando entero (`mt reorder PG-50 --position 1 --reason "why it goes first"`). Los mensajes propios de los modelos pasan a claves de i18n en `config/locales/en.yml`. Los de castellano llegan con la #026.
- **Avisos de Lista**: `Story#readiness_problems` devuelve claves. La UI las sigue enseñando en castellano (`readiness_issues`) y la API, en inglés. `mt start` avisa también si no hay criterios (`Story#criteria?`).
- **Frontmatter**: `milestone` es el título del hito. Al leer, se aceptan las líneas de `mt next` antes del `---`, así que `mt next > f.md` y `mt edit --file f.md` también funcionan. Los valores `on`, `off`, `y` y `n` se escriben con comillas.
- **Objetivo** tras `Goal:` con la primera letra en minúscula, como hace la UI con «Objetivo:», salvo las siglas.
- **Seeds**: horas fijas en el historial de PG-49 (16:20 y 10:05), la PG-31 primera en M3, punto final en el objetivo de M3 y una pregunta abierta en el cuerpo de PG-52.
- **CLI**: `Warning:` justo después del resultado y `Next:` tras una línea en blanco. Errores en `Error:`/`Hint:` por stderr, también los propios de `mt` (los de uso salen con código 2). Ayuda, `setup`, `init`, el hook y la skill (`cli/skill/SKILL.md`), en inglés. Si un repo ya tiene el hook instalado, se queda con el `echo` antiguo: `mt init --claude` no lo reescribe.
- **Fuera**: `bin/rails mt:token` sigue en castellano. Es para Fran en el servidor, no para los agentes.
