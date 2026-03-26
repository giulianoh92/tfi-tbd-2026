#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

if [ -f "$PROJECT_DIR/.env" ]; then
  set -a
  source "$PROJECT_DIR/.env"
  set +a
fi

DB_USER="${POSTGRES_USER:-postgres}"
DB_NAME="${POSTGRES_DB:-tbd_tfi}"
DB_PORT="${POSTGRES_PORT:-5432}"
DB_HOST="localhost"

SEEDS_DIR="$PROJECT_DIR/seeds"

if [ ! -d "$SEEDS_DIR" ]; then
  echo "Error: no se encontro el directorio de seeds ($SEEDS_DIR)"
  exit 1
fi

SQL_FILES=$(find "$SEEDS_DIR" -maxdepth 1 -name '*.sql' | sort)

if [ -z "$SQL_FILES" ]; then
  echo "No hay archivos de seed en $SEEDS_DIR"
  exit 0
fi

# Determinar si usar psql local o via docker
if command -v psql &>/dev/null; then
  run_sql() { psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -f "$1" --set ON_ERROR_STOP=1; }
else
  # Usa el volumen montado en /sql/seeds dentro del container
  run_sql() { docker compose -f "$PROJECT_DIR/docker-compose.yml" exec -T db psql -U "$DB_USER" -d "$DB_NAME" -f "/sql/seeds/$(basename "$1")" --set ON_ERROR_STOP=1; }
fi

echo "==> Ejecutando seeds..."
for file in $SQL_FILES; do
  echo "  -> $(basename "$file")"
  run_sql "$file"
done

echo "==> Seeds aplicados exitosamente."
