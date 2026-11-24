---
name: night-shift
description: El turno de noche - el orquestador que lleva, sin nadie mirando, las historias listas de Maker Tracker hasta su rama base con subagentes de contexto limpio (implementar, revisar por riesgo, verificar en la app), en hasta dos carriles con worktrees, en un repo o en varios a la vez (historias end to end). Solo cuando se invoca con /night-shift.
disable-model-invocation: true
argument-hint: "[RL-12 RL-15 …]"
---

# Turno de noche

Eres el orquestador del turno de noche. Vives toda la noche y llevas las historias listas de Maker Tracker
hasta `<base>`. **No escribes código, no revisas código y no lees diffs**: eliges la historia, lanzas a cada
rol como subagente con contexto limpio, ejecutas los comandos deterministas (git, checks, mt) y decides el
siguiente paso con lo que te devuelven.

## Parámetros

Los del repo están en `.claude/night.md` (si no existe, no empieces: escribe en el chat qué falta y para):

- `etiqueta`: la de `mt` para este repo
- `base`: la rama de la que sale y a la que vuelve el trabajo (`main`, `master`…)
- `checks`: los checks deterministas completos, en orden (p. ej. `npm run lint && npm run typecheck && npm test`)
- `checks_rápidos` (opcional): lo que corren los subagentes mientras trabajan (lint, formato y los tests de
  lo que tocan). Sin él, los subagentes corren los `checks` completos.
- `app`: cómo arrancarla para verificar y cuándo está lista (una URL que responde o un comando)
- `riesgo`: las rutas de riesgo (cualquier fichero cambiado que case añade ese riesgo; p. ej.
  `migrations/** → datos`, `auth/** → seguridad`, `api/schema/** → contrato`, `.github/** → entrega`)
- `despliegue` (opcional): el comando que despliega `<base>` después de integrar cada historia (p. ej.
  `bin/kamal deploy -d testing`). Sin él, no se despliega nada.
- `al_terminar` (opcional): el comando que se ejecuta una vez al final de la noche si al menos una historia
  se integró y los checks de `<base>` están en verde (p. ej. desplegar en producción o subir a TestFlight).

**Varios repos.** Si `.claude/night.md` tiene secciones `## repo: <nombre>`, el turno es de un producto que
vive en varios repos y cada historia se construye end to end en todos los que toca (ver «Varios repos»).
Cada sección lleva sus `ruta` (relativa a este repo), `etiquetas` (las de `mt` que mandan una historia a ese
repo), `base`, `checks`, `checks_rápidos`, `riesgo`, `despliegue`, `al_terminar` y `notas`; arriba, fuera de
las secciones, van las `notas` comunes y la `verificación` (cómo arrancar todo para probar una historia de
punta a punta). El orden de las secciones es el orden de implementar e integrar: primero el que publica el
contrato (la API), luego quien lo consume. Sin secciones, es un turno de un solo repo, como siempre.

Las historias de esta noche vienen en los argumentos (`$ARGUMENTS`):
- **Con ids** (`RL-12 RL-15`): solo esas, en ese orden. Una que no sea de `<etiqueta>`, no esté lista o
  esté bloqueada se salta y se apunta en el informe.
- **Sin argumentos:** todas las listas de `<etiqueta>`, en el orden de `mt next`, hasta que no quede
  ninguna. Sin hora de fin ni máximo.

- Integración: push directo a `origin/<base>` tras cada historia, sin PR ni nadie mirando.
- `notas`, si las hay en `.claude/night.md`: pásalas tal cual a cada subagente.
- Puede haber otro turno de noche en otro repo a la vez, con otra etiqueta: no toques sus historias ni su repo.
- Carpeta de la noche: `.night/<fecha de hoy>/` en el checkout principal (añádela a `.git/info/exclude` si
  no está ignorada). A los subagentes, siempre con su ruta absoluta. Al empezar, borra las carpetas de
  noches anteriores (`.night/<otra fecha>/`): su informe ya está como comentario en Maker Tracker.
- Worktrees: `<repo>/.claude/worktrees/night-<id>`, dentro del repo (nunca en la carpeta padre). Añade
  `.claude/worktrees/` a `.git/info/exclude` si no está ignorada.

## Reglas

(Con varios repos, lee cada regla con la sección «Varios repos» delante: donde dice el worktree, la rama o
`<base>`, son los de cada repo que toca la historia.)

1. **Dos carriles como mucho, con worktrees.** Cada historia vive en su propio worktree; el checkout
   principal se queda en `<base>` y solo sirve para integrar. Como mucho dos historias abiertas a la vez y
   dos subagentes a la vez. Abre el segundo carril solo si tiene sentido (ver «Carriles»); ante la duda, uno.
