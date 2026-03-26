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

SCHEMA_DIR="$PROJECT_DIR/schema"

if [ ! -d "$SCHEMA_DIR" ]; then
  echo "Error: no se encontro el directorio de schema ($SCHEMA_DIR)"
  exit 1
fi

# Determinar si usar psql local o via docker
if command -v psql &>/dev/null; then
  run_sql_cmd() { psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "$1" --set ON_ERROR_STOP=1; }
  run_sql_file() { psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -f "$1" --set ON_ERROR_STOP=1; }
else
  run_sql_cmd() { docker compose -f "$PROJECT_DIR/docker-compose.yml" exec -T db psql -U "$DB_USER" -d "$DB_NAME" -c "$1" --set ON_ERROR_STOP=1; }
  run_sql_file() {
    local relative_path="${1#$PROJECT_DIR/}"
    docker compose -f "$PROJECT_DIR/docker-compose.yml" exec -T db psql -U "$DB_USER" -d "$DB_NAME" -f "/sql/$relative_path" --set ON_ERROR_STOP=1
  }
fi

# Funcion para aplicar todos los .sql de un directorio (sorted)
apply_dir() {
  local dir="$1"
  local label="$2"

  local sql_files
  sql_files=$(find "$dir" -maxdepth 1 -name '*.sql' 2>/dev/null | sort)

  if [ -z "$sql_files" ]; then
    return
  fi

  echo ""
  echo "==> $label"
  for file in $sql_files; do
    echo "  -> $(basename "$file")"
    run_sql_file "$file"
  done
}

echo "==> Recreando schema public..."
run_sql_cmd "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"
echo "  -> Schema public recreado"

# Aplicar archivos en orden
apply_dir "$SCHEMA_DIR" "Extensiones"  # 00_extensions.sql esta en la raiz de schema/

apply_dir "$SCHEMA_DIR/01_tables"      "Tablas"
apply_dir "$SCHEMA_DIR/02_constraints" "Constraints"
apply_dir "$SCHEMA_DIR/03_indexes"     "Indices"
apply_dir "$SCHEMA_DIR/04_functions"   "Funciones / triggers / vistas"
apply_dir "$SCHEMA_DIR/05_seeds"       "Datos de prueba (seeds)"

echo ""
echo "==> Deploy completado exitosamente."
