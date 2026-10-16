---
number: 10
title: Historia · ver y definir una historia
milestone: M1
state: defining
claimed_by:
mockup: https://app.paper.design/file/01M50CA4S5CN4Z8ERVW36XWDHF/p-8-0
labels: [ui]
blocked_by: [7]
---

## Contexto

Aquí es donde Fran define: escribe el markdown con la IA, enlaza el mockup, marca dependencias y la pasa a Lista. La historia también cuenta lo que ha pasado: historial y comentarios de los agentes. Artboard v2: `4.4 Historia · Lista (#49)`. La plantilla y las propiedades están en `docs/PRODUCT.md` → 2026-10-16.

## Historia

Como Fran, quiero leer y editar una historia (cuerpo, propiedades y estado) y ver su historial, para dejarla lista para que un agente la construya sin preguntar.

## Criterios de aceptación

- [ ] Miga de pan `Roadmap / M2 · Publicar sin fricción / #49`. Título grande y el cuerpo markdown renderizado; los `- [ ]` y `- [x]` se ven como casillas.
- [ ] Editar título y cuerpo: textarea con pestaña de vista previa (`marked` ya está en el importmap). Guardar llama a `Story#edit!`.
- [ ] Columna lateral:
  - **Estado** con el selector de cinco estados (`state_selector` de la #001) y un texto de qué significa. En Lista: "Siguiente en el roadmap…" si es la siguiente; si no, su posición.
  - **Propiedades**: hito (selector), mockup (enlace a Paper), labels y "Bloqueada por" (`#n`, con enlace y estado de cada una) más "Bloquea" (calculado).
  - **Historial**: eventos de `Story#history` en lenguaje natural ("Pasa a Lista", "claude edita el cuerpo"), con actor y fecha relativa en mono.
- [ ] Si se pasa a Lista con preguntas abiertas en el cuerpo, o con `labels` que incluyen `ui` y sin mockup, se muestra un aviso. El aviso no bloquea.
- [ ] Comentarios debajo del cuerpo: lista con actor y fecha, y un campo para añadir uno como Fran.
- [ ] `/p/:slug/stories/:number` funciona con el número de la historia.
- [ ] `bin/ci` en verde.

## Fuera de alcance

- Pestaña Ejecución, runs y paradas (artboard `4.5`): M4.
- Miniaturas de los mockups de Paper: con un enlace basta.
- Decisiones ligadas a la historia: se ven en el Brief; aquí, como mucho, un enlace.

## Notas para quien lo construya

- El texto de cada evento sale de su `action` y su `data`. Un helper con un `case` basta.

## Preguntas abiertas

- Mockup v3 pendiente (Producto, tarea 3): `4.4` pasado a v3, con el bloque de propiedades, que en v2 no existe.

## Cierre
