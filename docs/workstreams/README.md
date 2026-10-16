# Vertientes de trabajo

> Maker Tracker avanza en tres vertientes en paralelo, cada una con su propio agente. Este documento es lo común a las tres: léelo entero y luego el brief de tu vertiente.

| Vertiente | Brief | Quién decide | Autonomía |
|---|---|---|---|
| **Producto y diseño** | [`product.md`](product.md) | Fran, con el agente | Baja: el agente propone y redacta, Fran decide |
| **Desarrollo de la app** | [`development.md`](development.md) | El agente, según el backlog | Alta: coge historias Listas y las construye |
| **Self-host y distribución** | [`self-hosting.md`](self-hosting.md) | El agente, con Fran supervisando | Media: toca la torre de Fran y cosas públicas, así que confirma antes de cada paso irreversible |

Contexto que todos deben haber leído: [`../PRODUCT.md`](../PRODUCT.md) (manda sobre todo lo demás), [`../ROADMAP.md`](../ROADMAP.md), [`../ARCHITECTURE.md`](../ARCHITECTURE.md) y [`../DESIGN.md`](../DESIGN.md).

## Cómo se reparte

```
  Producto ──(historias Listas en docs/backlog/)──► Desarrollo ──(app desplegable)──► Self-host
     ▲                                                  │                                │
     └──────────── preguntas, propuestas, decisiones ───┴────────────────────────────────┘
```

- **Producto** produce lo que los otros consumen: historias con criterios, decisiones, mockups y el sistema de diseño.
- **Desarrollo** convierte historias Listas en código.
- **Self-host** pone la app en la torre de Fran y prepara todo lo necesario para que cualquiera la autoaloje: guía, landing pública y repo abierto.

## Qué es de quién

Cada vertiente solo edita lo suyo. Si necesitas cambiar algo de otra, déjalo como propuesta (ver abajo).

| Vertiente | Es suyo |
|---|---|
| Producto | `docs/PRODUCT.md`, `docs/ROADMAP.md`, `docs/ARCHITECTURE.md`, `docs/DESIGN.md`, `docs/backlog/` (crear y definir historias) y el archivo de Paper |
| Desarrollo | `app/`, `db/`, `config/` (salvo despliegue), `lib/`, `Gemfile`, `bin/` (salvo scripts de despliegue) y el campo de estado y el cierre de las historias en `docs/backlog/` |
| Self-host | `Dockerfile`, `config/deploy*`, `.kamal/`, scripts de despliegue y backup, `docs/SELF_HOSTING.md`, `README.md`, `LICENSE`, `site/` (la landing estática) |

Compartido con cuidado: `AGENTS.md` (cambios pequeños, y avisa en el resumen) y `config/` cuando un cambio de despliegue toque la app (lo hace Self-host y lo comenta para que Desarrollo lo sepa).

## Backlog en el repo (hasta que exista la v2)

Maker Tracker todavía no puede guardar su propio backlog (eso llega en M2). Mientras tanto, **cada historia es un fichero en `docs/backlog/`**, con la misma forma que el modelo `Story`, para que migrarlas luego sea trivial:

```markdown
---
number: 7
title: Tokens del sistema de diseño en Tailwind
milestone: M1
state: ready            # idea | defining | ready | in_progress | done
claimed_by:             # development | self-hosting (al empezar)
mockup:                 # url de Paper; obligatoria para ready si tiene UI
labels: []              # lista libre: ui, modelo, agentes…
blocked_by: []          # números de historia que tienen que estar done antes
---

## Contexto
<!-- por qué, y qué existe ya -->
## Historia
Como …, quiero …, para …
## Criterios de aceptación
- [ ] …
## Fuera de alcance
## Notas para quien lo construya
## Preguntas abiertas
<!-- si hay alguna, la historia no puede estar ready -->
## Cierre
<!-- lo rellena quien la construye: commits, decisiones tomadas, lo que quedó fuera -->
```

- Nombre del fichero: `NNN-slug.md` (`007-design-tokens.md`). Numeración global y correlativa.
- El orden dentro de un hito lo da `docs/ROADMAP.md`, que enlaza las historias.
- Una historia con `blocked_by` no se empieza hasta que esas historias estén `done`.
- Solo Producto crea historias y las pasa a `ready`. Desarrollo y Self-host pueden crear historias en `idea` para proponer algo.
- Quien construye pasa a `in_progress` al empezar y a `done` al terminar, y rellena **Cierre**.
- Las decisiones van a `docs/PRODUCT.md` (sección Decisiones) si son de producto, o al **Cierre** de la historia si son de implementación.

## Propuestas y preguntas

Cuando una vertiente necesita algo de otra, o una decisión de Fran:

- Lo deja en `docs/workstreams/inbox.md`, con fecha, vertiente de origen, a quién va y qué opciones hay.
- Lo dice también en su resumen final a Fran.
- No bloquea su trabajo esperando: sigue con lo siguiente que no dependa de eso.

## Git

- **Un worktree y una rama por vertiente**, dentro del repo: `.claude/worktrees/<vertiente>` con ramas `product/<tema>`, `dev/<tema>` y `selfhost/<tema>`. Nadie trabaja directamente en `main`.
- **`bin/ci` debe pasar antes de cada commit.**
- **Antes de commitear, pushear, mergear o borrar algo, se confirma con Fran** (regla de `Code/Personal/AGENTS.md`). Lo mismo para cualquier cosa pública o en la torre.
- Commits pequeños, en español, con el formato del repo.
- Antes de pedir el merge a `main`, rebase sobre `main` para que los conflictos los resuelva quien los provoca.

## Dependencias conocidas entre vertientes

1. **Login y red.** La v2 quita Devise y el login humano, y es de las primeras historias de M1 (decisión de Fran del 2026-10-16: así los agentes prueban su trabajo sin autenticarse). Por eso Self-host **no despliega nada accesible desde fuera** de la red local o Tailscale.
2. **Fuentes e iconos.** Desarrollo integra Geist, Instrument Serif y Heroicons. Self-host usa los mismos valores en la landing estática: se comparten los tokens de `docs/DESIGN.md`.
3. **Repo público.** El repo es **privado** hoy. Hacerlo público lo decide Fran; Self-host lo prepara (licencia, README, revisión de secretos) y pregunta.
4. **Seeds y datos.** El despliegue de la torre necesita saber si hay datos reales que conservar. Hoy no: solo seeds.
