# Maker Tracker · Sistema de diseño

> Fuente de verdad visual. Los diseños viven en Paper; este documento recoge las reglas y los valores para que cualquier agente pueda aplicarlos sin abrir Paper. Si Paper y este documento no coinciden, se habla y se corrige uno de los dos.

## Dónde está

Archivo de Paper **Maker Tracker** (`01M50CA4S5CN4Z8ERVW36XWDHF`, https://app.paper.design/file/01M50CA4S5CN4Z8ERVW36XWDHF):

| Página | Qué hay |
|---|---|
| **Landing** | `Landing · Ship happens`, la landing que construimos (repo aparte) |
| **Sistema** | `01 · Tipografía`, `02 · Color y forma`, `03 · Componentes` |
| **App** | Pantallas de la app: `5.9 Actividad` (y `5.9b` vacía, cada una también « · Móvil»), `5.0 Proyectos`, `5.1 Tablero · M2`, `5.2 Tablero · Selector de hito`, `5.3 Roadmap`, `5.4 Historia · Lista (#49)`, `5.6 Historia · Editando (#49)` y `5.5 Brief`, con los datos de las seeds (Postgram). Debajo, los artboards `Pendiente · …` (Actividad, Stats, vista del agente, ejecución): son diseños antiguos que solo sirven de referencia hasta rehacerlos con el sistema |
| v1 · … | Histórico. No se usa |

**Una sola versión**: en Paper solo vive el diseño vigente. Lo que se rehace se sustituye y lo antiguo se borra, sin páginas por versión.

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

Escala: 11 · 12 · 13 · 14 · 16 · 18 · 20 · 24 · 32 (interfaz; el 11 es `--text-label`, solo para las labels de historia; el 13 es `--text-control`, para controles pequeños, selector de estado, actor, metadatos y ayudas de campo) y 48 · 72 · 112 (display; el hero de la landing usa 184).

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
--color-accent-hover: #FF5A24;    /* solo hover del botón primario */
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
- Sin degradados de fondo ni sombras decorativas (la única sombra es la del menú, funcional). Foco visible siempre: anillo de 2px del fondo + 2px de color. Naranja en el botón primario, blanco en el resto de controles.
- Hover: primario a `accent-hover`; secundario a fondo `surface`; fantasma y nav item, texto a `text`.

## Iconos

**Heroicons** (MIT), versión outline de 24, trazo 1.5, a 20px en interfaz y 16px dentro de botones, color heredado del texto, en SVG en línea. **Font Awesome se elimina.** En código: helper `icon "arrow-right", size: 16` y solo los SVG que se usan, en `app/assets/icons/`. Heroicons no tiene icono de PR: "Ver PR" usa `arrow-top-right-on-square`.

## Componentes

En `Sistema → 03 · Componentes`:

- **Botón**: primario (naranja, texto negro), secundario (borde `border-strong`), fantasma, desactivado y pequeño. Con estados hover y focus.
- **Nav item**: activo sobre `surface`, con contador naranja.
- **Selector de estado**: control segmentado con los cinco estados y su punto.
- **Input**: fondo `surface-sunken`, borde `border-strong`, ayuda debajo.
- **Actor**: punto + nombre en mono + estado (`claude en #48`). Agente activo = naranja con halo; inactivo = gris; humano = azul.
- **Fila de atención**: id en mono, origen en mono naranja, título, contexto y sus opciones (botones). Marca lateral con `box-shadow: inset 2px 0 0 accent` (no `border-left`, que desalinea).
- **Terminal**: ventana `surface-sunken` con barra de título y contenido en mono.
- **Línea de metadatos**: mono 12px, separada por ` · `.

Piezas de las pantallas de la app (en `App` y, como referencia, en `03 · Componentes` → "Fila · Historias"):

- **Barra lateral**: Actividad arriba, sola y con el contador de «Te toca»; debajo el proyecto (clave en mono sobre `surface`), navegación Tablero · Roadmap · Brief y sección Agentes abajo.
- **Tarjeta de historia** (Tablero): `#n` en mono, título, labels y metadato arriba a la derecha (actor, "Siguiente", bloqueo, "faltan criterios", mockup). Las Hechas, sin fondo y con el título atenuado.
- **Fila de historia** (Roadmap): estado (104px) · `#n` (40px) · título · metadato, con columnas de ancho fijo.
- **Badge "Siguiente"**: píldora `state-ready` con texto negro. Solo una por proyecto.
- **Label**: mono `text-label` (11px, interlineado 14) sobre `surface`, radio 4.
- **Propiedad**: etiqueta de 112px y valor.
- **Menú**: `surface` con borde `border-strong` y la única sombra funcional del sistema (`0 12px 32px rgba(0,0,0,.6)`).
- **Evento del historial**: marca lateral de 2px (`inset`) con el color del estado al que pasa, o `border-strong` si no es un cambio de estado.
- **Pregunta de agente** (5.10 / 5.10b, MT-29): abierta va arriba del todo, en una tarjeta `radius-xl` con marca lateral naranja (`inset 2px`), quién pregunta y cuánto espera en mono naranja, título, contexto y las opciones como filas de 40px (la recomendada, naranja con texto negro) con su comando `mt answer` en mono a la derecha. Una no bloqueante lleva la marca en `border-strong` y no es naranja. Respondida baja a la sección «Preguntas» al final de la historia, sin naranja: la opción elegida con un check verde, quién respondió, la nota y las descartadas. La etiqueta Reversible/Irreversible solo sale si se indicó.  Cada opción es un botón que responde sin salir de la pantalla (MT-30), con su comando al lado; «Responder con una nota…» abre un texto (nota de la opción pulsada o, con «Responder con este texto», respuesta libre) y «Registrar también como decisión» (`--decide`) solo sale en la página de la historia.
- **Actividad** (5.9 / 5.9b, MT-30): la portada, con todos los proyectos. Cabecera (título 32px y una frase con lo que te toca), bloque «Te toca» (etiqueta naranja con el contador; una lista de tarjetas con marca lateral naranja y `PG-49` en una columna de 56px; lo que más espera, primero) y, a la derecha (340px), «En marcha»: actor, historia y desde cuándo. Cada tarjeta lleva una línea mono naranja (quién, cuánto espera), título, contexto y sus acciones; las preguntas, sus opciones (la recomendada, naranja). Vacía: «Nada te espera.» en serif y «Lo último que ha pasado». El contador naranja de «Actividad» en la barra es el número de tarjetas. En móvil (< 768px) no hay barra lateral: las tarjetas van a sangre, las opciones de 44px con su comando debajo, y una barra inferior de cuatro pestañas (Actividad con el contador, Tablero, Roadmap, Brief).
- **Panel**: un formulario que se abre bajo su botón (p. ej. "Nuevo hito"), con el mismo fondo, borde y sombra que el menú. Inputs sobre `bg` y el botón de enviar pequeño, a la derecha.
- **Barra de cambio pendiente**: tras soltar algo que pide motivo (reordenar en el Roadmap), una barra `surface-sunken` con borde `border-strong`: qué ha cambiado, el motivo (opcional en la UI), "Deshacer" (fantasma) y "Guardar orden" (primario), ambos pequeños. Se guarda al confirmar, porque el motivo va en el evento y los eventos no se editan.
- **Acción discreta**: lo que se hace poco y no debe competir (cerrar o reabrir un hito) es un botón fantasma pequeño, al pie de su bloque, separado por un borde.
- **Cuerpo de una historia**: el markdown tal cual, sección por sección. Cada `##` se pinta como etiqueta de sección y las secciones vacías no se muestran. No se destaca ninguna sección.
- **Editar una historia**: el título pasa a input, el cuerpo al editor (Escribir / Vista previa) y las propiedades de la columna (mockup, labels, "Bloqueada por") a campos que se guardan con el mismo botón. El estado no se cambia mientras se edita.

Regla: si una pantalla necesita una pieza nueva, primero se añade al sistema en Paper y aquí.

## Landing

**Ship happens**. Pública, en inglés, en su propio repo, y su única acción es autoalojarlo:

1. Nav: marca, enlaces (How it works, For agents, Self-host, Docs), GitHub y "Self-host it".
2. Hero: "Ship happens." en serif con el subrayado hecho a mano en naranja; subtítulo; CTA "Self-host it" + "Read the source"; datos en mono (MIT, Rails + SQLite sin servicios externos, en tu máquina, MCP + CLI). Nada de "one container": `docker compose` levanta la app y el contenedor de las copias.
3. Producto: a la izquierda la vista Actividad ("For you", con la navegación de la app: Activity · Board · Roadmap · Brief), a la derecha un terminal ("For your agents"): los mismos datos para los dos públicos.
4. Frase grande: "You decide what's worth building. Agents build it…", con revelado palabra a palabra al hacer scroll (de 28 % a 100 % de opacidad).
5. Tres pasos: Define with AI · Ask what's next · Ship and report.
6. "Light, on purpose.": lo que no hay (sprints, puntos…) y cuatro principios.
7. "Are we free?": no es una FAQ sino la idea de fondo (ser dueño de tu código, tu infraestructura y tus datos, sin pagar a otros por lo que resuelves tú con tus agentes y tu hardware), dicha en una línea. MIT + bloque de instalación con `docker compose` y "SQLite inside, daily backups included. No Redis, no external services, no account."
8. Footer: "Made by Christian, Romer and Fran." y enlaces GitHub · Docs · MIT License.

Enlaces:

| Texto | Destino |
|---|---|
| How it works · For agents · Self-host | Anclas de la propia página |
| GitHub · Read the source · Get it on GitHub | `https://github.com/franwer-ranger/maker_tracker` |
| Docs · Read the setup guide | `docs/SELF_HOSTING.md` del repo de la app, en GitHub |
| MIT License | `LICENSE` del repo de la app |
| Self-host it (nav y hero) | Ancla al bloque de instalación |

La landing describe el producto completo (CLI, MCP, Actividad) aunque aún no esté todo hecho: Fran decide cuándo se comunica.

Iconos: Heroicons, como en la app. Las marcas (GitHub) no están en Heroicons: van con su logo oficial (Octicons).

Movimiento: transiciones con curva propia (`cubic-bezier(0.32, 0.72, 0, 1)`), revelados con `IntersectionObserver` y nada de escuchar `scroll` sin throttle.
