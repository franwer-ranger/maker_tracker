---
number: 14
title: Tokens de agente
milestone: M2
state: done
claimed_by: development
mockup:
labels: [api, agentes]
blocked_by: []
---

## Contexto

En M2 los agentes hablan con Maker Tracker por la API. El token sirve para saber **quién** hace cada cosa, no como seguridad: la app solo es accesible por la red local o Tailscale (`PRODUCT.md` → Decisiones). Fran decidió el 2026-10-16 que los tokens se crean con un comando en el servidor, sin pantalla. La UI de agentes llegará más adelante.

## Historia

Como Fran, quiero darle a cada agente su token con un comando, para que todo lo que haga por la API quede a su nombre.

## Criterios de aceptación

- [x] `Actor` guarda `token_digest` (SHA-256 del token, nunca el token en claro). Un token tiene el prefijo `mt_` seguido de 32 caracteres aleatorios.
- [x] `bin/rails "mt:token[claude]"` imprime el token **una sola vez** y cómo usarlo (`mt setup <url> <token>`). Si el actor no existe, lo crea como `agent`.
- [x] Repetir el comando para el mismo actor genera un token nuevo y el anterior deja de valer.
- [x] También vale para el actor humano (`mt:token[fran]`), para que Fran pueda usar `mt` desde su terminal.
- [x] `bin/rails mt:tokens` lista los actores con token y cuándo se usó cada uno por última vez (`token_used_at`), sin enseñar el token.
- [x] `Actor.authenticate(token)` devuelve el actor o `nil`, comparando en tiempo constante.
- [x] Funciona igual dentro del contenedor: `docker compose exec -u rails app bin/rails "mt:token[claude]"`.
- [x] `bin/ci` en verde.

## Fuera de alcance

- Pantalla de agentes y tokens.
- Permisos por token (solo lectura, por proyecto…): todos los tokens pueden hacer lo mismo.
- Caducidad de tokens.

## Notas para quien lo construya

- Crear un token no es un evento de proyecto (no tiene proyecto), así que no se registra en `Event`.

## Preguntas abiertas

## Cierre

Rama `dev/m2-api`, commit «Añade los tokens de agente».

**Hecho**
- Migración: `actors.token_used_at` e índice único en `token_digest`.
- `Actor#regenerate_token!` crea `mt_` + 32 alfanuméricos (`SecureRandom.alphanumeric`), guarda solo el SHA-256 y devuelve el token en claro. Renovarlo invalida el anterior y pone `token_used_at` a nil.
- `Actor.authenticate(token)` busca por el digest y compara con `secure_compare`. Devuelve nil sin token, sin prefijo `mt_` o si no existe.
- `Actor#token_used!` lo usará la API (#015): escribe `token_used_at` como mucho una vez por minuto.
- `bin/rails "mt:token[claude]"` (en `lib/tasks/mt.rake`) crea el actor como `agent` si no existe, imprime el token una vez y `mt setup <url> <token>`. Si existe `MT_URL`, la usa en lugar de `<url>`. Vale igual para `fran` (humano).
- `bin/rails mt:tokens` lista nombre, tipo y último uso.

**Decisiones**
- El nombre se normaliza como en `Actor` (minúsculas, sin espacios), así que `mt:token[Claude]` es el mismo actor que `claude`.

**Sin comprobar**
- Dentro del contenedor (`docker compose exec -u rails app …`): no tengo Docker aquí. Es una tarea rake normal sin dependencias nuevas, así que debería funcionar igual; lo comprueba Self-host en la #021.
