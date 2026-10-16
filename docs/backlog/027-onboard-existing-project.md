---
number: 27
title: Llevar un proyecto existente a Maker Tracker
milestone: M2
state: done
claimed_by: development
mockup:
labels: [cli, agentes, api]
blocked_by: [24]
---

## Contexto

Fran quiere abrir Claude Code en cualquier carpeta (por ejemplo `~/Code/Personal/postgram`), decir "lleva este proyecto a Maker Tracker: la visión, las decisiones y todo, y luego creamos historias", y que el agente lo haga. Hoy falla en tres sitios:

- La API no crea proyectos (la #018 lo dejó fuera).
- La skill solo existe en las carpetas donde se ha hecho `mt init --claude`, así que en una carpeta nueva el agente no sabe que Maker Tracker existe.
- La skill explica cómo trabajar historias, pero no cómo traer un proyecto que ya existe.

Fran decidió el 2026-10-16 que **un agente puede crear proyectos** y que **la skill se instala de forma global**, con el hook `SessionStart` por carpeta.

## Historia

Como Fran, quiero pedirle a un agente en cualquier repo que lleve ese proyecto a Maker Tracker, para no pasar su contexto a mano y empezar a crear historias ahí mismo.

## Criterios de aceptación

**Crear proyectos**
- [x] `POST /api/projects` (`name`, `key`) crea el proyecto con `Project.create_with_event!` a nombre del actor del token. El brief nace con su plantilla. Si la clave ya existe, `VALIDATION_FAILED` con hint ("pick another key, or use mt init PG if it is yours").
- [x] `mt project create "Postgram" --key PG` lo llama y responde como en `docs/CLI.md` → Escribir. `Next:` sugiere `mt init PG --claude` y `mt brief --file <f.md>`.
- [x] `mt init PG` en una carpeta: si el proyecto no existe, lo dice y sugiere `mt project create`. No lo crea por su cuenta.

**Skill global**
- [x] `mt skill install` copia la skill a `~/.claude/skills/maker-tracker/`. Repetirlo la actualiza. `mt setup` lo sugiere al terminar.
- [x] `mt init PG --claude` deja `.mt` y el hook `SessionStart` en el repo. Si la skill global ya está, no la copia también al repo.

**Onboarding en la skill**
- [x] La skill tiene una sección "Onboard an existing project" que el agente sigue cuando le piden llevar un proyecto a Maker Tracker:
  1. comprobar que `mt` está configurado y, si no, pedir a Fran que haga `mt setup` (el token no pasa por el chat);
  2. leer la documentación del repo (`README`, `AGENTS.md`/`CLAUDE.md`, `docs/`) y lo que diga Fran;
  3. proponer a Fran, **en el chat y antes de escribir nada**, la clave y el nombre, el brief (visión, principios, fuera de alcance, glosario), los hitos con su objetivo y las decisiones con su porqué;
  4. con su OK: `mt project create`, `mt init --claude`, `mt brief --file`, `mt milestone create` y `mt decide`;
  5. terminar con `mt context` y ofrecer empezar a crear historias con la plantilla.
- [x] Probado de verdad: en una carpeta con documentación de producto y una sesión nueva de Claude Code, "lleva este proyecto a Maker Tracker" acaba con el proyecto creado y su `mt context` completo, sin más instrucciones.
- [x] `docs/CLI.md` añade los ejemplos de `mt project create` y `mt skill install`.
- [x] `bin/ci` en verde.

## Fuera de alcance

- Importar historias de otra herramienta (Notion, Linear…). Las historias se crean después, con Fran.
- Subir pantallas: las historias enlazan el mockup en `mockup`.
- Borrar o renombrar proyectos.

## Notas para quien lo construya

- La skill sigue en inglés (`docs/CLI.md` → Idioma). El contenido que escriba el agente va en el idioma del proyecto.
- El paso 3 es lo importante: el agente propone y Fran decide, igual que hace Producto en este repo.

## Preguntas abiertas

## Cierre

Commit «Permite llevar un proyecto existente a Maker Tracker» en `dev/m2-onboard`.

- **Crear proyectos**: `POST /api/projects` con `Project.create_with_event!`. Si la clave ya existe, `VALIDATION_FAILED` con el hint de la historia. Con un nombre vacío o una clave mal escrita, el hint enseña el comando correcto. `mt project create "Postgram" --key PG` responde «PG · Postgram created by claude.» y sugiere `mt init PG --claude` y `mt brief --file <f.md>`. Si `mt init` recibe una clave que no existe, sugiere `mt project create` y no crea nada.
- **Skill global**: `mt skill install` la deja en `~/.claude/skills/maker-tracker/` (o bajo `$CLAUDE_CONFIG_DIR`, como Claude Code) y dice si la instala, la actualiza o ya estaba al día. `mt setup` lo sugiere si no está o no es la de ese `mt`. `mt init --claude` copia la skill al repo solo si no está la global. Si la global es de otra versión, avisa con `Warning:` y no la toca.
- **Skill**: sección «Onboard an existing project» con los cinco pasos, y la descripción se activa también con «lleva este proyecto a Maker Tracker».
- **Prueba real**: instancia vacía en otro puerto y una carpeta con `README.md`, `AGENTS.md` y `docs/` copiados de `~/Code/Personal/postgram`. La sesión nueva de Claude Code (`claude -p`, con la skill como skill del repo para no escribir en el `~/.claude` de Fran) recibió «lleva este proyecto a Maker Tracker…»:
  - En el primer turno leyó la documentación y propuso clave, nombre, brief, 10 hitos y 17 decisiones, diciendo de dónde salía cada cosa. No escribió nada: seguía habiendo 0 proyectos.
  - Con «OK, adelante tal cual», creó el proyecto, `.mt`, el hook, el brief, los hitos y las decisiones, y acabó con `mt context` completo, ofreciendo empezar por las historias.
  - La instalación global la probé aparte, con `CLAUDE_CONFIG_DIR`.
- **`docs/CLI.md`**: ejemplos de `mt project create` (bien y con la clave repetida) y de `mt skill install`. También corregí `Goal:` de M3, que seguía en minúscula.
- **Lo que pidió Producto en el inbox**:
  - `Goal:` saca el objetivo tal cual.
  - Los títulos ya no se cortan: los anchos son mínimos, como dice ahora `docs/CLI.md`.
  - `seed_story` pone `claimed_by` (y `claimed_at`) a `nil` si no se da.
- **De paso**:
  - Un hito sin historias dice «No stories yet.» en `mt context`, en lugar de «0 of 0 done».
  - Un proyecto sin nombre ya no añade «El slug no puede estar vacío».
- **Fuera**: el hook que ya esté instalado en un repo no se reescribe. Las decisiones importadas llevan la fecha de hoy (la #025 dejó fuera las fechas pasadas).
