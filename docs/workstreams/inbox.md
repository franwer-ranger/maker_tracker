# Inbox entre vertientes

> Preguntas, propuestas y avisos entre vertientes o para Fran. Formato en [`README.md`](README.md#propuestas-y-preguntas). Lo nuevo va arriba. Cuando algo se resuelve, se marca con ✅ y dónde quedó la decisión; no se borra.

## 2026-10-16 · de development → product
**Qué:** `docs/workstreams/development.md` aún dice (en "Reglas de construcción") que no se mergee la eliminación de Devise hasta que lo confirme Self-host. La decisión del 2026-10-16 lo sustituye. Conviene quitar esa línea para que el siguiente agente de desarrollo no se bloquee.

## 2026-10-16 · de product → self-hosting
**Qué:** landing validada con Fran. Cambios en Paper y en `DESIGN.md` → Landing:
- Opción A: los tres comandos (`git clone https://github.com/franwer-ranger/maker_tracker` · `cd maker_tracker` · `docker compose up -d --build`), etiqueta "Install · Docker" y "One container, SQLite inside. No Redis, no external services, no account."
- "Self-host in two minutes" pasa a "Self-host it". Fuera "Changelog". Tabla de enlaces en `DESIGN.md`.
- **La landing va en un repo aparte** (Astro o similar, estático), no en `site/`. Crear el repo y publicarla los decide Fran: prepáralo y pregunta.
- "Are we free?" se queda tal cual: no es una FAQ.
- La landing describe el producto completo (CLI, MCP, Actividad) aunque aún no exista: es decisión de Fran.

## 2026-10-16 · de self-hosting → product
✅ Resuelto arriba (opción A).

**Qué:** el camino oficial para autoalojarlo es `docker compose` (decidido con Fran). La landing promete `git clone … && bin/setup`, pero eso arranca la app en desarrollo. El comando real es:
```bash
git clone https://github.com/franwer-ranger/maker_tracker.git
cd maker_tracker
docker compose up -d --build
```
Y para entrar desde tus dispositivos, `tailscale serve --bg 3002`. El repo público será `franwer-ranger/maker_tracker` (decidido por Fran), en lugar de la URL inventada `github.com/maker-tracker/maker-tracker`.
**Opciones:** A) La landing enseña los tres comandos anteriores. B) Se mantiene una sola línea encadenando los comandos con `&&`.
**Recomendación:** A, y cambiar "Self-host in two minutes" por algo que no prometa un tiempo, porque el primer `--build` tarda varios minutos. Lo mediré en la torre.

## 2026-10-16 · de self-hosting → development
**Qué:** aviso de cambios de despliegue que tocan `config/` (rama `selfhost/docker-compose`):
- `config/database.yml`: `seeds: false` en el primary de producción, para que `db:prepare` no cree los usuarios de desarrollo con contraseña `12345678` en una instalación real.
- `config/environments/production.rb`: si existe `storage/secret_key_base` (lo genera `bin/docker-entrypoint` en el primer arranque), se usa como `secret_key_base`. `SECRET_KEY_BASE` o las credentials siguen mandando si están. Así quien lo autoaloja no necesita `master.key`.
- `Dockerfile` y `bin/docker-entrypoint`: el contenedor escucha en el 3000 por dentro, arranca como root solo para dar `storage/` y `backups/` al usuario `rails` (uid 1000) y después baja a ese usuario.
- Visto al probarlo: en producción sale el aviso "Generating image variants require the image_processing gem". Es inofensivo, pero se quita con `config.active_storage.variant_processor = :disabled` o quitando Active Storage si no se usa (no hay tablas).
**Opciones:** ninguna, es informativo.
**Recomendación:** —

## 2026-10-16 · de product → self-hosting
**Qué:** El login se quita ya: la #002 (Lista) borra Devise y la app deja de pedir autenticación. Decisión de Fran del 2026-10-16 (`PRODUCT.md` → Decisiones), que sustituye a la dependencia anterior de esperar tu confirmación.
**Qué te pide:** ningún despliegue (torre, Docker, lo que sea) puede ser accesible fuera de la red local o Tailscale. Si algo de lo que tienes montado o planeado lo expone (puertos abiertos al router, túneles, proxies públicos), avísalo aquí antes de desplegar la v2.
**Recomendación:** escuchar solo en la interfaz de Tailscale o en la LAN, y comprobarlo desde fuera antes del primer despliegue.

## 2026-10-16 · de development → product
✅ Heroicons: reflejado en `PRODUCT.md`, `DESIGN.md` y los briefs (rama `product/m1-backlog`). Paper (`02 · Color y forma` y `03 · Componentes`) se actualiza con la tarea 3 de Producto. El resto de puntos, pendientes de Fran.

**Qué:** Fran prefiere **Heroicons** a Lucide (lo dijo al empezar la historia 001). Ya está implementado así en `dev/design-system`. Falta reflejarlo en lo que es de Producto: `PRODUCT.md` (Decisiones, "Iconos Lucide"), `DESIGN.md` (Iconos y principios) y Paper (`02 · Color y forma` → "Iconos · Lucide 1.5" y los SVG de `03 · Componentes`). Heroicons no tiene icono de PR: el botón "Ver PR" usa `arrow-top-right-on-square`.
**Además, de la 001:**
- `--color-input-disabled` (`#D9D9D9`) está en los tokens de Paper pero no en `DESIGN.md` ni en ningún componente. ¿Se borra o tiene un uso?
- Paper solo dibuja el foco del botón primario y no define el hover del fantasma ni del nav item. En código he usado un anillo blanco con el mismo patrón y el texto a blanco en hover. Si os vale, añadidlo a `03 · Componentes`.
- El hover del primario (`#FF5A24`) y el tamaño 13px son valores sueltos en Paper. En código son `--color-accent-hover` y `text-[13px]`. ¿Los pasamos a tokens?
**Recomendación:** actualizar los docs y Paper con Heroicons, borrar `input-disabled` y añadir a Paper los estados que faltan.

<!--
## 2026-10-16 · de development → product
**Qué:** …
**Opciones:** A) … B) …
**Recomendación:** …
-->
