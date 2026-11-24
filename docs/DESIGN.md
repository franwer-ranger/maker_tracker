# Maker Tracker · Sistema de diseño (UI v1)

> Los valores. La filosofía y las reglas están en la skill [`maker-tracker-ds`](../.claude/skills/maker-tracker-ds/SKILL.md); el comportamiento de los componentes, en la skill oficial `ui-sdk`. Si este documento y Paper no coinciden, manda Paper y se corrige este.

## Dónde está

Archivo de Paper **Maker Tracker** (`01M50CA4S5CN4Z8ERVW36XWDHF`, https://app.paper.design/file/01M50CA4S5CN4Z8ERVW36XWDHF). Solo cuentan las páginas `v1 · …`:

- `v1 · 0 · Referencias`: la receta y sus referencias.
- `v1 · 1 · Sistema`: `01 · Tokens`, `08 · Componentes base (receta)`, `09 · Presencia del agente`, `10 · Piezas de pantalla`.
- `v1 · 2` a `v1 · 10`: portada, capacidad, historia, roadmap, taller, decisiones, historias, editar y ajustes; cada una en escritorio claro, oscuro y móvil.
- Debajo del separador `ARCHIVO · no construir`: diseños antiguos. No se construyen ni sirven de referencia.

Los valores exactos se leen con el MCP de Paper (`get_tokens`, `get_jsx`, `get_computed_styles`), nunca a ojo.

## Color

Claro en `:root`, oscuro en `.dark`. La barra lateral es oscura en los dos temas.

| Token | Claro | Oscuro | Uso |
|---|---|---|---|
| `--background` | `#F7F8FA` | `#17171A` | Panel de lectura: blanco frío (Fran, 2026-11-23: menos arena). |
| `--foreground` | `#111113` | `#EDEDED` | Tinta. |
| `--card` | `#FFFFFF` | `#1F1F23` | Superficie levantada: blanco. |
| `--card-foreground` | `#111113` | `igual` |  |
| `--popover` | `#111113` | `#ECEBE6` | Recuadros flotantes (decisión al pasar el ratón): oscuros sobre el papel. |
| `--popover-foreground` | `#EDEEF0` | `#111113` |  |
| `--muted` | `#ECEEF1` | `#26262A` | Relleno sutil, frío. |
| `--muted-foreground` | `#6B6F76` | `#8A8A8F` | Texto secundario sobre blanco frío. |
| `--border` | `#E4E6EA` | `#2E2E33` | Reglas finas del panel, frías. |
| `--input` | `#E4E6EA` | `igual` |  |
| `--ring` | `#111113` | `igual` | Foco. |
| `--primary` | `#111113` | `#EDEDED` | Acción principal: tinta (botón negro sobre papel). |
| `--primary-foreground` | `#F6F7F8` | `#111113` |  |
| `--signal` | `#FF3F01` | `#FF3F01` | Piloto naranja: solo atención, lo que viene y el momento clave. Si todo es naranja, nada lo es. |
| `--signal-soft` | `#FFE7DC` | `#3A1A0E` | Fondo de un aviso de enfoque. |
| `--success` | `#2E7D4F` | `#5FB37A` | Al día, hecho. |
| `--destructive` | `#C2341B` | `igual` |  |
| `--sidebar` | `#0F0F11` | `#0B0B0C` | El marco: sidebar y fondo que contiene el panel. |
| `--sidebar-foreground` | `#C9CBD0` | `igual` | Apagada: no compite con el contenido (receta) |
| `--sidebar-muted` | `#6E7078` | `igual` |  |
| `--sidebar-accent` | `#1C1D21` | `#1F1F23` | Ítem activo del sidebar. |
| `--sidebar-border` | `#2A2A2E` | `#222226` |  |
| `--state-idea` | `#8C8A84` | `igual` | Estado Idea. |
| `--state-defining` | `#D99A1E` | `igual` | Estado Definiendo. |
| `--state-ready` | `#111113` | `#EDEDED` | Estado Lista. |
| `--state-in-progress` | `#FF3F01` | `igual` | En curso (piloto). |
| `--state-done` | `#2E7D4F` | `igual` | Hecha. |
| `--body` | `#3A3D44` | `#B9B9BD` | Texto de lectura (párrafos) |
| `--sidebar-active` | `#F2F3F5` | `#F2F3F5` | Texto del elemento activo de la barra |
| `--kbd` | `#9EA3AB` | `igual` | Atajos de teclado |

## Tipografía, tamaños, espacio y forma

| Token | Valor | Uso |
|---|---|---|
| `--font-display` | `"Instrument Serif"` | Solo titulares de 40px o más, peso 400, tracking -0.01em. Sustituye a Apple Garamond Light (sin licencia web). |
| `--font-sans` | `"Geist"` | Toda la interfaz |
| `--font-mono` | `"Geist Mono"` | Ids, agentes, tiempos, comandos |
| `--text-xs` | `12px` |  |
| `--text-sm` | `14px` |  |
| `--text-base` | `16px` |  |
| `--text-lg` | `18px` |  |
| `--text-xl` | `20px` |  |
| `--text-2xl` | `24px` |  |
| `--text-3xl` | `32px` |  |
| `--text-display-sm` | `48px` |  |
| `--text-display` | `72px` |  |
| `--text-display-lg` | `112px` |  |
| `--text-control` | `13px` | Controles pequeños, selector de estado, actor, metadatos y ayudas de campo. Entre text-xs (12) y text-sm (14). |
| `--text-label` | `11px` | Solo labels de historia (mono, interlineado 14px). |
| `--spacing-1` | `4px` |  |
| `--spacing-2` | `8px` |  |
| `--spacing-3` | `12px` |  |
| `--spacing-4` | `16px` |  |
| `--spacing-6` | `24px` |  |
| `--spacing-8` | `32px` |  |
| `--spacing-12` | `48px` |  |
| `--spacing-16` | `64px` |  |
| `--spacing-24` | `96px` |  |
| `--spacing-32` | `128px` |  |
| `--radius-sm` | `4px` |  |
| `--radius-md` | `6px` |  |
| `--radius-lg` | `8px` |  |
| `--radius-xl` | `12px` |  |
| `--radius-full` | `9999px` |  |
| `--radius` | `6px` | Controles. |
| `--radius-panel` | `14px` | El panel dentro del marco. |

- Instrument Serif solo en el título de la página. Geist para la interfaz; Geist Mono para ids, actores, fechas, números, comandos y etiquetas en mayúsculas (12px, tracking 0.08em).
- Iconos de línea (trazo 1.5–1.8), 13–16 px, sin fondo, del color de su texto.

## Componentes

En `app/frontend/components/`, encima de los comportamientos de UI SDK. El catálogo visual está en Paper (`08` y `10`) y en `/design` (solo development). Una pieza nueva se añade a los tres sitios.

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
