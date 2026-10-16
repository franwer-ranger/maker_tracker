---
name: maker-tracker-design
description: Sistema de diseño de Maker Tracker. Cárgala antes de crear o cambiar cualquier vista, componente, estilo o pantalla de la app (app/views, app/helpers de UI, CSS, Tailwind, iconos) o la landing, y antes de diseñar en Paper. Explica dónde están los diseños, cómo sacar valores exactos y qué reglas no se rompen.
---

# Diseño de Maker Tracker

La fuente de verdad es `docs/DESIGN.md` y el archivo de Paper que enlaza. Esta skill es el procedimiento. Si algo de aquí choca con `DESIGN.md`, manda `DESIGN.md`.

## Antes de tocar UI

1. Lee `docs/DESIGN.md` entero. Es corto.
2. Busca la pantalla en Paper, archivo **Maker Tracker** (`01M50CA4S5CN4Z8ERVW36XWDHF`):
   - **App**: pantallas de la app. Los artboards `Pendiente · …` son diseños antiguos; sirven de referencia, no de spec.
   - **Sistema**: `01 · Tipografía`, `02 · Color y forma`, `03 · Componentes`.
   - **Landing**: `Landing · Ship happens`.
3. Saca los valores con el MCP de Paper (`get_jsx`, `get_computed_styles`, `get_tokens`). **Nunca midas a ojo desde una captura.** Las capturas solo sirven para comprobar el resultado.
4. Si la historia enlaza un artboard, el resultado tiene que coincidir con él y con los datos de las seeds (Postgram).

## En el código

- Tokens como variables CSS en `app/assets/stylesheets/application.tailwind.css`, expuestos en `config/tailwind.config.js` con los mismos nombres que en Paper: `bg-accent`, `text-muted`, `border-strong`, `text-control`, `font-display`… No escribas colores ni tamaños sueltos (`#FF3F01`, `text-[13px]`). Si falta un token, va primero a Paper y a `DESIGN.md`.
- Componentes propios, al estilo shadcn, en `app/helpers/components_helper.rb` y `app/views/components/`:
  - controles: `ui_button`, `nav_item`, `ui_field`;
  - estado: `state_dot`, `state_selector`;
  - máquina y metadatos: `actor`, `meta_line`, `section_label`, `terminal`.

  Reutilízalos antes de crear otros.
- Iconos: `icon "nombre", size: 16`. **Heroicons** outline de 24, trazo 1.5, SVG en línea. Copia solo los que uses en `app/assets/icons/`.
- `/design` (solo en development) enseña todas las piezas. Si añades una, añádela también ahí.

## Reglas que no se rompen

- Solo modo oscuro. Fondo `bg`, texto `text`.
- **Naranja = acción o atención**: botón primario, "Necesita tu atención", agente trabajando. Nada más. Texto **negro** sobre naranja.
- **Serif (Instrument Serif) solo en titulares grandes** (≥ 40px). Geist para la interfaz y Geist Mono para lo de máquina: ids (`#48`, `PG-49`), actores, fechas, coste, comandos y etiquetas de sección en mayúsculas.
- La información va sobre superficies, no todo en tarjetas. Bordes finos. Sin degradados ni sombras decorativas.
- Foco siempre visible: 2px del fondo + 2px de color (naranja en el primario, blanco en el resto).
- Filas repetidas con columnas de ancho fijo, para que se alineen.
- Lo que hace una acción importante se puede enseñar también como comando (`mt …`): la persona y el agente ven lo mismo.

## Si diseñas en Paper

- Una sola versión: lo que rehaces sustituye a lo anterior y lo antiguo se borra. Nada de páginas o artboards "v2", "v3"…
- Usa los tokens del archivo (`var(--color-…)`) y clona piezas de `03 · Componentes` o de `App` antes de dibujar otras nuevas.
- Una pieza nueva se añade a `03 · Componentes` y a `DESIGN.md`.
- Los datos de ejemplo son los de Postgram, para que las seeds puedan coincidir.
