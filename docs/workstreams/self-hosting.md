# Vertiente · Self-host y distribución

> Lee antes [`README.md`](README.md) (reglas comunes), [`../PRODUCT.md`](../PRODUCT.md) (sobre todo Decisiones) y [`../DESIGN.md`](../DESIGN.md) (para la landing).

## Tu papel

Llevas Maker Tracker de "funciona en el portátil" a "**cualquiera puede autoalojarlo, y Fran ya lo tiene en su torre**". Son dos caras del mismo trabajo, y se hacen juntas a propósito:

1. **La instancia de Fran**: Maker Tracker corriendo en su torre, accesible solo desde su red local o Tailscale, con copias de seguridad.
2. **La experiencia pública**: la guía para autoalojarlo, el repo listo para abrirse (MIT) y la landing pública.

La regla que las une: **montas la torre siguiendo solo la guía que escribes.** La torre es el primer usuario de `docs/SELF_HOSTING.md`; si la guía no basta para montarla, la guía está mal.

## Es tuyo

`Dockerfile`, `config/deploy*`, `.kamal/`, scripts de despliegue y backup, `docs/SELF_HOSTING.md`, `README.md`, `LICENSE` y el repo de la landing (aparte de este). Si necesitas tocar configuración de la app (`config/environments/production.rb`, hosts, SSL), hazlo con cambios mínimos y avísalo en el inbox para Desarrollo.

## Cuidado: esto toca cosas reales

- La torre es la máquina de casa de Fran, que además corre **Home Assistant** (Maker Tracker va como proyecto aparte, sin interferir). **Confirma con Fran antes de instalar, abrir puertos, crear servicios o borrar nada en ella.**
- Hacer público el repo, publicar la landing o comprar o configurar un dominio son acciones públicas: **las decide Fran.** Tú las preparas y preguntas.
- Nunca se commitea `config/master.key` ni secretos. En producción la clave va por `RAILS_MASTER_KEY` o un fichero fuera del repo.

## Estado de partida

- Hay un `Dockerfile` de producción generado por Rails (Ruby 3.4.8). No hay Kamal ni configuración de despliegue.
- Producción usa SQLite (`storage/*.sqlite3`) y `solid_cable` (`storage/production_cable.sqlite3`): todo el estado vive en `storage/`, que debe ser un volumen persistente.
- El repo es **privado** (`github.com/franwer-ranger/maker_tracker`). No hay `LICENSE` ni `README.md`. El historial está limpio de `master.key` y `.env` (revisado el 2026-10-16).
- El código es la v1, todavía con Devise. Se despliega igual: el objetivo ahora es tener el camino montado, no esperar a la v2.
- La landing A está diseñada en Paper (página `Landing`, artboard `Landing · Ship happens`) y descrita en `DESIGN.md`.

## Primeras tareas, en orden

1. **Preguntar a Fran lo que no sabemos de la torre**: sistema operativo, si tiene Docker, cómo entras (SSH por Tailscale, usuario), cómo corre Home Assistant (para no chocar en puertos ni recursos) y dónde guardar las copias de seguridad.
2. **Elegir el camino de instalación oficial** y proponérselo a Fran con una recomendación. Tiene que servir a la vez para la torre y para cualquiera que siga la guía. Candidatos: Kamal 2 (lo que trae Rails 8; con registro local no necesita Docker Hub) o una imagen con `docker compose`. Ojo: la landing promete `git clone … && bin/setup`, pero eso arranca la app **en desarrollo**. El comando que acabe siendo oficial tiene que coincidir con lo que diga la landing: si cambia, avisa a Producto en el inbox.
3. **Desplegar la app actual en la torre**, solo accesible por red local y Tailscale (valorar `tailscale serve` para tener HTTPS dentro de la tailnet), con `storage/` persistente. Cuando esté, **confirma en el inbox que no es accesible desde fuera**: Desarrollo lo necesita para quitar el login (dependencia 1 del README).
4. **Copias de seguridad de SQLite desde el primer día** (Litestream o un volcado periódico con `sqlite3 .backup`), probando que se restauran.
5. **Escribir `docs/SELF_HOSTING.md`** mientras haces 2–4: requisitos, instalación, actualización, copias de seguridad, restauración y tokens de agentes (cuando existan).
6. **Preparar el repo para abrirse**: `LICENSE` (MIT), `README.md` en inglés (qué es, captura, instalación en pocas líneas, enlace a la guía) y una última revisión de secretos. Luego pregunta a Fran si se hace público y con qué nombre.
7. **Construir la landing** en un repo propio y público (Astro o similar, salida estática), validada por Producto el 2026-10-16: textos y enlaces en `DESIGN.md` → Landing. Tokens y fuentes de `DESIGN.md`, fuentes alojadas en el propio sitio e iconos Heroicons en SVG en línea. Crear el repo, publicarla y el dominio los decide Fran: prepáralo y pregunta.

## En M2

- MT-21 La v2 en la torre, con API para los agentes, fue tuya (hecha): la torre con la v2 y `mt` del Mac conectado a ella. Puede ir en cuanto exista la API (#015), aunque M1 no esté terminado.

## Cómo sabes que vas bien

- Alguien que no es Fran podría autoalojarlo leyendo solo `docs/SELF_HOSTING.md`.
- Actualizar la torre a una versión nueva es un solo comando.
- Una copia de seguridad se ha restaurado al menos una vez de verdad.
- Lo que promete la landing es exactamente lo que pasa al seguirla.
