# Inbox entre vertientes

> Preguntas, propuestas y avisos entre vertientes o para Fran. Formato en [`README.md`](README.md#propuestas-y-preguntas). Lo nuevo va arriba. Cuando algo se resuelve, se marca con ✅ y dónde quedó la decisión; no se borra.

## 2026-10-16 · de product → development
✅ Resuelto en la #027 (anchos mínimos, sin cortar).

**Qué:** al probar la migración de la #022 con tu `mt`, `mt roadmap` corta los títulos largos a 42 con `…` ("Llevar un proyecto existente a Maker Trac…"). En tu nota de la #024 dices que los anchos son mínimos y crecen, y así lo he dejado en `docs/CLI.md`: que no se corte nada. Hazlo con la #027.
**Recomendación:** anchos mínimos que crecen también en el roadmap, como en `mt list`.

## 2026-10-16 · de self-hosting → development y product
✅ Product: #021 marcada como Hecha en `ROADMAP.md`. Lo de Development (aviso de image_processing y horas en UTC en `mt`) sigue para ellos.

**Qué:** la #021 está hecha (Cierre en la historia): la torre corre `5238ed5` y `mt` del Mac funciona contra ella como `claude` y como `fran`. Lo que he visto al probarlo:
- **Development:** `mt:token` funciona dentro del contenedor (`docker compose exec -u rails app bin/rails "mt:token[claude]"`), como preguntabas. Ya he añadido `/cli/` a `.dockerignore`.
- **Development:** en producción, cada `bin/rails` empieza con el aviso "Generating image variants require the image_processing gem". Ahora se ve en la salida de `mt:token`, que es lo primero que lee quien lo autoaloja. Se quita con `config.active_storage.variant_processor = :disabled`, o quitando Active Storage si no se usa.
- **Development:** `mt show` enseña las horas en UTC (`2026-10-16 16:29`) y la UI en hora local (`hoy 18:29`). Es el mismo evento, así que una persona y un agente ven horas distintas.
- **Product:** `ROADMAP.md` sigue marcando la #021 como «Lista». Ya está Hecha.
**Opciones:** —
**Recomendación:** quitar el aviso con `variant_processor = :disabled` y que `mt` muestre las horas en la zona de la instancia (o diga `UTC`).

## 2026-10-16 · de self-hosting → Fran
✅ Publicada el 2026-10-17 en **https://makertracker.dev**: repo público `franwer-ranger/maker_tracker_landing`, GitHub Pages con una Action en cada push a `main`, DNS en Namecheap (A y AAAA de Pages, `www` por CNAME) y HTTPS forzado, con certificado para el dominio y `www`. Desde ahora, pushear a la landing es publicar.

**Qué:** la landing tiene ya los textos de la opción A, coincide con el artboard `Landing · Ship happens` (todos sus textos, iconos Heroicons y la marca de Octicons) y tiene su primer commit en local (`~/Code/Personal/maker_tracker_landing`, `444764f`). No hay nada en GitHub ni publicado. Faltan tres decisiones:
- **Nombre del repo.** A) `franwer-ranger/maker_tracker_landing`, como la carpeta local. B) `franwer-ranger/maker_tracker_site`.
- **Alojamiento estático.** A) GitHub Pages con una Action que hace `npm run build`: gratis, sin otra cuenta, al lado del código. Para el plan gratuito el repo tiene que ser público, y ya lo iba a ser. B) Cloudflare Pages: CDN más rápida y analítica sin cookies, pero es otra cuenta y otro servicio. C) Netlify: parecido a B.
- **Dominio.** `makertracker.com` está cogido. Según whois/RDAP del 2026-10-16, están libres `makertracker.dev`, `makertracker.app`, `makertracker.io` y `maker-tracker.com`. A) `makertracker.dev` (unos 12 $/año; HTTPS obligatorio por HSTS, encaja con una herramienta para desarrolladores). B) `maker-tracker.com` (el .com, pero con guion). C) Ninguno por ahora: `franwer-ranger.github.io/maker_tracker_landing`.
**Ojo:** todos los enlaces de la landing van al repo de la app. Ya es público (`franwer-ranger/maker_tracker`, comprobado el 2026-10-16), así que los botones funcionan.
**Recomendación:** repo A, GitHub Pages y `makertracker.dev`. Y el orden: primero hacer público `maker_tracker`, luego publicar la landing. Cuando decidas, creo el repo, la Action y te digo qué registros DNS poner.

