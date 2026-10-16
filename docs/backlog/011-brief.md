---
number: 11
title: Brief · visión y decisiones del proyecto
milestone: M1
state: done
claimed_by: development
mockup: https://app.paper.design/file/01M50CA4S5CN4Z8ERVW36XWDHF/p-C-0
labels: [ui]
blocked_by: [7]
---

## Contexto

El brief es el contexto del proyecto: lo primero que lee cualquier agente (en M2, con `mt context`). Es un único markdown (visión, principios, fuera de alcance, glosario). Al lado están las decisiones, que solo se añaden.

## Historia

Como Fran, quiero escribir la visión del proyecto y registrar sus decisiones con su porqué, para que cualquier agente arranque sabiendo qué buscamos y qué está decidido.

## Criterios de aceptación

- [ ] Título "Brief" en Instrument Serif y la línea "Lo primero que lee cualquier agente que trabaje en Postgram · editado hace 3 días" (fecha del último `brief.edited`).
- [ ] Brief renderizado. Para editarlo, textarea con vista previa; guardar llama a `Project#edit_brief!`.
- [ ] Columna de **Decisiones** (`DECISIONES · 14`), de la más reciente a la más antigua: `D-14` en mono, fecha, título, "Por qué: …" y "Vinculada a #48" con enlace si tiene historia. Las sustituidas aparecen atenuadas, con "Sustituida por D-n".
- [ ] "+ Decisión" pide título, porqué, historia (opcional) y a cuál sustituye (opcional). Se guarda como Fran y no se puede editar después.
- [ ] Coincide con `5.5`. La decisión más reciente va sobre `surface` con borde `border-strong` y las demás solo con borde. Cada decisión muestra su actor y su fecha. Las sustituidas llevan borde discontinuo, título tachado y "sustituida por D-n".
- [ ] `bin/ci` en verde.

## Fuera de alcance

- Varios documentos por proyecto (decisión: un único brief).
- Editar o borrar decisiones: no se puede, por diseño.

## Mockups

Paper → `App` → `5.5 Brief`.

## Preguntas abiertas


## Cierre

Rama `dev/m1-screens`, commit «Añade el Brief y las decisiones».

**Hecho**
- `/p/:slug/brief`, como en `5.5`: «Brief» en Instrument Serif, «Lo primero que lee cualquier agente que trabaje en Postgram · editado hace 3 días» (último `brief.edited`) y el brief pintado en la variante documento (`markdown markdown-doc`: los `##` son titulares y las listas van con raya).
- Editar (`/brief/edit`) con el mismo editor de la Historia, que ahora es un componente (`components/_markdown_editor`, también en `/design`). Guardar llama a `Project#edit_brief!`.
- Columna de decisiones (`DECISIONES · 14`, el último número asignado), de la más reciente a la más antigua:
  - la primera, sobre `surface` con borde `border-strong`; las demás, solo con borde;
  - cada una con actor y fecha, «Por qué: …», «Vinculada a #48» con enlace y «Sustituye a D-9»;
  - las sustituidas, con borde discontinuo, título tachado y «sustituida por D-12».
- «+ Decisión» abre un panel con título, porqué, historia (número, opcional) y a cuál sustituye (opcional). Se registra como fran con `Project#record_decision!` y no se puede editar después.
- Comprobado en Chrome headless: editar el brief deja `brief.edited` y la cabecera pasa a «editado hace 1 min». Registrar D-15 ligada a #48 y sustituyendo a D-14 deja `decision.recorded`, D-15 queda de solo lectura y D-14 sale tachada. Captura contra `5.5`.

**Decisiones**
- El cuerpo de una decisión se pinta tras «Por qué:» tal cual está escrito. Las seeds lo escriben en minúscula, como en Paper. Pasarlo a minúscula en la vista estropeaba los nombres propios («prawn»).
- Las seeds añaden un `brief.edited` de hace 3 días para que la cabecera coincida con `5.5`.
