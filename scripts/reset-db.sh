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

# Determinar si usar herramientas locales o via docker
if command -v psql &>/dev/null; then
  run_psql() { psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" "$@"; }
  run_dropdb() { dropdb -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" "$@"; }
  run_createdb() { createdb -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" "$@"; }
else
  run_psql() { docker compose -f "$PROJECT_DIR/docker-compose.yml" exec -T db psql -U "$DB_USER" "$@"; }
  run_dropdb() { docker compose -f "$PROJECT_DIR/docker-compose.yml" exec -T db dropdb -U "$DB_USER" "$@"; }
  run_createdb() { docker compose -f "$PROJECT_DIR/docker-compose.yml" exec -T db createdb -U "$DB_USER" "$@"; }
fi

echo "==> Eliminando base de datos '$DB_NAME'..."
run_dropdb --if-exists "$DB_NAME"

echo "==> Creando base de datos '$DB_NAME'..."
run_createdb "$DB_NAME"

echo "==> Ejecutando migraciones..."
"$SCRIPT_DIR/migrate.sh"

echo "==> Ejecutando seeds..."
"$SCRIPT_DIR/seed.sh"

echo "==> Base de datos reseteada exitosamente."