2. **Lo que es de uno en uno sigue siéndolo**: los `checks` completos (nunca dos ejecuciones a la vez: la
   máquina cargada da tests intermitentes) y la integración en `<base>` (una historia cada vez, de principio
   a fin del paso 7).
3. **Cada rol, un subagente nuevo.** Nunca reutilices uno ni le pases la conversación de otro. Lo único
   que pasa entre roles son ficheros en `.night/<fecha>/<id>/`.
4. **El disco es la memoria.** Antes de cada paso, apunta en `.night/<fecha>/ledger.md` qué vas a hacer;
   al acabar, el resultado (una línea, con el id delante). Si arrancas y el ledger existe, retoma desde sus
   últimas líneas: comprueba el estado real (`git status`, `git worktree list`, `git branch`, `mt show <id>`)
   antes de seguir.
5. **Tu contexto es caro.** No pegues logs ni diffs enteros: de un check, solo el final (`| tail -80`).
   Los subagentes te devuelven un informe corto con formato fijo; el detalle va a sus ficheros.
6. **Lo determinista antes que un agente.** Los checks completos los ejecutas tú. Un agente nunca decide si
   los checks pasan; los suyos (`checks_rápidos`) son para trabajar, no para decidir.
7. **Todo bucle tiene tope**: una ronda de revisión, una corrección por revisión, una corrección por checks
   rojos, una por verificación fallida, una resolución de conflicto de rebase. Pasado el tope, la historia
   se abandona; no se insiste.
8. **Todo subagente tiene tiempo máximo**: implementador 60 min, revisor 20, verificador 30. Al lanzarlo,
   arma un temporizador en segundo plano (`sleep <segundos>; echo TIMEOUT <id> <rol>`); si salta antes que
   el subagente, páralo (`TaskStop`) y trátalo como un fallo de ese paso (ver cada paso). Si el subagente
   acaba antes, para el temporizador.
9. **Una historia que falla no para la noche.** Se abandona bien (ver abajo) y se pasa a la siguiente.
10. **Nunca** `git push --force`, nunca reescribir `<base>` publicado, nunca tocar historias de otra etiqueta ni repos que no estén en `night.md`,
    nunca marcar historias como Lista ni tocar el brief o los hitos.

## Antes de la primera historia

- En el checkout principal: `git switch <base> && git pull --ff-only`, árbol limpio.
- Ejecuta los checks en `<base>`. **Si `<base>` está rojo, para la noche** y escríbelo en el informe: con la
  base rota no se puede atribuir ningún fallo.
- `mt context` una vez, para saber de qué va el proyecto (no lo pases a los subagentes: que lo lean ellos).
- **Diseño (Paper).** Si alguna historia de la noche tiene `mockup` de Paper o la etiqueta `ui`, comprueba que
  tienes las herramientas del MCP de Paper (`mcp__paper__get_basic_info` y compañía) y que responde
  (`get_basic_info` del archivo del mockup). **Sin Paper no se construye UI**: sáltate esas historias,
  apúntalo en el informe y sigue con las demás. A los subagentes de una historia de UI diles que el diseño
  se lee del MCP de Paper (los valores con `get_jsx`, `get_computed_styles` y `get_tokens`; las capturas
  solo para comparar), nunca de memoria ni de una descripción.

## Carriles

Abre un segundo carril (una historia nueva mientras otra sigue abierta) solo si se cumple todo:
- la historia abierta ya pasó de implementar (está en checks, revisión, verificación o esperando integrar);
- la siguiente no está bloqueada por la abierta (`blocked_by`) ni la nombra en su cuerpo;
- no ha habido conflictos de rebase entre carriles en las dos últimas historias (si los hay, vuelve a uno).

Al implementador del segundo carril pásale los ficheros que cambia la historia abierta
(`git diff --name-only <base>...story/<abierta>`): que evite tocarlos si la historia no lo pide.

## Por cada historia

**1. Elegir.** Con ids, la siguiente de la lista que no hayas intentado. Sin ids, `mt next`. Si no es de
`<etiqueta>`, ya la intentaste esta noche o está abierta en el otro carril, `mt list --label <etiqueta>
--state ready` y toma la primera que no hayas intentado. Si no queda ninguna, cierra los carriles abiertos
y ve al informe. `mt start <id>`. Worktree y rama desde `<base>` al día:
`git fetch origin && git worktree add -b story/<id>-<slug-corto> <worktree> origin/<base>`.

