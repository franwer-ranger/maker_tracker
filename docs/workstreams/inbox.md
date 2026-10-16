# Inbox entre vertientes

> Preguntas, propuestas y avisos entre vertientes o para Fran. Formato en [`README.md`](README.md#propuestas-y-preguntas). Lo nuevo va arriba. Cuando algo se resuelve, se marca con ✅ y dónde quedó la decisión; no se borra.

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
