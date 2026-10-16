#!/usr/bin/env bash
# Migra el roadmap, el backlog y las decisiones de Maker Tracker a la app (#022).
# Requisitos: mt configurado (mt setup) y el proyecto ya creado y vacío.
# Uso, desde la raíz del repo: P=MT bash docs/migration/import.sh
set -euo pipefail
: "${P:=MT}"
cd "$(git rev-parse --show-toplevel)"

echo "== Brief"
mt brief --file docs/migration/brief.md --project "$P"

echo "== Hitos (en el orden de ROADMAP.md)"
mt milestone create "Núcleo v2" --goal "El modelo nuevo funcionando, con la UI mínima para definir producto." --project "$P"
mt milestone create "Interfaz para agentes" --goal "Un agente puede responder «¿qué es lo siguiente?» y cerrar el ciclo. A partir de aquí, Maker Tracker se construye con Maker Tracker." --project "$P"
mt milestone create "Actividad" --goal "Enterarme de qué está pasando sin preguntar." --project "$P"
mt milestone create "Ejecución y wflow" --goal "El flujo completo de producto a tecnología, con cada pieza viviendo sola." --project "$P"
mt milestone create "Después" --goal "Sin orden decidido: MCP fino sobre la API (Claude Desktop, móvil), migrar los backlogs desde Notion y paradas nivel 2 (Maker Tracker guarda la decisión y wflow la recoge al reanudar)." --project "$P"

echo "== Historias (en el orden de ROADMAP.md, conservando su número)"
# El orden de creación es el orden dentro de cada hito.
grep -oE '\(backlog/[0-9]{3}-[^)]+\.md\)' docs/ROADMAP.md | tr -d '()' | while read -r f; do
  file="docs/$f"
  state=$(sed -n 's/^state: *//p' "$file" | head -1)
  number=$(sed -n 's/^number: *//p' "$file" | head -1)
  case "$state" in
    done|in_progress)
      mt create --file "$file" --state ready --project "$P" >/dev/null
      mt move "$P-$number" "$state" --project "$P" >/dev/null ;;
    *)
      mt create --file "$file" --project "$P" >/dev/null ;;
  esac
  echo "$P-$number $state"
done

echo "== Cerrar M1"
mt milestone close M1 --project "$P"

echo "== Decisiones"
P="$P" bash docs/migration/decisions.sh >/dev/null

echo "== Resultado"
mt context --project "$P"
