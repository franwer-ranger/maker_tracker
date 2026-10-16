---
number: 20
title: Skill de Maker Tracker y hook SessionStart
milestone: M2
state: done
claimed_by: development
mockup:
labels: [agentes, cli]
blocked_by: [19]
---

## Contexto

Con `mt` instalado, falta que el agente sepa usarlo y que cada sesión arranque con el contexto del proyecto sin pedirlo. Para Claude Code eso es una skill (cómo se trabaja con `mt`) y un hook `SessionStart` que inyecta `mt context`. La skill es genérica: sirve para cualquier proyecto que use Maker Tracker, no solo para este repo.

## Historia

Como Fran, quiero que cualquier sesión de Claude Code en un repo con `.mt` arranque sabiendo el contexto del proyecto y cómo coger trabajo, para que "¿qué es lo siguiente?" funcione sin explicarlo cada vez.

## Criterios de aceptación

- [x] La skill `maker-tracker` (en `cli/skill/SKILL.md`) explica:
  - el ciclo de desarrollo: `mt next` → `mt start` → construir → `mt done --commit`;
  - qué hacer con dudas: `mt comment` en la historia y seguir con otra (`mt release`) si bloquean;
  - cuándo registrar una decisión (`mt decide`);
  - cómo escribe producto un agente: `mt create`/`mt edit` con la plantilla de historia, `mt move … ready` solo sin preguntas abiertas y con mockup si es UI, y motivo siempre al reordenar;
  - que los `breadcrumbs` son el siguiente paso sugerido y los `warnings` hay que leerlos.
- [x] `mt init PG --claude` además de `.mt`:
  - copia la skill a `.claude/skills/maker-tracker/` del repo;
  - añade a `.claude/settings.json` del repo un hook `SessionStart` que ejecuta `mt context`, sin pisar lo que ya haya.

  Repetirlo no duplica nada.
- [x] El hook no rompe la sesión si `mt` falla (sin red o sin Tailscale): imprime una línea diciendo que no hay contexto y por qué.
- [x] Probado en un repo de ejemplo: una sesión nueva de Claude Code empieza con el contexto de Postgram y, ante "¿qué es lo siguiente?", ejecuta `mt next`.
- [x] `bin/ci` en verde.

## Fuera de alcance

- Instalarlo de forma global (`~/.claude`): se hace por repo, para que sea explícito.
- Otros agentes (Codex…): de momento, `AGENTS.md` del repo puede apuntar a la skill a mano.

## Notas para quien lo construya

- La skill va embebida en el binario (`embed`) para que `mt init --claude` no dependa de tener el repo de Maker Tracker.
- `.mt` y `.claude/` se commitean en el repo del proyecto. El token nunca: vive en `~/.config/mt/config`.

## Preguntas abiertas

## Cierre

Rama `dev/m2-api`, commit «Añade la skill de Maker Tracker y el hook SessionStart».

**Hecho**
- La skill `maker-tracker` está en `cli/skill/SKILL.md` y va embebida en el binario (`cli/skill/skill.go`, `//go:embed`). Es genérica (no habla de este repo): ciclo `next → start → construir → done --commit`, dudas con `comment` y `release`, cuándo usar `decide`, cómo escribe producto un agente (plantilla, regla de Lista, motivo al reordenar) y cómo leer «Siguiente:», «Avisos:» y los errores.
- `mt init PG --claude` deja la skill en `.claude/skills/maker-tracker/SKILL.md` y añade a `.claude/settings.json` un hook `SessionStart` sin tocar lo que ya hay. Repetirlo no duplica nada: si un hook ya ejecuta `mt context`, no lo añade, y la skill solo se reescribe si ha cambiado.
- El hook es `command -v mt >/dev/null 2>&1 && mt context --hook || echo "Maker Tracker: sin contexto (…)"`. `mt context --hook` nunca falla: sin red o con un error de la API imprime «Maker Tracker: sin contexto del proyecto (motivo)» y sale con 0. Si `mt` no está en el PATH, lo dice el `echo`.
- Probado en un repo de ejemplo con `claude -p "¿Qué es lo siguiente?"` contra el servidor de test: el hook inyecta el contexto de Postgram, el agente carga la skill, ejecuta `mt next` y responde PG-49 con su motivo.
- Arreglado al probarlo: el agente leía `blocked_by: [47]` en el frontmatter y creía que PG-49 seguía bloqueada. Ahora la parte de solo lectura de `mt show` añade «**Ya no la bloquean** (hechas): PG-47».

**Decisiones**
- `mt init --claude` reescribe `settings.json` con las claves en orden alfabético (Go no conserva el orden de un JSON que no conoce). El contenido se mantiene entero.
- El hook no lleva `matcher`, así que se ejecuta al empezar, reanudar, limpiar y compactar: después de compactar la sesión vuelve a tener el contexto.

**Fuera**
- Que Fran lo use de verdad en el repo de Maker Tracker es la #022.
