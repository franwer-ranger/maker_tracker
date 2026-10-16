---
number: 1
title: Sistema de diseño v3 en código
milestone: M1
state: done
claimed_by: development
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

Rama `dev/design-system`, commit «Añade el sistema de diseño v3 en código».

**Hecho**
- Tokens de Paper (`get_tokens`, hash `c0891b85`) como variables CSS en `app/assets/stylesheets/application.tailwind.css` y expuestos en `config/tailwind.config.js` con los mismos nombres: `bg-accent`, `bg-surface-sunken`, `text-muted`/`text-text-muted`, `text-soft`, `text-subtle`, `border` (por defecto) y `border-strong`, `bg-state-*`, `rounded-sm|md|lg|xl`, `font-sans|mono|display`, `text-xs…3xl` y `text-display-sm|display|display-lg` con su interlineado y tracking de `01 · Tipografía`. Alturas de control: `h-control-sm|nav|control|control-lg`. Curva `ease-brand`.
- Fuentes servidas por la app (`app/assets/fonts/`, `fonts.css`): Geist y Geist Mono variables (npm `geist` 1.5.1) e Instrument Serif 400 latin (`@fontsource/instrument-serif` 5.2.8). Licencias en `vendor/licenses/`. Inter y Font Awesome fuera de los tres layouts.
- **Iconos: Heroicons, no Lucide** (decisión de Fran durante la historia; ver inbox). Helper `icon "arrow-right", size: 16` en `app/helpers/icons_helper.rb`: SVG outline en línea, trazo 1.5, `currentColor`, `aria-hidden` salvo que se pase `aria: { label: }`. Solo están los que se usan, en `app/assets/icons/`: `arrow-right`, `arrow-top-right-on-square`, `cog-6-tooth`, `document-duplicate`, `plus`.
- Componentes en `app/helpers/components_helper.rb` y `app/views/components/`: `ui_button` (primario, secundario, fantasma, desactivado; tamaños `:md` 40 y `:sm` 32; con `href` es enlace), `nav_item`, `state_dot`, `state_selector` (radios, sirve en cualquier formulario), `ui_field` (label, input y ayuda, con o sin form builder), `actor`, `meta_line`, `section_label` y `terminal` (con copiar, `clipboard_controller.js`).
- `/design` (solo development) con tipografía, color, estados, radios, iconos y todos los componentes.

**Decisiones de implementación**
- Helpers + partials, sin `view_component`: con estas piezas no hace falta.
- El espaciado de Paper (base 4) coincide con la escala de Tailwind, así que no se redefine.
- `color-mix` de Paper (`color-mix(var(--x) 25%, transparent)`) se escribe con espacio de color (`in srgb`), que es lo que exige CSS.
- Hover del primario `#FF5A24`: en Paper es un valor suelto; aquí es `--color-accent-hover` (`bg-accent-hover`).
- Foco: el primario usa el anillo de Paper (2px fondo + 2px naranja). Los demás controles usan el mismo patrón en blanco, porque Paper solo dibuja el foco del primario.
- Hover del fantasma y del nav item: el texto pasa a `text`. Paper no los define.
- Los radios ocultos (`sr-only`, absolutos) del selector de estado van dentro de una `label` con `relative`. Sin eso se escapaban del `overflow` del contenedor y añadían una segunda barra de scroll a la página.
- El tamaño 13px (botón pequeño, selector, actor, ayuda) no es un token en Paper; va como `text-[13px]` dentro de los componentes.

**Fuera**
- `--color-input-disabled` (`#D9D9D9`) existe en Paper pero no en `DESIGN.md` ni en ningún componente: no se ha llevado al código (en el inbox).
- Fila de atención: no estaba en los criterios. Se hará con la pantalla Actividad (M3) usando estas piezas.
- Pantallas v1 sin rediseñar, como pedía la historia.
