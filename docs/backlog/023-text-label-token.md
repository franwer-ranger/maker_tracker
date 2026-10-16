---
number: 23
title: Token text-label
milestone: M2
state: ready
claimed_by:
mockup: https://app.paper.design/file/01M50CA4S5CN4Z8ERVW36XWDHF/p-A-0
labels: [ui, sistema]
blocked_by: []
---

## Contexto

Desarrollo preguntó en el inbox (#008) si el 11px de las labels pasa a token. Fran decidió el 2026-10-16 que sí: `--text-label`, solo para las labels de historia. Ya está en Paper y en `DESIGN.md` → Tipografía.

## Historia

Como agente que construye la UI, quiero que el 11px de las labels sea un token, para no dejar ningún tamaño suelto en el código.

## Criterios de aceptación

- [ ] `--text-label: 11px` existe junto al resto de variables de tipografía, y Tailwind lo expone como `text-label` con interlineado de 14px.
- [ ] `ui_label` usa `text-label` y no queda ningún `text-[11px]` en `app/`.
- [ ] `/design` muestra el 11 en la escala de tipografía.
- [ ] `bin/ci` en verde.

## Fuera de alcance

- Cualquier otro cambio de las labels.

## Notas para quien lo construya

- Es la misma operación que la #013 con `text-control`.

## Preguntas abiertas

## Cierre
