---
number: 23
title: Token text-label
milestone: M2
state: done
claimed_by: development
mockup: https://app.paper.design/file/01M50CA4S5CN4Z8ERVW36XWDHF/p-A-0
labels: [ui, sistema]
blocked_by: []
---

## Contexto

Desarrollo preguntó en el inbox (#008) si el 11px de las labels pasa a token. Fran decidió el 2026-10-16 que sí: `--text-label`, solo para las labels de historia. Ya está en Paper y en `DESIGN.md` → Tipografía.

## Historia

Como agente que construye la UI, quiero que el 11px de las labels sea un token, para no dejar ningún tamaño suelto en el código.

## Criterios de aceptación

- [x] `--text-label: 11px` existe junto al resto de variables de tipografía, y Tailwind lo expone como `text-label` con interlineado de 14px.
- [x] `ui_label` usa `text-label` y no queda ningún `text-[11px]` en `app/`.
- [x] `/design` muestra el 11 en la escala de tipografía.
- [x] `bin/ci` en verde.

## Fuera de alcance

- Cualquier otro cambio de las labels.

## Notas para quien lo construya

- Es la misma operación que la #013 con `text-control`.

## Preguntas abiertas

## Cierre

Rama `dev/m2-api`, commit «Añade el token text-label».

**Hecho**
- `--text-label: 11px` está en `application.tailwind.css`, y Tailwind lo expone como `text-label` con interlineado de 14px.
- `ui_label` usa `text-label`. No queda ningún `text-[11px]` en `app/`.
- `/design` enseña el 11 en la columna Máquina, con una label de ejemplo y el texto «11 · text-label, solo labels», como el nodo de `01 · Tipografía` en Paper.

**Decisiones**
- Ninguna: misma operación que la #013.
