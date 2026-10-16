---
number: 13
title: Token text-control y estados en /design
milestone: M1
state: ready
claimed_by:
mockup: https://app.paper.design/file/01M50CA4S5CN4Z8ERVW36XWDHF/p-A-0
labels: [ui, sistema]
blocked_by: [1]
---

## Contexto

En el Cierre de la #001, Desarrollo dejó tres dudas sobre el sistema de diseño. Fran decidió el 2026-10-16:
- `--color-input-disabled` se borra de Paper. En el código nunca existió, así que no hay nada que quitar.
- El hover del primario es un token: `--color-accent-hover`. En código ya existe con ese nombre.
- El 13px pasa a token: `--text-control`.
- Los estados que Desarrollo inventó (foco blanco en los controles que no son el primario, y hover del fantasma y del nav item) se quedan como están y ya están dibujados en Paper.

Ver `docs/DESIGN.md` → Tipografía y Forma.

## Historia

Como agente que construye la UI, quiero que el 13px sea un token como los demás, para no escribir valores sueltos en cada componente.

## Criterios de aceptación

- [ ] `--text-control: 13px` existe junto al resto de variables de tipografía, y Tailwind lo expone como `text-control`, con interlineado de 16px.
- [ ] No queda ningún `text-[13px]` en `app/`: los cuatro usos actuales (`_field`, `_terminal`, la página `/design` y donde aparezcan en `components_helper.rb`) pasan a `text-control`. Si alguno usa otro interlineado, se mantiene con su clase `leading-*`.
- [ ] `/design` muestra el 13 en la escala de tipografía y los estados de `Sistema → 03 · Componentes`: foco del secundario y del fantasma, hover del fantasma y hover del nav item.
- [ ] `bin/ci` en verde.

## Fuera de alcance

- Cambiar cualquier otro valor del sistema.
- Las piezas nuevas de las pantallas (tarjeta, fila, menú…): las construyen las historias #007–#011.

## Notas para quien lo construya

- Es una historia corta. Puede ir antes o después de la #012.

## Preguntas abiertas

## Cierre