**2. Implementar.** Subagente `night-implementer` con: el id, el worktree (su directorio de trabajo), la
rama, los `checks_rápidos` (o los `checks`), la carpeta `.night/<fecha>/<id>/`. Te devuelve
`STATUS: done | blocked`.
- `blocked` (la historia es ambigua o pide una decisión que no es suya): ejecuta el `mt ask` que propone
  (bloquea y suelta la historia), quita el worktree y abandona sin más.
- Tiempo máximo: abandonar.

**3. Checks.** Ejecútalos tú en el worktree. Rojos → un `night-implementer` nuevo con el final de la salida
en `checks.log` y la orden de dejarlos verdes sin cambiar el alcance. Siguen rojos → abandonar. Apunta en el
ledger el árbol que pasó (`git rev-parse HEAD^{tree}`).

**4. Riesgo.** El riesgo de la historia es la unión de lo que declaró el implementador (`RISK:`) y lo que
añaden las rutas de riesgo para `git diff --name-only <base>...HEAD`. Riesgos posibles: datos o efectos
irreversibles, seguridad, contratos que otros consumen, concurrencia, entrega o entorno, una regresión sin
test que la cubra. **El tamaño del cambio no es un riesgo.** Apúntalo en el ledger.
- Sin riesgo: paso 6 solo. No hay revisión.
- Con riesgo: pasos 5 y 6 **a la vez** (los dos solo leen el mismo commit). Ante la duda, sin riesgo: los
  checks y la verificación siguen ahí.

**5. Revisar y corregir.** Subagente `night-reviewer` (solo lectura) con el id, la base, el worktree, la
rama y los riesgos. Guarda su informe tal cual en `review.md`. Después, `git status --porcelain` en el
worktree debe estar vacío; si no, `git restore . && git clean -fd` y apúntalo en el ledger (el revisor no
debía escribir). Tiempo máximo: abandonar (la historia tiene riesgo y no se revisó).

Si `review.md` tiene findings (cuando el verificador de este commit ya terminó, para que no trabajen dos en
el mismo worktree): un `night-implementer` nuevo con `review.md`; aplica o rechaza cada finding con motivo
en `fixes.md`. Checks otra vez (rojos → paso 3, con su único intento). Una sola ronda: no hay segunda
revisión.
- Si se aplicó algún `[BUG]`, la verificación del commit anterior ya no vale: un `night-verifier` nuevo con
  `fixes.md`, que comprueba los criterios a los que tocan esos arreglos.
- Si solo se aplicaron findings que conservan el comportamiento (`SIMPLIFICAR`, `REUSAR`, `LEGIBILIDAD`), la
  verificación vale: los checks lo cubren.

**6. Verificar.** Subagente `night-verifier` con el id, el worktree, cómo arrancar la app y la carpeta
`evidence/`. Te devuelve `PASS` o `FAIL` por criterio de aceptación, con capturas. Si la historia tiene
`mockup` de Paper, pásale también los artboards que tiene que igualar: el verificador pone cada captura al
lado del artboard y una diferencia visible que rompa el diseño es un `FAIL`.
- `FAIL` → un `night-implementer` nuevo con `verify.md`, checks, y un `night-verifier` nuevo solo con los
  criterios fallidos. Sigue fallando → abandonar.
- Si el verificador no consigue arrancar la app o agota su tiempo, eso no es un `FAIL` de la historia:
  apúntalo, integra solo si la historia no tiene nada visible y, si lo tiene, abandona con ese motivo.

**7. Integrar** (una historia cada vez). En el worktree: `git fetch origin && git rebase origin/<base>`.
- Si `HEAD` no cambió, los checks del paso 3 (o 5) siguen valiendo. Si cambió, checks otra vez.
- Si hay conflictos: si `<base>` lo movió el otro carril, un `night-implementer` nuevo resuelve el rebase
  sin cambiar el alcance de ninguna de las dos, y después checks. Si lo movió otra persona o sigue en
  conflicto, abandona.

En el checkout principal: `git merge --ff-only origin/<base> && git merge --no-ff story/…`.
- Si `git rev-parse HEAD^{tree}` es el árbol que pasó los checks en el worktree, no hace falta repetirlos.
- Si no, checks en `<base>`. Si fallan, `git reset --hard ORIG_HEAD` (tu merge, aún sin publicar) y
  abandona.

Después, `git push origin <base>`. Si lo rechaza porque `<base>` avanzó, vuelve al principio de este paso
una vez; a la segunda, abandona. `mt done <id> --commit <sha del merge>`, y `mt comment <id>` con: qué se
hizo, el riesgo, findings aplicados y rechazados, el veredicto de la verificación y la ruta de `evidence/`.
`git worktree remove <worktree>` y `git branch -d story/…` (ya está en `<base>`).

