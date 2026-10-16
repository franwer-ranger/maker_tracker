#!/usr/bin/env bash
# Decisiones de PRODUCT.md, de la más antigua a la más reciente (#022).
# Título: la frase en negrita. Porqué: la viñeta entera (con sus subviñetas).
# Uso, en un proyecto vacío: P=MT bash docs/migration/decisions.sh
set -euo pipefail
: "${P:=MT}"

# D-1 · Anteriores
mt decide 'Autoalojado en mi torre' --why 'Autoalojado en mi torre, como proyecto aparte de Home Assistant. Solo es accesible desde la red local o Tailscale. Por eso la autenticación de agentes puede ser simple: un token por agente, sin OAuth.' --project "$P"
# D-2 · Anteriores
mt decide 'Fuera sprints, puntos y velocidad' --why 'Fuera sprints, puntos y velocidad. Servían para medir a un equipo humano. Construyen los agentes, y el cuello de botella es cuánto defino yo.' --project "$P"
# D-3 · Anteriores
mt decide 'Sin login para humanos' --why 'Sin login para humanos. Al estar autoalojado, sobra. Lo que sí importa es saber quién hizo qué (yo, Claude, Codex…) para el registro de actividad.' --project "$P"
# D-4 · Anteriores
mt decide 'Maker Tracker y wflow, desacoplados por contrato' --why 'Maker Tracker y wflow, desacoplados por contrato. Leer historias y recibir eventos genéricos; nada de base de datos compartida, ni leer los `state.md` de wflow, ni conceptos de wflow (review-tech, apply…) en el modelo del núcleo: las fases son texto libre que trae el evento.' --project "$P"
# D-5 · Anteriores
mt decide 'La UI de wflow es un módulo aislado con interruptor, no un sistema de plugins' --why 'La UI de wflow es un módulo aislado con interruptor, no un sistema de plugins. Dependencia en un solo sentido: el núcleo nunca usa nada de `Wflow::`. Si sobra, se borra la carpeta. Un Rails engine o un sistema de plugins genérico solo si aparece una segunda integración y se repite el patrón.' --project "$P"
# D-6 · Anteriores
mt decide 'Open source, con landing pública' --why 'Open source, con landing pública. El repo será abierto (MIT) con instrucciones para autoalojarlo. La landing es pública e importante: es lo que enseñamos a Romer y Christian (cofundadores) y la puerta al repo. Su única acción es "autoalójalo".' --project "$P"
# D-7 · Anteriores
mt decide 'Repos públicos separados' --why 'Repos públicos separados (2026-10-16): la landing va en su propio repo (Astro o similar, estático) y la app en el suyo (`franwer-ranger/maker_tracker`). wflow podría publicarse aparte, con otro nombre. La landing describe el producto completo aunque aún no exista todo; publicar no es comunicar, y comunicarlo lo decide Fran.' --project "$P"
# D-8 · Anteriores
mt decide 'Filosofía de fondo' --why 'Filosofía de fondo (sdvns, de Fran y Romer): ser dueño de tu código, tu infraestructura y tus datos, en lugar de pagar a otras empresas por lo que hoy resuelves tú con tus agentes y tu hardware. La landing la toca en una línea ("Are we free?"), sin hacer de ello el tema.' --project "$P"
# D-9 · Anteriores
mt decide 'Sistema de diseño' --why 'Sistema de diseño (Paper, páginas "Sistema" y "Landing"): solo modo oscuro por ahora. Dos voces: Instrument Serif para titulares grandes (sustituye a Apple Garamond, que no tiene licencia web) y Geist / Geist Mono para todo lo demás. El naranja `#FF3F01` se reserva para acción y atención. Iconos Heroicons (outline, trazo 1.5; sustituye a Lucide el 2026-10-16); fuera Font Awesome.' --project "$P"
# D-10 · Anteriores
mt decide 'Las paradas de wflow, primero como comandos' --why 'Las paradas de wflow, primero como comandos. Cada opción de una parada muestra su comando (`wflow decide 48 …`) y lo ejecuto yo en la terminal. Si se queda corto, el siguiente paso es que Maker Tracker guarde la decisión y wflow la recoja al reanudar. Maker Tracker nunca ejecuta wflow.' --project "$P"
# D-11 · 2026-10-16 · Arranque de M1
mt decide 'El contexto de proyecto es un único brief' --why 'El contexto de proyecto es un único `brief` en markdown (visión, principios, fuera de alcance, glosario). Las decisiones van aparte, en `Decision`. Si algún día hace falta otro tipo de documento, se añade entonces.

Decidida el 2026-10-16.' --project "$P"
# D-12 · 2026-10-16 · Arranque de M1
mt decide 'Un único actor humano' --why 'Un único actor humano (`fran`, creado en seeds) al que se atribuye todo lo que pasa en la UI. Colaboración multi-persona, después del MVP.

