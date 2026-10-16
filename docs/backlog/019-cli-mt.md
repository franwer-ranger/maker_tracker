---
number: 19
title: CLI mt
milestone: M2
state: done
claimed_by: development
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
- [x] El código vive en este repo, en `cli/` (módulo Go propio), para que cambie a la vez que la API. `make -C cli install` (o `go install ./cli/cmd/mt`) deja `mt` en el PATH.
- [x] `mt setup <url> <token>` guarda la instancia y el token en `~/.config/mt/config` (permisos `600`) y comprueba que funcionan. Las variables `MT_URL` y `MT_TOKEN` tienen prioridad.
- [x] `mt init PG`, en la raíz de un repo, crea `.mt` con `project: PG`. `mt` busca `.mt` hacia arriba desde el directorio actual. `--project PG` tiene prioridad. Sin proyecto, el error dice cómo ponerlo.
- [x] Al arrancar, si `GET /api` devuelve una `api_version` que el binario no conoce, avisa de que hay que actualizarlo.

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

- [x] Las historias se citan como `PG-49` o solo `49` (con el proyecto de `.mt`).
- [x] `--file -` lee de la entrada estándar. `mt show PG-49 > f.md`, editar y `mt edit PG-49 --file f.md` funciona sin tocar nada más.

**Salida**
- [x] Por defecto, texto legible: el `markdown` si lo hay o el `summary`; después los `warnings` y, al final, "Siguiente:" con los `breadcrumbs`. Igual en terminal que dentro de un agente (no cambia según haya TTY).
- [x] `--json` imprime el sobre tal cual.
- [x] Si hay error, imprime el mensaje y el `hint` por stderr y sale con código distinto de 0 (`2` para errores de uso, `1` para el resto).
- [x] `mt help` y `mt <comando> --help` describen cada comando con un ejemplo.

- [x] `bin/ci` compila y pasa `go vet` en `cli/`.

## Fuera de alcance

- Publicar binarios (GitHub Releases, Homebrew): es una acción pública y la decide Fran. Hasta entonces, se compila desde el repo.
- Un MCP: va después de M2, sobre la misma API.
- Autocompletado de la shell.

## Notas para quien lo construya

- Go lo instala Fran (también lo necesitan wflow y wtree). Añádelo a `AGENTS.md` (Stack) y haz que `bin/setup` avise si falta.
- Solo biblioteca estándar de Go, salvo que haga falta algo de verdad (p. ej. para el parseo de flags).
- La lista de comandos puede estar escrita en el binario. `GET /api` sirve para comprobar la versión, no hace falta generar el CLI a partir de ella.
- Prueba contra `bin/dev` con el proyecto Postgram de las seeds y un token creado con `mt:token`.

## Preguntas abiertas

## Cierre

Rama `dev/m2-api`, commit «Añade el CLI mt».

**Hecho**
- `cli/`: módulo Go propio (`github.com/franwer-ranger/maker_tracker/cli`), solo biblioteca estándar. `cmd/mt` es el binario y `internal/mt` la lógica: configuración, cliente HTTP, parser de argumentos y la tabla de comandos.
- `make -C cli install` (o `go install ./cli/cmd/mt`) lo deja en `$(go env GOPATH)/bin`, normalmente `~/go/bin`. **Ese directorio tiene que estar en el PATH** (en el Mac de Fran ahora no lo está). `make -C cli build` lo compila en `cli/bin/mt` (ignorado en git).
- `mt setup <url> <token>` comprueba `GET /api` y el token (`GET /api/projects`) antes de guardar `~/.config/mt/config` con permisos 600 (respeta `XDG_CONFIG_HOME`). Dice con qué actor estás conectado. `MT_URL` y `MT_TOKEN` mandan sobre el fichero.
- `mt init PG` comprueba que el proyecto existe (si hay instancia configurada) y crea `.mt` en el directorio actual. `mt` busca `.mt` hacia arriba. `--project` manda; después, la clave de la referencia (`PG-49`); después, `.mt`.
- Todos los comandos de la tabla, más `mt projects`, `mt version` y `mt help`. Cada uno, una llamada a la API. Las flags van en cualquier orden, también las globales delante del comando (`mt --project PG next`).
- Salida: el `markdown` o el `summary`, después «Avisos:» y al final «Siguiente:» con los breadcrumbs, igual con o sin TTY. `--json` imprime el sobre tal cual (sangrado, sin reordenar). Errores por stderr con el código, el mensaje y el hint; salida 2 para errores de uso y 1 para el resto.
- `mt show PG-49 > f.md` y `mt edit PG-49 --file f.md` dan «sin cambios»: lo que hay tras la marca de solo lectura (y los «Siguiente:») se ignora. `--file -` lee de stdin, y `mt comment PG-49 -` también.
- `bin/ci` añade dos pasos: `gofmt` y `make -C cli vet build`. `bin/setup` avisa si falta Go. `AGENTS.md` → Stack menciona la API y el CLI.
- Probado contra un servidor en entorno test con las seeds de Postgram: setup, init, todas las lecturas, start/done/release, comment, decide, create/edit/move/reorder, milestone create/edit/reorder/close/reopen, brief, y los errores (sin proyecto, token malo, sin red, historia que no existe, opción desconocida).

**Decisiones**
- La versión de la API viaja en una cabecera (`X-MT-API-Version`) en todas las respuestas, en lugar de llamar a `GET /api` antes de cada comando: así cada comando sigue siendo una sola llamada. Si no la conoce, `mt` avisa por stderr de que hay que actualizarlo. `mt setup` sí llama a `GET /api`.
- `GET /api/projects` devuelve también `actor` (para el mensaje de `mt setup`).
- `mt create --file f.md --milestone M2`: las opciones sueltas mandan sobre el frontmatter del fichero (cambio pequeño en la API de la #018). `mt create` ya no devuelve el markdown de la historia, solo el summary («PG-57 creada en M3 · …»); se lee con `mt show`.
- `mt init` escribe `.mt` en el directorio actual, no busca la raíz del repo de git.

**Fuera**
- `--claude` en `mt init`: es la #020.
