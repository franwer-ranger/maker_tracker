---
number: 1
title: Sistema de diseño v3 en código
milestone: M1
state: ready
claimed_by:
---

## Qué

Llevar el sistema de diseño v3 (`docs/DESIGN.md`, Paper → `v3 · Sistema`) al código, como base de toda la UI de la v2: tokens, fuentes, iconos y una primera tanda de componentes reutilizables.

## Por qué

La UI actual no tiene sistema: Inter, Font Awesome por CDN y clases sueltas. Todas las pantallas de M1 (Roadmap, Historia, Brief) se van a construir encima de esto. Hacerlo primero evita rehacerlas después, y no depende de ninguna decisión de producto pendiente.

## Criterios de aceptación

- [ ] Los tokens de color, espaciado, radios y tamaños de `DESIGN.md` existen como variables CSS (`--color-accent`, …) y Tailwind los expone en su tema (p. ej. `bg-accent`, `text-muted`, `border-strong`, `rounded-md`, `font-display`), con los mismos nombres que en Paper.
- [ ] Geist, Geist Mono e Instrument Serif se sirven desde la propia app (sin CDN de terceros: la app vive en una red privada). Inter desaparece.
- [ ] Font Awesome desaparece del layout. Hay un helper (`icon "arrow-right"`) que pinta iconos Lucide como SVG en línea, con trazo 1.5, tamaño configurable y color heredado del texto. Solo se incluyen los iconos que se usan.
- [ ] Componentes como partials o helpers propios, con sus variantes y estados de `03 · Componentes`: botón (primario, secundario, fantasma, desactivado, pequeño), nav item, punto de estado, selector de estado, input con label y ayuda, actor (`claude en #48`) y bloque de terminal.
- [ ] Una página interna de desarrollo (p. ej. `/design`, solo en development) muestra todos los componentes, para revisarlos contra Paper.
- [ ] El layout usa fondo `--color-bg`, Geist como fuente base y texto `--color-text`. Las pantallas v1 pueden verse raras: no se rediseñan aquí.
- [ ] Texto negro sobre el botón naranja, foco visible en todos los controles y hover según Paper.
- [ ] `bin/ci` en verde.

## Notas para quien lo construya

- Tailwind es v3 (`tailwindcss-rails` 3.x, `config/tailwind.config.js`, `app/assets/stylesheets/application.tailwind.css`). No migres a v4 en esta historia.
- Valores exactos desde Paper con `get_computed_styles` / `get_jsx` sobre los nodos de `03 · Componentes`; no midas a ojo.
- Componentes al estilo de shadcn: código propio y pequeño en el repo, sin gemas de componentes. Si `view_component` te parece claramente mejor que partials, propónlo antes en el inbox.
- Fuera de alcance: rediseñar pantallas v1, la landing (es de Self-host) y el modo claro.

## Mockups

Paper → `v3 · Sistema` → `01 · Tipografía`, `02 · Color y forma`, `03 · Componentes`.

## Cierre
