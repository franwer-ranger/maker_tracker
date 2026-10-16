---
number: 11
title: Brief · visión y decisiones del proyecto
milestone: M1
state: defining
claimed_by:
mockup: https://app.paper.design/file/01M50CA4S5CN4Z8ERVW36XWDHF/p-8-0
labels: [ui]
blocked_by: [7]
---

## Contexto

El brief es el contexto del proyecto: lo primero que lee cualquier agente (en M2, con `mt context`). Es un único markdown (visión, principios, fuera de alcance, glosario). Al lado están las decisiones, que solo se añaden. Artboard v2: `4.6 Brief`.

## Historia

Como Fran, quiero escribir la visión del proyecto y registrar sus decisiones con su porqué, para que cualquier agente arranque sabiendo qué buscamos y qué está decidido.

## Criterios de aceptación

- [ ] Título "Brief" en Instrument Serif y la línea "Lo primero que lee cualquier agente que trabaje en Postgram · editado hace 3 días" (fecha del último `brief.edited`).
- [ ] Brief renderizado. Para editarlo, textarea con vista previa; guardar llama a `Project#edit_brief!`.
- [ ] Columna de **Decisiones** (`DECISIONES · 14`), de la más reciente a la más antigua: `D-14` en mono, fecha, título, "Por qué: …" y "Vinculada a #48" con enlace si tiene historia. Las sustituidas aparecen atenuadas, con "Sustituida por D-n".
- [ ] "+ Decisión" pide título, porqué, historia (opcional) y a cuál sustituye (opcional). Se guarda como Fran y no se puede editar después.
- [ ] `bin/ci` en verde.

## Fuera de alcance

- Varios documentos por proyecto (decisión: un único brief).
- Editar o borrar decisiones: no se puede, por diseño.

## Preguntas abiertas

- Mockup v3 pendiente (Producto, tarea 3): `4.6 Brief` pasado a v3.

## Cierre
