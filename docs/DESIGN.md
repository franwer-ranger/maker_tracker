# Maker Tracker · Sistema de diseño

> Fuente de verdad visual. Los diseños viven en Paper; este documento recoge las reglas y los valores para que cualquier agente pueda aplicarlos sin abrir Paper. Si Paper y este documento no coinciden, se habla y se corrige uno de los dos.

## Dónde está

Archivo de Paper **Maker Tracker** (`01M50CA4S5CN4Z8ERVW36XWDHF`, https://app.paper.design/file/01M50CA4S5CN4Z8ERVW36XWDHF):

| Página | Qué hay |
|---|---|
| **v3 · Landing** | `[Elegida] Landing · A · Ship happens` es la landing que construimos. `[Aparcada] Landing · B · What's next` no se usa por ahora; no se borra |
| **v3 · Sistema** | `01 · Tipografía`, `02 · Color y forma`, `03 · Componentes` |
| **v2 · Agent-first** | Pantallas de la app (Actividad, Roadmap, Historia, Brief, Stats). Son anteriores al sistema v3: misma estructura, pero hay que pasarlas a sus fuentes y tokens |
| v1 · … | Histórico. No se usa |

Para llevar un diseño a código, leer los valores exactos con el MCP de Paper (`get_jsx`, `get_computed_styles`), nunca a ojo desde una captura. Los tokens del archivo coinciden con los de abajo.

## Principios

- **Taller de noche.** Negro, preciso y tranquilo, al estilo de Geist (Vercel). La marca solo levanta la voz con un titular serif y con el naranja.
- **Solo modo oscuro** por ahora.
- **El naranja es un piloto**: se enciende solo cuando algo pide acción o atención (botón principal, "Necesita tu atención", agente trabajando). Si todo es naranja, nada lo es.
- **Información sobre superficies**, no todo metido en tarjetas. Bordes finos y poco relleno de color.
- **Dos públicos** (ver `PRODUCT.md`): la UI es para la persona. Lo que es de máquina (ids, actores, tiempos, coste, comandos) va en mono, y cada acción importante enseña su comando equivalente.

## Tipografía

| Voz | Fuente | Uso |
|---|---|---|
| Display | **Instrument Serif** 400 | Solo titulares grandes (≥ 40px): landing, título del Brief, hitos. Tracking −0.01em a −0.025em según tamaño |
| Interfaz | **Geist** 400 / 500 / 600 | Todo lo demás |
| Máquina | **Geist Mono** 400 | Ids (`#48`), actores (`claude`), tiempos, coste, comandos, etiquetas de sección en mayúsculas (12px, tracking 0.08em) |

Todas son OFL (Google Fonts / Vercel). **Apple Garamond Light** fue la idea original, pero no tiene licencia web: Instrument Serif es la más parecida (estrecha, misma altura de x). SF Pro tampoco se usa en web.

Escala: 12 · 14 · 16 · 18 · 20 · 24 · 32 (interfaz) y 48 · 72 · 112 (display; el hero de la landing usa 184).

## Color

```css
--color-bg: #000000;              /* fondo */
--color-surface-sunken: #0A0A0A;  /* terminal, bloques de código, ventanas */
--color-surface: #1D1D1D;         /* nav activo, hover, botón desactivado */
--color-border: #2A2A2A;
--color-border-strong: #3A3A3A;   /* botones secundarios, inputs */
--color-text: #FFFFFF;
--color-text-soft: #EDEDED;       /* lectura larga */
--color-text-muted: #9E9C9C;      /* secundario */
--color-text-subtle: #6E6E6E;     /* solo metadatos no esenciales, nunca texto de lectura */
--color-accent: #FF3F01;          /* piloto: acción y atención */
--color-avatar: #3D89F6;          /* actor humano */
--color-state-idea: #6B6B6B;      /* punto hueco */
--color-state-defining: #E8B04A;
--color-state-ready: #F5F5F5;
--color-state-done: #5FB37A;
/* En curso = --color-accent con halo */
```

- **Texto sobre naranja: negro (`#000`), no blanco.** El blanco sobre `#FF3F01` no llega al contraste AA en tamaños pequeños. Los mockups v2 usan blanco y hay que corregirlos.
- Tintes de atención (fondo de una fila que pide atención): naranja al 5–6 % sobre negro (`#120501`), borde `#6B2410`.
- Los colores de estado se usan como puntos (6–10px) y barras, nunca como fondos grandes.

## Forma

- Espaciado base 4: 4 · 8 · 12 · 16 · 24 · 32 · 48 · 64 · 96 · 128.
- Radios: 4 · **6** (botones, inputs) · 8 · **12** (tarjetas, ventanas) · full. Anidados: radio interior = exterior − hueco.
- Alturas de control: 32 (pequeño) · 36 (nav) · 40 (normal) · 44 (CTA de landing).
- Sin degradados de fondo ni sombras decorativas. Foco visible siempre (anillo de 2px del color del control).

## Iconos

**Heroicons** (MIT), versión outline de 24, trazo 1.5, a 20px en interfaz y 16px dentro de botones, color heredado del texto, en SVG en línea. **Font Awesome se elimina.** En código: helper `icon "arrow-right", size: 16` y solo los SVG que se usan, en `app/assets/icons/`. Heroicons no tiene icono de PR: "Ver PR" usa `arrow-top-right-on-square`.

## Componentes

En `v3 · Sistema → 03 · Componentes`:

- **Botón**: primario (naranja, texto negro), secundario (borde `border-strong`), fantasma, desactivado y pequeño. Con estados hover y focus.
- **Nav item**: activo sobre `surface`, con contador naranja.
- **Selector de estado**: control segmentado con los cinco estados y su punto.
- **Input**: fondo `surface-sunken`, borde `border-strong`, ayuda debajo.
- **Actor**: punto + nombre en mono + estado (`claude en #48`). Agente activo = naranja con halo; inactivo = gris; humano = azul.
- **Fila de atención**: id en mono, origen en mono naranja, título, contexto y sus opciones (botones). Marca lateral con `box-shadow: inset 2px 0 0 accent` (no `border-left`, que desalinea).
- **Terminal**: ventana `surface-sunken` con barra de título y contenido en mono.
- **Línea de metadatos**: mono 12px, separada por ` · `.

Regla: si una pantalla necesita una pieza nueva, primero se añade al sistema en Paper y aquí.

## Landing

Elegida la **A · Ship happens**. Pública, en inglés, y su única acción es autoalojarlo:

1. Nav: marca, enlaces (How it works, For agents, Self-host, Docs), GitHub y "Self-host it".
2. Hero: "Ship happens." en serif con el subrayado hecho a mano en naranja; subtítulo; CTA "Self-host in two minutes" + "Read the source"; datos en mono (MIT, Rails + SQLite, en tu máquina, MCP + CLI).
3. Producto: a la izquierda la vista Actividad ("For you"), a la derecha un terminal ("For your agents"): los mismos datos para los dos públicos.
4. Frase grande: "You decide what's worth building. Agents build it…", con revelado palabra a palabra al hacer scroll (de 28 % a 100 % de opacidad).
5. Tres pasos: Define with AI · Ask what's next · Ship and report.
6. "Light, on purpose.": lo que no hay (sprints, puntos…) y cuatro principios.
7. "Are we free?": MIT + bloque de instalación.
8. Footer: "Made by Fran, Romer and Christian."

Pendiente en la landing: la URL del repo es inventada (`github.com/maker-tracker/maker-tracker`); se cambia cuando exista la definitiva. Movimiento: transiciones con curva propia (`cubic-bezier(0.32, 0.72, 0, 1)`), revelados con `IntersectionObserver` y nada de escuchar `scroll` sin throttle.
