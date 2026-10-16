---
number: 27
title: Llevar un proyecto existente a Maker Tracker
milestone: M2
state: ready
claimed_by:
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
- [ ] `POST /api/projects` (`name`, `key`) crea el proyecto con `Project.create_with_event!` a nombre del actor del token. El brief nace con su plantilla. Si la clave ya existe, `VALIDATION_FAILED` con hint ("pick another key, or use mt init PG if it is yours").
- [ ] `mt project create "Postgram" --key PG` lo llama y responde como en `docs/CLI.md` → Escribir. `Next:` sugiere `mt init PG --claude` y `mt brief --file <f.md>`.
- [ ] `mt init PG` en una carpeta: si el proyecto no existe, lo dice y sugiere `mt project create`. No lo crea por su cuenta.

**Skill global**
- [ ] `mt skill install` copia la skill a `~/.claude/skills/maker-tracker/`. Repetirlo la actualiza. `mt setup` lo sugiere al terminar.
- [ ] `mt init PG --claude` deja `.mt` y el hook `SessionStart` en el repo. Si la skill global ya está, no la copia también al repo.

**Onboarding en la skill**
- [ ] La skill tiene una sección "Onboard an existing project" que el agente sigue cuando le piden llevar un proyecto a Maker Tracker:
  1. comprobar que `mt` está configurado y, si no, pedir a Fran que haga `mt setup` (el token no pasa por el chat);
  2. leer la documentación del repo (`README`, `AGENTS.md`/`CLAUDE.md`, `docs/`) y lo que diga Fran;
  3. proponer a Fran, **en el chat y antes de escribir nada**, la clave y el nombre, el brief (visión, principios, fuera de alcance, glosario), los hitos con su objetivo y las decisiones con su porqué;
  4. con su OK: `mt project create`, `mt init --claude`, `mt brief --file`, `mt milestone create` y `mt decide`;
  5. terminar con `mt context` y ofrecer empezar a crear historias con la plantilla.
- [ ] Probado de verdad: en una carpeta con documentación de producto y una sesión nueva de Claude Code, "lleva este proyecto a Maker Tracker" acaba con el proyecto creado y su `mt context` completo, sin más instrucciones.
- [ ] `docs/CLI.md` añade los ejemplos de `mt project create` y `mt skill install`.
- [ ] `bin/ci` en verde.

## Fuera de alcance

- Importar historias de otra herramienta (Notion, Linear…). Las historias se crean después, con Fran.
- Subir pantallas: las historias enlazan el mockup en `mockup`.
- Borrar o renombrar proyectos.

## Notas para quien lo construya

- La skill sigue en inglés (`docs/CLI.md` → Idioma). El contenido que escriba el agente va en el idioma del proyecto.
- El paso 3 es lo importante: el agente propone y Fran decide, igual que hace Producto en este repo.

## Preguntas abiertas

## Cierre
