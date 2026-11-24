---
name: maker-tracker-design
description: Sistema de diseño de Maker Tracker. Cárgala antes de crear o cambiar cualquier vista, componente, estilo o pantalla de la app (app/views, app/helpers de UI, CSS, Tailwind, iconos) o la landing, y antes de diseñar en Paper. Explica dónde están los diseños, cómo sacar valores exactos y qué reglas no se rompen.
---

# Diseño de Maker Tracker

La fuente de verdad es `docs/DESIGN.md` y el archivo de Paper que enlaza. Esta skill es el procedimiento. Si algo de aquí choca con `DESIGN.md`, manda `DESIGN.md`.

## Antes de tocar UI

1. Lee `docs/DESIGN.md` entero. Es corto.
2. Busca la pantalla en Paper, archivo **Maker Tracker** (`01M50CA4S5CN4Z8ERVW36XWDHF`). **Solo cuentan las páginas `v1 · …`** (rediseño v1, D-91 y D-98):
   - `v1 · 0 · Referencias`: la receta y sus referencias.
   - `v1 · 1 · Sistema`: `01 · Tokens`, `08 · Componentes base (receta)`, `09 · Presencia del agente`, `10 · Piezas de pantalla`.
   - `v1 · 2` a `v1 · 10`: las pantallas, cada una en escritorio claro, oscuro y móvil.
   - Todo lo que está debajo del separador `ARCHIVO · no construir` es antiguo: no es spec ni referencia.
   - El MCP de Paper corre en la torre (`http://127.0.0.1:29979/mcp`). Si no tienes sus herramientas, **no construyas UI**: devuelve `blocked`.
3. Saca los valores con el MCP de Paper (`get_jsx`, `get_computed_styles`, `get_tokens`). **Nunca midas a ojo desde una captura.** Las capturas solo sirven para comprobar el resultado.
4. Si la historia enlaza un artboard, el resultado tiene que coincidir con él y con los datos de las seeds (Postgram).

## En el código (UI v1, D-98)

- Stack: Rails + Inertia + React + UI SDK (Vite). Componentes propios encima de los de UI SDK; los tokens con los mismos nombres que en Paper (`get_tokens`). No escribas colores ni tamaños sueltos: si falta un token, va primero a Paper.
- Las vistas ERB, Basecoat y Stimulus de la web son la UI antigua: se van en MT-107. No construyas sobre ellas.
- `/design` (solo en development) enseña todas las piezas. Si añades una, añádela también ahí.

## La receta: calma para trabajar, carácter en los momentos justos

- Claro y oscuro (y sistema). Barra lateral siempre oscura.
- **Un solo botón en tinta por pantalla.** El resto, secundarios o acciones ligeras.
- **Naranja solo para atención y vida del agente** (presencia, «te toca»). Nunca en botones.
- **Instrument Serif solo en el título de la página.** Geist para la interfaz; Geist Mono para lo de máquina: ids (`PG-49`), actores, fechas, números, comandos y etiquetas en mayúsculas.
- Iconos de línea, descriptivos, sin fondo. Bordes completos; nada de rayas laterales de color. Sin degradados ni sombras decorativas.
- «Copiar para tu agente» está en muchos sitios, pero siempre como acción ligera (⌘⇧C), nunca protagonista.
- Teclado como Raycast: ⌘K, `/` para buscar, atajos visibles con `kbd`.
- Un producto cada vez (combo con buscador): nunca mezclar proyectos en una pantalla.
- Foco siempre visible. Filas repetidas con columnas de ancho fijo.
- Lo que hace una acción importante se puede enseñar también como comando (`mt …`): la persona y el agente ven lo mismo.

## Si diseñas en Paper

- Una sola versión: lo que rehaces sustituye a lo anterior; lo antiguo va al archivo o se borra.
- Usa los tokens del archivo y clona piezas de `08` y `10` antes de dibujar otras nuevas.
- Los datos de ejemplo son los de Postgram, reales: nada inventado.
