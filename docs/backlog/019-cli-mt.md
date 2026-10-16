---
number: 19
title: CLI mt
milestone: M2
state: ready
claimed_by:
mockup:
labels: [cli]
blocked_by: [16, 17, 18]
---

## Contexto

`mt` es como trabajan los agentes con Maker Tracker desde la terminal, en el repo de cualquier proyecto. Fran decidió el 2026-10-16 que sea un **binario en Go**: sin dependencias para quien lo instale, aunque añade un segundo lenguaje. Habla con la API (#015–#018) de la instancia de cada uno (la torre de Fran, por Tailscale).

## Historia

Como agente, quiero un comando `mt` que me dé el contexto, la siguiente historia y me deje trabajarla, para cerrar el ciclo sin salir de la terminal.

## Criterios de aceptación

**Instalación y configuración**
- [ ] El código vive en este repo, en `cli/` (módulo Go propio), para que cambie a la vez que la API. `make -C cli install` (o `go install ./cli/cmd/mt`) deja `mt` en el PATH.
- [ ] `mt setup <url> <token>` guarda la instancia y el token en `~/.config/mt/config` (permisos `600`) y comprueba que funcionan. Las variables `MT_URL` y `MT_TOKEN` tienen prioridad.
- [ ] `mt init PG`, en la raíz de un repo, crea `.mt` con `project: PG`. `mt` busca `.mt` hacia arriba desde el directorio actual. `--project PG` tiene prioridad. Sin proyecto, el error dice cómo ponerlo.
- [ ] Al arrancar, si `GET /api` devuelve una `api_version` que el binario no conoce, avisa de que hay que actualizarlo.

**Comandos** (cada uno, una llamada a la API)

| Comando | Operación |
|---|---|
| `mt context` | contexto (#016) |
| `mt next` | siguiente |
| `mt roadmap [--closed]` | roadmap |
| `mt show PG-49` | ver |
| `mt list [--state …] [--milestone …] [--label …] [--mine]` | listar |
| `mt decisions` | decisiones |
| `mt start PG-49` · `mt done PG-49 [--commit sha]… [--pr url]` · `mt release PG-49 --reason "…"` | #017 |
| `mt comment PG-49 "…"` · `mt decide "…" --why "…" [--story PG-49] [--supersedes D-9]` | #017 |
| `mt create "Título" [--milestone M2] [--state …] [--file f.md]` · `mt edit PG-49 --file f.md` | #018 |
| `mt move PG-49 ready` · `mt reorder PG-49 --position 1 [--milestone M3] --reason "…"` | #018 |
| `mt brief [--file f.md]` (sin `--file`, lo muestra) · `mt milestone create/edit/close/reopen/reorder …` | #018 |

- [ ] Las historias se citan como `PG-49` o solo `49` (con el proyecto de `.mt`).
- [ ] `--file -` lee de la entrada estándar. `mt show PG-49 > f.md`, editar y `mt edit PG-49 --file f.md` funciona sin tocar nada más.

**Salida**
- [ ] Por defecto, texto legible: el `markdown` si lo hay o el `summary`; después los `warnings` y, al final, "Next:" con los `breadcrumbs`. Igual en terminal que dentro de un agente (no cambia según haya TTY).
- [ ] `--json` imprime el sobre tal cual.
- [ ] Si hay error, imprime el mensaje y el `hint` por stderr y sale con código distinto de 0 (`2` para errores de uso, `1` para el resto).
- [ ] `mt help` y `mt <comando> --help` describen cada comando con un ejemplo, en inglés como el resto de la salida.
- [ ] Al escribir frontmatter, los valores que lo necesiten van entre comillas (títulos con `:`, `no`, `on`…), y lo que `mt show` imprime se puede devolver con `mt edit --file` sin cambios.

- [ ] `bin/ci` compila y pasa `go vet` en `cli/`.

## Fuera de alcance

- Publicar binarios (GitHub Releases, Homebrew): es una acción pública y la decide Fran. Hasta entonces, se compila desde el repo.
- Un MCP: va después de M2, sobre la misma API.
- Autocompletado de la shell.

## Notas para quien lo construya

- **La salida de cada comando está en [`docs/CLI.md`](../CLI.md)**: reglas comunes (idioma, avisos, `Next:`, errores en dos líneas, YAML seguro) y ejemplos con las seeds.

- Go lo instala Fran (también lo necesitan wflow y wtree). Añádelo a `AGENTS.md` (Stack) y haz que `bin/setup` avise si falta.
- Solo biblioteca estándar de Go, salvo que haga falta algo de verdad (p. ej. para el parseo de flags).
- La lista de comandos puede estar escrita en el binario. `GET /api` sirve para comprobar la versión, no hace falta generar el CLI a partir de ella.
- Prueba contra `bin/dev` con el proyecto Postgram de las seeds y un token creado con `mt:token`.

## Preguntas abiertas

## Cierre