Decidida el 2026-10-16.' --project "$P"
# D-13 · 2026-10-16 · Arranque de M1
mt decide 'Fuera el login ya' --why 'Fuera el login ya: quitar Devise es de las primeras historias de M1, para que los agentes de desarrollo prueben su trabajo sin autenticarse. Sustituye a la regla anterior de esperar a la confirmación de self-host; la condición pasa a self-host (la torre no se expone fuera de la red local / Tailscale).

Decidida el 2026-10-16.' --project "$P"
# D-14 · 2026-10-16 · Arranque de M1
mt decide 'Esquema v2 desde cero' --why 'Esquema v2 desde cero: se borran las tablas v1 (sprints, items, users…) sin migrar datos; no hay datos reales.

Decidida el 2026-10-16.' --project "$P"
# D-15 · 2026-10-16 · Arranque de M1
mt decide 'Fuera el kanban v1' --why 'Fuera el kanban v1 (icebox/backlog/sprints). En su lugar, dos vistas del mismo proyecto:
  - Tablero (portada para la persona): columnas por estado (Idea · Definiendo · Lista · En curso · Hecha), filtrado por hito (por defecto el primer hito abierto; también "Todos" y la bandeja de ideas). Dentro de cada columna, el orden es el del roadmap. Arrastrar entre columnas cambia el estado; mover arriba o abajo reordena la historia en su hito. Ambas cosas generan su evento.
  - Roadmap: los hitos en orden, cada uno con sus historias. Es donde se decide el orden entre hitos y lo que leen los agentes (`mt roadmap`).

Decidida el 2026-10-16.' --project "$P"
# D-16 · 2026-10-16 · Arranque de M1
mt decide 'Reordenar pide motivo a los agentes' --why 'Reordenar pide motivo a los agentes y es opcional en la UI. El evento se registra siempre.

Decidida el 2026-10-16.' --project "$P"
# D-17 · 2026-10-16 · Arranque de M1
mt decide 'Historias: propiedades arriba, markdown libre abajo' --why 'Historias: propiedades arriba, markdown libre abajo (idea tomada de las tarjetas de Notion de la guardería).
  - Identificador: `number` por proyecto con la clave corta del proyecto (`MT-36`), citable en commits y en `mt show MT-36`.
  - Propiedades (`properties`, json) que la app conoce: `mockup` (url de Paper; necesaria para Lista si la historia tiene UI), `labels` (lista libre: plataforma, épica…) y `blocked_by` (números de historia; "bloquea" se calcula al revés).
  - Bloqueada no es un estado: se deriva de `blocked_by`. `mt next` nunca propone una historia bloqueada y el tablero la marca.
  - Fuera, respecto a Notion: Now/Next/Later (lo sustituyen los hitos), Prioridad (la prioridad es el orden en el hito), coste a mano (llega en M4 desde los runs) y relación con fichas de pantalla.
  - Plantilla del cuerpo: Contexto · Historia (Como…, quiero…, para…) · Criterios de aceptación (numerados y comprobables) · Fuera de alcance · Notas para quien lo construya · Preguntas abiertas. Lo que se hace al terminar una historia es igual para todas y vive en las instrucciones del agente, no en cada historia.
  - Para pasar a Lista: ninguna pregunta abierta y mockup si tiene UI. En M1 es una regla visible, no una validación que bloquee.

Decidida el 2026-10-16.' --project "$P"
# D-18 · 2026-10-16 · Arranque de M1
mt decide Decisiones --why 'Decisiones: solo se añaden, desde el Brief. Para cambiar una, se escribe otra que la sustituye.

Decidida el 2026-10-16.' --project "$P"
# D-19 · 2026-10-16 · Arranque de M1
mt decide 'Bandeja de ideas' --why 'Bandeja de ideas: las historias sin hito se ven al final del Roadmap.

Decidida el 2026-10-16.' --project "$P"
# D-20 · 2026-10-16 · Arranque de M1
mt decide 'Eventos en M1' --why 'Eventos en M1: se generan todos; la Historia muestra su historial. La pantalla Actividad llega en M3.

Decidida el 2026-10-16.' --project "$P"
# D-21 · 2026-10-16 · Arranque de M1
mt decide 'Edición de markdown' --why 'Edición de markdown: textarea con vista previa.

Decidida el 2026-10-16.' --project "$P"
# D-22 · 2026-10-16 · Arranque de M1
mt decide 'Las historias de UI de M1 esperan a sus mockups' --why 'Las historias de UI de M1 esperan a sus mockups en Paper; las de modelo, eventos y seeds salen Listas antes. (Hechos y aprobados el mismo día: página `App`.)

Decidida el 2026-10-16.' --project "$P"
# D-23 · 2026-10-16 · Arranque de M1
mt decide 'Una sola versión en Paper' --why 'Una sola versión en Paper. Lo que construimos ahora es la v2 del producto; el sistema de diseño no lleva número. Los diseños antiguos se borran en cuanto tienen sustituto.