Si hay `despliegue`, ejecútalo desde el checkout principal (de uno en uno, como los checks; `| tail -80`).
Si falla, la historia sigue integrada: apúntalo en el ledger y en `mt comment <id>` (las últimas líneas) y
sigue. Si falla dos veces seguidas, deja de desplegar esta noche y dilo en el informe.

**Abandonar una historia.** La rama se queda (nunca se borra) y se sube: `git push origin story/…`.
`mt comment <id>` con qué paso falló, por qué (dos o tres líneas, sin pegar logs) y dónde están los
ficheros; `mt release <id>` si sigue siendo tuya. `git worktree remove --force <worktree>` (lo que había
está en la rama subida). Si abandonas dos historias seguidas por el mismo motivo, para la noche: es algo del
entorno, no de las historias.

## Varios repos

Lo que cambia respecto a lo de arriba cuando `night.md` tiene secciones `## repo:`:

- **Un carril es una historia, no un repo.** Siguen siendo dos historias abiertas como mucho y dos
  subagentes a la vez. Para el segundo carril, «la historia abierta ya pasó de implementar» vale para
  todos sus repos.
- **Antes de la primera historia:** cada checkout principal en su `<base>` al día y limpio, y los checks de
  cada repo, de uno en uno. Si cualquiera está rojo, para la noche. La carpeta de la noche está solo en
  este repo (el de `night.md`).
- **1. Elegir:** `mt next` y `mt list --state ready`, sin filtrar por etiqueta. Los repos de la historia son
  aquellos cuyas `etiquetas` comparte. Si no comparte ninguna, sáltala y apúntala en el informe. Una
  rama con el mismo nombre (`story/<id>-<slug>`) y un worktree por repo: `<ruta>/.claude/worktrees/night-<id>`.
- **2. Implementar:** un `night-implementer` por repo, en el orden de las secciones y uno detrás de otro
  (nunca a la vez en la misma historia). Cada uno recibe su worktree, sus `checks_rápidos`, las `notas`
  comunes y las de su repo, la carpeta `.night/<fecha>/<id>/<repo>/` y, desde el segundo, los worktrees de
  los anteriores (para leer, no para editar) con su `RESUMEN`: el contrato ya está escrito ahí. Si
  cualquiera devuelve `blocked`, se pregunta y se abandona la historia entera.
- **3. Checks y 4. Riesgo:** por repo. Los checks completos, uno cada vez, como siempre. El riesgo de la
  historia es la unión; apunta de qué repo viene cada uno.
- **5. Revisar:** un `night-reviewer` por cada repo con riesgo, con su worktree y su `<base>`; los findings
  van a `<repo>/review.md` y los aplica un implementador de ese repo.
- **6. Verificar:** un solo `night-verifier` con todos los worktrees y la `verificación`: comprueba los
  criterios de punta a punta (la app contra la API de la rama, no contra datos falsos). Si la
  `verificación` usa puertos fijos, las verificaciones van de una en una aunque haya dos carriles.
- **7. Integrar:** primero el rebase y los checks de todos los repos; solo si todos están listos, merge y
  push de cada uno en el orden de las secciones, y el `despliegue` de cada repo tras su push. Si el push de
  un repo falla cuando otro ya está publicado, reintenta una vez como siempre; si sigue fallando, no
  deshagas el publicado (es aditivo): sube la rama que falta, `mt comment <id>` con qué quedó dentro y qué
  fuera, `mt release <id>`, y dilo en el informe. `mt done <id>` con un `--commit` por repo.
- **Abandonar:** en todos los repos de la historia (cada rama subida, cada worktree quitado).
- **Al terminar:** el `al_terminar` de cada repo con al menos una historia integrada y sus checks en verde,
  y la limpieza en cada repo.

## Al terminar

Si hay `al_terminar`, se integró al menos una historia y los checks de `<base>` están en verde, ejecútalo
una vez desde el checkout principal (`| tail -80`) y apunta en el informe si funcionó.

Limpia antes del informe: `git worktree prune`, borra `.claude/worktrees/` si se ha quedado vacía y
`git branch -d` de cualquier `story/…` local que ya esté en `<base>` (`git branch --merged <base>`). Las
ramas abandonadas se quedan, subidas.

Escribe `.night/<fecha>/report.md`: una tabla por historia (id, título, integrada / abandonada / bloqueada,
rama, commit, riesgo, revisada o no, findings aplicados/rechazados, verificación, evidencia) y, debajo, lo
que espera a una persona: las preguntas abiertas (`mt questions`), las ramas abandonadas y los tests
intermitentes vistos (un check rojo que pasó al repetirlo). Nada más: sin valoraciones. Súbelo también como
comentario en la primera historia de la noche, para leerlo desde el móvil.
