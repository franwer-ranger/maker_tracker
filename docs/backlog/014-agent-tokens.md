---
number: 14
title: Tokens de agente
milestone: M2
state: ready
claimed_by:
mockup:
labels: [api, agentes]
blocked_by: []
---

## Contexto

En M2 los agentes hablan con Maker Tracker por la API. El token sirve para saber **quién** hace cada cosa, no como seguridad: la app solo es accesible por la red local o Tailscale (`PRODUCT.md` → Decisiones). Fran decidió el 2026-10-16 que los tokens se crean con un comando en el servidor, sin pantalla. La UI de agentes llegará más adelante.

## Historia

Como Fran, quiero darle a cada agente su token con un comando, para que todo lo que haga por la API quede a su nombre.

## Criterios de aceptación

- [ ] `Actor` guarda `token_digest` (SHA-256 del token, nunca el token en claro). Un token tiene el prefijo `mt_` seguido de 32 caracteres aleatorios.
- [ ] `bin/rails "mt:token[claude]"` imprime el token **una sola vez** y cómo usarlo (`mt setup <url> <token>`). Si el actor no existe, lo crea como `agent`.
- [ ] Repetir el comando para el mismo actor genera un token nuevo y el anterior deja de valer.
- [ ] También vale para el actor humano (`mt:token[fran]`), para que Fran pueda usar `mt` desde su terminal.
- [ ] `bin/rails mt:tokens` lista los actores con token y cuándo se usó cada uno por última vez (`token_used_at`), sin enseñar el token.
- [ ] `Actor.authenticate(token)` devuelve el actor o `nil`, comparando en tiempo constante.
- [ ] Funciona igual dentro del contenedor: `docker compose exec -u rails app bin/rails "mt:token[claude]"`.
- [ ] `bin/ci` en verde.

## Fuera de alcance

- Pantalla de agentes y tokens.
- Permisos por token (solo lectura, por proyecto…): todos los tokens pueden hacer lo mismo.
- Caducidad de tokens.

## Notas para quien lo construya

- Crear un token no es un evento de proyecto (no tiene proyecto), así que no se registra en `Event`.

## Preguntas abiertas

## Cierre
