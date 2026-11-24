---
name: maker-tracker-ds
description: Filosofía y sistema de diseño de Maker Tracker (UI v1). Cárgala antes de diseñar, construir o revisar cualquier pantalla, componente o estilo de la web, junto con la skill oficial `ui-sdk`. Dice qué buscamos, qué reglas no se rompen y de dónde salen los valores exactos.
---

# Maker Tracker · filosofía de diseño

Esta skill dice **por qué y cómo se ve** Maker Tracker. El **cómo se construye** un componente (teclado, foco, selección, popups, arrastrar, ARIA) lo dice la skill oficial `ui-sdk`: úsala para todo comportamiento y no lo reinventes. Los valores exactos están en Paper y en `docs/DESIGN.md`.

## Para quién y para qué

Maker Tracker es donde un maker **define y conoce su producto** junto a sus agentes (D-91). Construir, repartir y probar es de Relay. La documentación viva es el centro; las historias son el diff que la cambia.

- **Agent-first, pero la UI es para una persona.** Todo lo que hace la UI lo pueden hacer los agentes por la API y `mt`. La pantalla existe para que una persona piense con calma.
- **Una cosa cada vez.** Un producto por pantalla (combo con buscador, nunca pestañas ni mezclas de proyectos): saltar de foco en foco cansa a una persona, aunque a un agente no.
- **Relajar la mente y centrarse en lo que toca.** Si estás en la UI, no te empujamos de vuelta al chat. El taller enseña como mucho 5 cosas.
- **Resolver bien el núcleo.** No copiamos funciones de la competencia; cada pantalla responde a una pregunta y nada más.

## La receta: «Calma para trabajar, *carácter* en los momentos justos»

Referencias en Paper, página `v1 · 0 · Referencias`.

**Calma (Linear, Things 3).**
- Panel claro y frío que flota dentro del marco oscuro. La barra lateral, oscura y apagada: no compite por una atención que no se ha ganado.
- La estructura se siente, no se ve: pocas reglas, títulos con aire, listas que respiran.
- El color es estado, no adorno. Casi monocromo.
- Lo de ahora, separado claramente de lo que viene.

**Carácter (Teenage Engineering, Nothing).** El software como un instrumento con un sistema estricto. El rasgo propio aparece **solo** en los estados, los números, la señal naranja, el título de página en serif y el logo. Si un rasgo aparece en todas partes, deja de ser carácter: se quita.

**Vida.** Cuando un agente trabaja o algo cambia en directo, se nota con el toque de instrumento: la matriz de puntos naranja (`09 · Presencia del agente`), con muchos fotogramas para que parezca aleatoria, icono de robot y el nombre del agente donde quepa (`🤖 saul en Revelarlo`).

**Teclado (Raycast).** ⌘K para todo, `/` para buscar, atajos visibles con `kbd` junto a las acciones principales.

## Reglas que no se rompen

- **Un solo botón en tinta por pantalla.** El resto, secundarios o acciones ligeras.
- **Naranja (`--signal`) solo para atención y vida del agente**: «te toca», lo urgente, el agente trabajando, En curso. **Nunca en botones.**
- **Instrument Serif solo en el título de la página.** Geist para la interfaz. Geist Mono para lo de máquina: ids (`PG-49`), actores, fechas, números, comandos y etiquetas en mayúsculas.
- **Iconos sí, descriptivos**: de línea, sin fondo, del mismo color que su texto. No llenar de iconos ni iconos de colores por sección. Alguna ilustración de puntos al estilo Nothing en momentos concretos (estados vacíos, primera vez), nunca de adorno.
- **«Copiar para tu agente» en muchos sitios, pero siempre ligera** (acción secundaria, ⌘⇧C). Nunca protagonista.
- Bordes completos y finos; nada de rayas laterales de color. Sin degradados, sombras decorativas, cristal ni morados. Que no parezca shadcn de serie.
- Claro, oscuro y sistema. La barra lateral es oscura en los dos.
- Foco siempre visible. Filas repetidas con columnas de ancho fijo.
- Lo que hace una acción importante se puede enseñar también como comando (`mt …`): la persona y el agente ven lo mismo.
- **Nunca datos inventados**, ni en Paper ni en las seeds: si no hay dato, la pieza no aparece o dice que falta.

## De dónde salen los valores

1. Paper, archivo **Maker Tracker** (`01M50CA4S5CN4Z8ERVW36XWDHF`), por su MCP (`http://127.0.0.1:29979/mcp` en la torre). **Solo cuentan las páginas `v1 · …`**:
   - `v1 · 1 · Sistema`: `01 · Tokens`, `08 · Componentes base (receta)`, `09 · Presencia del agente`, `10 · Piezas de pantalla`.
   - `v1 · 2` a `v1 · 10`: cada pantalla en escritorio claro, oscuro y móvil.
   - Lo que está debajo del separador `ARCHIVO · no construir` es antiguo: ni spec ni referencia.
2. Saca los valores con `get_jsx`, `get_computed_styles` y `get_tokens`. **Nunca a ojo desde una captura**: las capturas solo sirven para comparar el resultado.
3. Sin las herramientas del MCP de Paper **no se construye UI**: devuelve `blocked`.

## En el código (D-98)

- Rails + Inertia + React + UI SDK, con Vite. Nuestros componentes envuelven los comportamientos de UI SDK y llevan nuestro aspecto. Antes de escribir uno, sigue la skill `ui-sdk` y mira si ya existe en `app/frontend/components/`.
- Tokens con los mismos nombres que en Paper (`--background`, `--signal`, `--state-ready`…); el oscuro es `.dark { … }` con los valores de los tokens `--dark-*`. Nada de colores ni tamaños sueltos: si falta un token, va primero a Paper y a `docs/DESIGN.md`.
- `/design` (solo en development) enseña todas las piezas. Si añades una, añádela ahí.
- Las vistas ERB, Basecoat y Stimulus de la web son la UI antigua: se quitan en MT-107. No construyas sobre ellas.

## Verificar

Con **agent-browser** (headless): cada pantalla en claro, oscuro y a 390 de ancho, al lado de su artboard de Paper. Una diferencia que rompa la receta o la estructura es un fallo.

## Si diseñas en Paper

- Una sola versión: lo que se rehace sustituye a lo anterior; lo antiguo va al archivo o se borra.
- Clona piezas de `08` y `10` antes de dibujar otras; una pieza nueva se añade a `10`.
- Datos de ejemplo reales de Postgram, para que las seeds coincidan.
