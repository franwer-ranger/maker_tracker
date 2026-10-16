---
number: 21
title: La v2 en la torre, con API para los agentes
milestone: M2
state: done
claimed_by: self-hosting
mockup:
labels: [selfhost]
blocked_by: [11, 15]
---

## Contexto

Es de la vertiente de **self-host**. La torre ya corre Maker Tracker con `docker compose` y `tailscale serve`, accesible solo desde la tailnet. En M2 tiene que correr la v2 (pantallas de M1 y API) y los agentes del Mac tienen que poder usarla con `mt`. Es el paso que deja a Maker Tracker construirse con Maker Tracker (#022).

## Historia

Como Fran, quiero la v2 en la torre y mis agentes conectados a ella desde el Mac, para dejar de llevar el backlog en ficheros.

## Criterios de aceptación

- [x] La torre corre `main` con M1 terminado (#007–#011) y la API (#015). Se ha actualizado con el comando de "Updating" de `docs/SELF_HOSTING.md`, sin pasos a mano fuera de la guía.
- [x] `docs/SELF_HOSTING.md` tiene una sección **Agents**: crear un token con `docker compose exec`, instalar `mt` desde el repo y `mt setup https://<host>.ts.net <token>`.
- [x] Desde el Mac, con Tailscale: `mt setup` y `mt context` contra la torre funcionan para `claude` y para `fran`.
- [x] Se repiten las comprobaciones de red de la guía: sin Tailscale, la torre no responde, tampoco en `/api`.
- [x] Copia de seguridad antes de actualizar y restaurada en otra carpeta para comprobarla.

## Fuera de alcance

- Publicar binarios de `mt`.
- Copias fuera de la torre (aparcado).

## Notas para quien lo construya

- Si M1 no está terminado cuando la API esté lista, se puede desplegar antes: lo importante es que `mt` funcione contra la torre.

## Preguntas abiertas

## Cierre

Hecha el 2026-10-16 por self-hosting, en `selfhost/m2`.

- **Torre:** actualizada de `46a97bd` a `5238ed5` (M1 y M2 sin la #021) con `git pull && docker compose up -d --build`, sin más pasos. Los dos contenedores, sanos. Por SSH vía Tailscale (`torre-ts`), tras añadir su clave de host comprobando que coincide con la de la LAN.
- **Pantallas:** Tablero, Roadmap, Historia y Brief responden 200 por `https://omarchy-tower.….ts.net` y se ven bien (capturas con Chrome headless) en el proyecto `prueba` (`PR`), que Fran creó para pruebas. `Postgram` no se tocó.
- **Agentes:** tokens de `claude` y `fran` creados con `docker compose exec -u rails app bin/rails "mt:token[…]"` (funciona dentro del contenedor, como pedía Desarrollo). En el Mac: `make -C cli install`, `mt setup` (como `claude`), `mt init PR` y `mt context` con los dos tokens. Escribiendo (`mt milestone create`, `create`, `start`, `comment`, `done`) cada acción queda a nombre de su actor, en `mt show` y en la UI.
- **Red:** desde la LAN, ni la app ni `/api` responden (3002, 80, 443). En la torre la app solo escucha en `127.0.0.1:3002` y `tailscale serve status` dice `(tailnet only)`. La prueba desde el móvil con datos no se repitió: la red no ha cambiado desde la del 2026-10-16.
- **Copia:** `bin/backup` antes de actualizar (`20261016-151825`), copiada al Mac y comprobada fuera de la torre: `integrity_check` ok, 12 migraciones y sus tablas.
- **Guía:** sección Agents en `docs/SELF_HOSTING.md` y `/api` en la comprobación de red. `/cli/` va a `.dockerignore` (la imagen se construye igual, comprobado).
- **Quedó fuera:** `mt` se instala en `~/go/bin`, que no está en el PATH del Mac de Fran; la guía lo dice. Avisos para Desarrollo en el inbox.
