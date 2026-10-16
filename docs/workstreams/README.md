# Vertientes de trabajo

> Maker Tracker avanza en tres vertientes en paralelo, cada una con su propio agente. Este documento es lo común a las tres: léelo entero y luego el brief de tu vertiente.

| Vertiente | Brief | Quién decide | Autonomía |
|---|---|---|---|
| **Producto y diseño** | [`product.md`](product.md) | Fran, con el agente | Baja: el agente propone y redacta, Fran decide |
| **Desarrollo de la app** | [`development.md`](development.md) | El agente, según el backlog | Alta: coge historias Listas y las construye |
| **Self-host y distribución** | [`self-hosting.md`](self-hosting.md) | El agente, con Fran supervisando | Media: toca la torre de Fran y cosas públicas, así que confirma antes de cada paso irreversible |

Contexto que todos deben haber leído: [`../PRODUCT.md`](../PRODUCT.md) (manda sobre todo lo demás), `mt context` y `mt roadmap` (el roadmap vive en Maker Tracker, proyecto `MT`), [`../ARCHITECTURE.md`](../ARCHITECTURE.md) y [`../DESIGN.md`](../DESIGN.md).

## Cómo se reparte

```
  Producto ──(historias Listas en MT)──► Desarrollo ──(app desplegable)──► Self-host
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
| Producto | `docs/PRODUCT.md`, `docs/ARCHITECTURE.md`, `docs/DESIGN.md`, `docs/CLI.md`, el roadmap, las historias y las decisiones en Maker Tracker (crearlas, definirlas, ordenarlas y pasarlas a Lista) y el archivo de Paper |
| Desarrollo | `app/`, `db/`, `config/` (salvo despliegue), `lib/`, `Gemfile`, `bin/` (salvo scripts de despliegue) y, en Maker Tracker, el estado y el Cierre de las historias que construye |
| Self-host | `Dockerfile`, `config/deploy*`, `.kamal/`, scripts de despliegue y backup, `docs/SELF_HOSTING.md`, `README.md`, `LICENSE` y el repo de la landing (aparte) |

Compartido con cuidado: `AGENTS.md` (cambios pequeños, y avisa en el resumen) y `config/` cuando un cambio de despliegue toque la app (lo hace Self-host y lo comenta para que Desarrollo lo sepa).

## Backlog en Maker Tracker

Desde el 2026-10-16 (MT-22), Maker Tracker se gestiona en Maker Tracker: proyecto `MT` en la torre. Este repo tiene `.mt`, así que `mt` sabe el proyecto. Formato de cada comando en [`../CLI.md`](../CLI.md); la skill `maker-tracker` explica el ciclo.

- **Antes de empezar**: `mt context` (lo carga el hook al abrir sesión) y `mt roadmap`.
- **Coger trabajo**: `mt next` → `mt start MT-n`. Solo se cogen historias Listas y sin bloquear.
- **Terminar**: rellena la sección `## Cierre` del cuerpo (`mt show MT-n > f.md`, editar, `mt edit MT-n --file f.md`): commits, decisiones de implementación y lo que quedó fuera. Después, `mt done MT-n --commit <sha>`.
- **Dudas**: `mt comment MT-n "…"` y, si bloquean, `mt release MT-n --reason "…"` y otra historia. Lo que necesita a otra vertiente o a Fran sigue yendo también al inbox.
- **Decisiones de producto**: `mt decide "…" --why "…"` (antes iban a `PRODUCT.md`).
- Solo Producto crea historias Listas y ordena el roadmap. Desarrollo y Self-host pueden crear historias como Idea (`mt create "…"`) para proponer algo.
- Plantilla del cuerpo: Contexto · Historia · Criterios de aceptación · Fuera de alcance · Notas para quien lo construya · Preguntas abiertas · Cierre. Con preguntas abiertas, no está Lista.

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
2. **Fuentes e iconos.** Desarrollo integra Geist, Instrument Serif y Heroicons. Self-host usa los mismos valores en la landing (su propio repo): se comparten los tokens de `docs/DESIGN.md`.
3. **Repo público.** `franwer-ranger/maker_tracker` es público desde el 2026-10-16. Lo que se publica fuera (landing, binarios, dominio) lo sigue decidiendo Fran.
4. **Seeds y datos.** El despliegue de la torre necesita saber si hay datos reales que conservar. Hoy no: solo seeds.
