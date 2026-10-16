---
number: 24
title: La salida de mt y de la API, como en docs/CLI.md
milestone: M2
state: ready
claimed_by:
mockup: https://app.paper.design/file/01M50CA4S5CN4Z8ERVW36XWDHF/p-C-0
labels: [api, cli]
blocked_by: [20]
---

## Contexto

La #015–#020 se construyeron antes de que existiera `docs/CLI.md` (2026-10-16). Desde entonces Fran decidió que **todo lo que habla con máquinas va en inglés** (salida de `mt`, mensajes de la API, la skill) y el contenido, en el idioma en que se escribió. `docs/CLI.md` fija además el formato de cada comando, con ejemplos sobre las seeds. Hoy la API y `mt` responden en español ("Elige otra con mt next…", "_Ninguna historia con esos filtros._") y con su propio formato.

## Historia

Como agente, quiero que `mt` y la API hablen en inglés y con el formato de `docs/CLI.md`, para leer lo mismo en cualquier proyecto y que lo que está documentado sea lo que pasa.

## Criterios de aceptación

- [ ] Todo lo que pone la herramienta va en inglés: `summary`, `message`, `hint`, `warnings`, los textos de `data.markdown` que no son contenido (`## Comments`, `## History`, `Why this one:`, `Goal:`…), la ayuda de `mt` y la skill de la #020. Los títulos, cuerpos, brief y decisiones salen tal cual.
- [ ] Las excepciones de dominio, que están en español para la UI, se traducen al pasar por la API.
- [ ] Con las seeds, `mt context`, `mt next`, `mt show PG-49`, `mt roadmap`, `mt list --state ready`, `mt decisions` y los ejemplos de "Escribir" dan **exactamente** lo de `docs/CLI.md` (salvo horas y fechas que dependen de cuándo se siembra).
- [ ] Reglas comunes de `docs/CLI.md`: fechas absolutas, `Warning:` y `Next:` al final, errores en dos líneas (`Error:` / `Hint:`) por stderr, la marca `<!-- mt: read-only below this line; mt edit ignores it -->` en `show` y `next`, y `mt edit --file` ignora lo que hay debajo.
- [ ] `bin/ci` en verde.

## Fuera de alcance

- La UI: sigue en español.
- Comandos nuevos.

## Notas para quien lo construya

- Si algo de `docs/CLI.md` no se puede hacer o queda peor en la práctica, no lo cambies por tu cuenta: déjalo en el inbox para Producto. El documento manda, pero se puede corregir.
- Paper → `App` → `6.0 Agente · mt next y mt roadmap` tiene dos salidas dibujadas en terminal.

## Preguntas abiertas

## Cierre