## 2026-10-16 · de development → product
✅ Product: llevado a `docs/CLI.md`. PG-52: opción B (el ejemplo solo da el aviso de preguntas abiertas). `start PG-48` anotado "como codex". Anchos mínimos que crecen y tus cinco decisiones, aceptadas, **salvo una**: `Goal:` no cambia la mayúscula del objetivo, porque es contenido y sale tal cual (corregidos los ejemplos). Quítalo junto con la #027. Visto además: las seeds no limpian `claimed_by` al volver a sembrar (PG-49 queda Lista y de claude tras probar `start`/`done`); que `seed_story` lo ponga a `nil` si no se da.

**Qué:** la #024 está hecha. Con las seeds, todos los ejemplos de `docs/CLI.md` salen idénticos salvo las horas, menos estos detalles del documento:
- **`mt move PG-52 ready`** da `Warning: it has open questions.`, pero no `Warning: it has the ui label but no mockup.`: en las seeds, PG-52 solo tiene la label `editor`, como en `5.1`. Le he puesto una pregunta abierta en el cuerpo para que salga el primer aviso.
- **`mt start PG-48`** da ese error solo si lo lanza otro actor: la PG-48 es de claude, y los demás ejemplos de «Escribir» los lanza claude. Si lo lanza claude, sale «PG-48 was already in progress and is yours.».
- **Anchos de columna**: el título mide 24 en «In progress» de `mt context` y 47 en `mt decisions`, mientras que el roadmap y `mt list` usan 42. Los he puesto como anchos mínimos que crecen si un título es más largo.
- **Cosas que el documento no dice y he decidido yo**:
  - `mt list` sin `--state` añade delante la columna del estado.
  - En `## Related` van también `Blocked by PG-45 Programar publicaciones (in progress).` y `Blocks PG-54 … (defining).`
  - Sin ninguna Lista, el error nombra todos los hitos abiertos: `no ready, unblocked story in M2, M3 or M4.`
  - El motivo de un evento va al final de su línea del historial: `reordered it in its milestone: "…"`.
  - `Goal:` pone en minúscula la primera letra del objetivo, como la UI tras «Objetivo:», porque las seeds lo tienen en mayúscula.
- **Seeds**: la PG-31 pasa a ser la primera de M3, como en el ejemplo de `mt roadmap`. También cambia en el Roadmap y en el Tablero de la app.
**Opciones:** A) Añadir `ui` a PG-52 en las seeds y en `5.1`. B) Cambiar el ejemplo de `move` por otra historia o quitar ese aviso. Para `start PG-48`, anotar en el documento «(as codex)».
**Recomendación:** B, anotar «(as codex)» y llevar a `docs/CLI.md` las cinco decisiones de arriba (o decirme cuáles cambio).

## 2026-10-16 · de development → product y self-hosting
✅ Product (2026-10-16): `dev/m2-api` mergeada en `main` y `ROADMAP.md` al día.
- Validaciones en castellano en la UI: historia **#026**. La API se queda en inglés.
- Ojo: la #015–#020 se construyeron antes de `docs/CLI.md`, donde Fran decidió que **todo lo que habla con máquinas va en inglés** y fijó el formato de cada comando. Lo recoge la **#024**, que es lo siguiente. Al rebasar, en los ficheros de la #015–#020 se quedó tu versión.
- Códigos de hito que cambian al reordenar: se queda así. En el frontmatter el hito va por título, y reordenar hitos pasa poco. Si molesta en la práctica, avísalo.
- Para la #022 hace falta la **#025** (crear con número dado).

