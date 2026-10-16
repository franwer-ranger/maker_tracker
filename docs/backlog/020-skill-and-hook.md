---
number: 20
title: Skill de Maker Tracker y hook SessionStart
milestone: M2
state: ready
claimed_by:
mockup:
labels: [agentes, cli]
blocked_by: [19]
---

## Contexto

Con `mt` instalado, falta que el agente sepa usarlo y que cada sesión arranque con el contexto del proyecto sin pedirlo. Para Claude Code eso es una skill (cómo se trabaja con `mt`) y un hook `SessionStart` que inyecta `mt context`. La skill es genérica: sirve para cualquier proyecto que use Maker Tracker, no solo para este repo.

## Historia

Como Fran, quiero que cualquier sesión de Claude Code en un repo con `.mt` arranque sabiendo el contexto del proyecto y cómo coger trabajo, para que "¿qué es lo siguiente?" funcione sin explicarlo cada vez.

## Criterios de aceptación

- [ ] La skill `maker-tracker` (en `cli/skill/SKILL.md`), escrita en inglés porque es para cualquier proyecto, explica:
  - el ciclo de desarrollo: `mt next` → `mt start` → construir → `mt done --commit`;
  - qué hacer con dudas: `mt comment` en la historia y seguir con otra (`mt release`) si bloquean;
  - cuándo registrar una decisión (`mt decide`);
  - cómo escribe producto un agente: `mt create`/`mt edit` con la plantilla de historia, `mt move … ready` solo sin preguntas abiertas y con mockup si es UI, y motivo siempre al reordenar;
  - que los `breadcrumbs` son el siguiente paso sugerido y los `warnings` hay que leerlos.
- [ ] `mt init PG --claude` además de `.mt`:
  - copia la skill a `.claude/skills/maker-tracker/` del repo;
  - añade a `.claude/settings.json` del repo un hook `SessionStart` que ejecuta `mt context`, sin pisar lo que ya haya.

  Repetirlo no duplica nada.
- [ ] El hook no rompe la sesión si `mt` falla (sin red o sin Tailscale): imprime una línea diciendo que no hay contexto y por qué.
- [ ] Probado en un repo de ejemplo: una sesión nueva de Claude Code empieza con el contexto de Postgram y, ante "¿qué es lo siguiente?", ejecuta `mt next`.
- [ ] `bin/ci` en verde.

## Fuera de alcance

- Instalarlo de forma global (`~/.claude`): se hace por repo, para que sea explícito.
- Otros agentes (Codex…): de momento, `AGENTS.md` del repo puede apuntar a la skill a mano.

## Notas para quien lo construya

- La skill va embebida en el binario (`embed`) para que `mt init --claude` no dependa de tener el repo de Maker Tracker.
- `.mt` y `.claude/` se commitean en el repo del proyecto. El token nunca: vive en `~/.config/mt/config`.

## Preguntas abiertas

## Cierre