Decidida el 2026-10-16.' --project "$P"
# D-24 · 2026-10-16 · Arranque de M1
mt decide 'Iconos: Heroicons' --why 'Iconos: Heroicons en lugar de Lucide.

Decidida el 2026-10-16.' --project "$P"
# D-25 · 2026-10-16 · Definición de M2
mt decide 'Los agentes escriben producto directamente, con registro' --why 'Los agentes escriben producto directamente, con registro: crean y editan historias, las mueven de estado (también a Lista), las reordenan con motivo y editan el brief. Cada cambio deja su evento a su nombre. Sin esto, Maker Tracker no se puede construir con Maker Tracker. Si hacen falta propuestas que apruebe, se decide en M3.

Decidida el 2026-10-16.' --project "$P"
# D-26 · 2026-10-16 · Definición de M2
mt decide 'El CLI mt es un binario en Go' --why 'El CLI `mt` es un binario en Go, en este mismo repo (`cli/`), para que cambie a la vez que la API. Sin dependencias para quien lo instala. Publicar binarios (Releases, Homebrew) se decide después.

Decidida el 2026-10-16.' --project "$P"
# D-27 · 2026-10-16 · Definición de M2
mt decide 'Tokens de agente con un comando en el servidor' --why 'Tokens de agente con un comando en el servidor (`bin/rails "mt:token[claude]"`), sin pantalla. El token identifica, no protege: la app sigue solo en la red local o Tailscale. La UI de agentes llega más adelante.

Decidida el 2026-10-16.' --project "$P"
# D-28 · 2026-10-16 · Definición de M2
mt decide 'Lo que lee un agente es markdown' --why 'Lo que lee un agente es markdown. La API devuelve el sobre en JSON, pero contexto, roadmap e historias van en markdown, y `mt` imprime texto legible por defecto (`--json` para el sobre). Una historia se lee y se escribe en el mismo formato que `docs/backlog/` (frontmatter + cuerpo).

Decidida el 2026-10-16.' --project "$P"
# D-29 · 2026-10-16 · Definición de M2
mt decide 'Proyectos por su clave' --why 'Proyectos por su clave en la API y en `mt` (`PG`, `PG-49`), no por el slug.

Decidida el 2026-10-16.' --project "$P"
# D-30 · 2026-10-16 · Definición de M2
mt decide 'Lo que habla con máquinas va en inglés' --why 'Lo que habla con máquinas va en inglés: salida de `mt`, mensajes de la API, claves, comandos y la skill, como los nombres de tablas o el código. El contenido (títulos, historias, brief, decisiones) va en el idioma en que se escribe, y la app sigue en español. Formato de la salida en [`CLI.md`](CLI.md).

Decidida el 2026-10-16.' --project "$P"
# D-31 · 2026-10-16 · Definición de M2
mt decide 'Frontmatter YAML + cuerpo markdown' --why 'Frontmatter YAML + cuerpo markdown para leer y escribir una historia; JSON solo en la API y con `--json`.

Decidida el 2026-10-16.' --project "$P"
# D-32 · 2026-10-16 · Definición de M2
mt decide 'Al migrar a la app (#022), las historias conservan su número' --why 'Al migrar a la app (#022), las historias conservan su número (`MT-14` es la #014), para que valgan las referencias de commits y documentos, y las decisiones de este documento se mueven a la app (`D-n`): una sola fuente, que leen `mt context` y `mt decisions`.

Decidida el 2026-10-16.' --project "$P"
# D-33 · 2026-10-16 · Definición de M2
mt decide 'Skill y hook por repo' --why 'Skill y hook por repo: mt init PG --claude deja .mt, la skill y el hook SessionStart en el repo del proyecto, no en la configuración global.

Decidida el 2026-10-16.' --project "$P"
# D-34 · 2026-10-16 · Definición de M2
mt decide 'Skill global, hook por carpeta' --why 'Skill global, hook por carpeta (2026-10-16): `mt skill install` deja la skill en `~/.claude/skills/`, para que en cualquier carpeta el agente sepa usar `mt`; `mt init PG --claude` deja `.mt` y el hook `SessionStart` en el repo.

Decidida el 2026-10-16.' --project "$P" --supersedes D-33
# D-35 · 2026-10-16 · Definición de M2
mt decide 'Un agente puede crear proyectos' --why 'Un agente puede crear proyectos (`mt project create`, 2026-10-16), a su nombre y con su evento. Sustituye a "crear proyectos solo desde la UI" de la #018. Así funciona "lleva este proyecto a Maker Tracker" desde cualquier repo (#027): el agente lee el repo, propone brief, hitos y decisiones, y escribe con el OK de Fran.

Decidida el 2026-10-16.' --project "$P"