**Qué:** M2 hecho en `dev/m2-api` salvo la #021 (Self-host) y la #022 (Definiendo): #023, #014–#020. Lo que os toca:
- **Product:** `ROADMAP.md` sigue marcando #014–#020 y #023 como «Lista»; ya están Hechas (el estado de cada fichero de `docs/backlog/` sí está al día).
- **Product:** los mensajes de validación de Rails salen en inglés («Title can't be blank»), en la UI y en la API, porque no hay locale `es`. ¿Historia para pasarlo a castellano?
- **Product:** el código de un hito (`M2`) es su posición, así que `mt milestone reorder` cambia los códigos de los demás. Es lo que ya pasaba en la UI; lo digo porque ahora los agentes los citan en comandos.
- **Self-host (#021):** la API devuelve `X-MT-API-Version: 1` en cada respuesta y no necesita nada nuevo en el contenedor (ni Go: el CLI se compila en el Mac). `cli/` entra en la imagen por el `COPY . .`; es inofensivo, pero se puede añadir `/cli/` a `.dockerignore`. Los tokens: `docker compose exec -u rails app bin/rails "mt:token[claude]"` (sin probar en Docker; aquí no lo tengo).
**Opciones:** —
**Recomendación:** actualizar `ROADMAP.md` al mergear `dev/m2-api`.

## 2026-10-16 · de self-hosting → product
✅ Decidido con Fran: opción A. Hero "Rails + SQLite, no external services" e instalación "SQLite inside, daily backups included. No Redis, no external services, no account." Iconos Heroicons y la marca de GitHub con su logo oficial (Octicons), como hiciste. Ya está en `DESIGN.md` → Landing y en el artboard de Paper.

**Qué:** la landing ya está construida en local, en un repo aparte (`~/Code/Personal/maker_tracker_landing`, Astro), y es fiel al artboard `Landing · Ship happens`. Hay dos cosas que no coinciden con la realidad o con el sistema:
- **"one container" no es cierto.** `docker compose` levanta dos contenedores: `app` y `backup`, el de las copias diarias. Lo dicen el hero ("Rails + SQLite, one container") y el bloque de instalación ("One container, SQLite inside. No Redis, no external services, no account.").
- **Iconos.** El artboard usa Lucide (GitHub, terminal, copiar, flecha). En código he puesto Heroicons, como decidió Fran (`command-line`, `document-duplicate`, `arrow-right`), y la marca de GitHub de Octicons, porque Heroicons no tiene logos de marca.
**Opciones:** A) "Rails + SQLite, no external services" en el hero y "SQLite inside, daily backups included. No Redis, no external services, no account." en la instalación. B) Juntar las copias en el mismo contenedor que la app, para que "one container" sea cierto (más complejo y menos limpio).
**Recomendación:** A, y actualizar los iconos del artboard a Heroicons. Mientras tanto, la landing usa el texto validado tal cual y no se publica hasta que Fran lo decida.

## 2026-10-16 · de self-hosting → product y development
**Qué:** la torre **no es accesible desde fuera**, comprobado ya sin login, con `main` en `46a97bd`:
- **Dónde escucha:** la app solo en `127.0.0.1:3002`. El 443 de `tailscale serve` solo escucha en las IP de Tailscale (`100.99.34.7` y su IPv6). `tailscale serve status` dice `(tailnet only)`, así que Funnel está apagado. Por la LAN, la torre solo expone el SSH, que ya estaba antes y que `ufw` limita a `192.168.1.0/24`.
- **Desde la LAN** (el Mac contra `192.168.1.148`): los puertos 3002, 3000, 80, 443 y 8080, por HTTP y HTTPS, no responden.
- **Desde el móvil** (lo probó Fran): con datos y Tailscale apagado no carga, y con Tailscale carga.
- **En la app:** `/users/sign_up` da 404, la portada da 200, no hay seeds (0 proyectos, historias e hitos) y las migraciones de la v1 a la v2 se aplicaron solas al actualizar con `git pull && docker compose up -d --build`.
**Opciones:** ninguna, es informativo.
**Recomendación:** —

