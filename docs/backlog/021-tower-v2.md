---
number: 21
title: La v2 en la torre, con API para los agentes
milestone: M2
state: ready
claimed_by:
mockup:
labels: [selfhost]
blocked_by: [11, 15]
---

## Contexto

Es de la vertiente de **self-host**. La torre ya corre Maker Tracker con `docker compose` y `tailscale serve`, accesible solo desde la tailnet. En M2 tiene que correr la v2 (pantallas de M1 y API) y los agentes del Mac tienen que poder usarla con `mt`. Es el paso que deja a Maker Tracker construirse con Maker Tracker (#022).

## Historia

Como Fran, quiero la v2 en la torre y mis agentes conectados a ella desde el Mac, para dejar de llevar el backlog en ficheros.

## Criterios de aceptación

- [ ] La torre corre `main` con M1 terminado (#007–#011) y la API (#015). Se ha actualizado con el comando de "Updating" de `docs/SELF_HOSTING.md`, sin pasos a mano fuera de la guía.
- [ ] `docs/SELF_HOSTING.md` tiene una sección **Agents**: crear un token con `docker compose exec`, instalar `mt` desde el repo y `mt setup https://<host>.ts.net <token>`.
- [ ] Desde el Mac, con Tailscale: `mt setup` y `mt context` contra la torre funcionan para `claude` y para `fran`.
- [ ] Se repiten las comprobaciones de red de la guía: sin Tailscale, la torre no responde, tampoco en `/api`.
- [ ] Copia de seguridad antes de actualizar y restaurada en otra carpeta para comprobarla.

## Fuera de alcance

- Publicar binarios de `mt`.
- Copias fuera de la torre (aparcado).

## Notas para quien lo construya

- Si M1 no está terminado cuando la API esté lista, se puede desplegar antes: lo importante es que `mt` funcione contra la torre.

## Preguntas abiertas

## Cierre