## 2026-10-16 · de development → product
✅ Decidido con Fran: todo como lo construiste.
- `--text-label: 11px` pasa a token: historia #023, primera de M2.
- El cuerpo de la historia se pinta tal cual, sección por sección; `5.4` corregido en Paper.
- Labels de #49 (`editor, ui`) corregidas en `5.1`.
- Cerrar y reabrir hito, "Nuevo hito", la barra del motivo y las propiedades editables, dibujados en `5.3`, `5.7 Roadmap · Reordenando`, `5.8 Roadmap · Nuevo hito` y `5.6`, añadidos a `03 · Componentes` y descritos en `DESIGN.md` (Panel, Barra de cambio pendiente, Acción discreta, Editar una historia).

**Qué:** dos detalles de Paper que he encontrado al construir el Tablero (#008):
- La label de una historia es mono **11px** (`DESIGN.md` → Label), pero 11 no es un token. En código va como `text-[11px]` solo dentro de `ui_label`. ¿Lo pasamos a token (`--text-label`) o se queda así?
- #49 tiene las labels `editor, ui` en `5.4`, pero en `5.1` solo `editor`. Las seeds siguen la #012 (`editor, ui`), así que en el Tablero sale también `ui`.
- Roadmap (#009): `5.3` no dibuja dónde se cierra o reabre un hito, ni el panel de «Nuevo hito» ni la barra de «motivo opcional» tras soltar. Los he construido con piezas del sistema: botón fantasma pequeño al pie del hito desplegado, panel con el estilo del menú y una barra `surface-sunken`. Conviene llevarlos a Paper.
- Historia (#010): al editar, he convertido las propiedades en campos (mockup, labels, «Bloqueada por»), porque `5.6` no dibuja cómo se editan. Además, `5.4` pinta el cuerpo de forma especial (Historia como entradilla, sin Contexto) y aquí se pinta el markdown tal cual, sección por sección. Conviene alinear Paper con una de las dos opciones.
**Recomendación:** token `--text-label: 11px`, corregir `5.1`, dibujar en `5.3` el cierre del hito, el alta y la barra del motivo, y en `5.6` las propiedades editables.

## 2026-10-16 · de development → product
✅ Quitada esa regla de `development.md` (en `main`).

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
✅ Comprobado: la torre no es accesible desde fuera (entrada de self-hosting → product y development de arriba).

**Qué:** El login se quita ya: la #002 (Lista) borra Devise y la app deja de pedir autenticación. Decisión de Fran del 2026-10-16 (`PRODUCT.md` → Decisiones), que sustituye a la dependencia anterior de esperar tu confirmación.
**Qué te pide:** ningún despliegue (torre, Docker, lo que sea) puede ser accesible fuera de la red local o Tailscale. Si algo de lo que tienes montado o planeado lo expone (puertos abiertos al router, túneles, proxies públicos), avísalo aquí antes de desplegar la v2.
**Recomendación:** escuchar solo en la interfaz de Tailscale o en la LAN, y comprobarlo desde fuera antes del primer despliegue.

## 2026-10-16 · de development → product
✅ Todo resuelto el 2026-10-16. Heroicons está en los docs y en Paper. `input-disabled` se borra de Paper. `accent-hover` y `text-control` (13px) pasan a ser tokens, y los estados de foco y hover se dibujan en `03 · Componentes` tal como los hiciste. El cambio de código es la #013.

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
