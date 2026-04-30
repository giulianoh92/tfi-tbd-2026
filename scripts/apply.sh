#!/usr/bin/env bash
set -euo pipefail

# Aplica el schema completo (drop + recreate + todos los .sql en orden) a la
# base apuntada por DATABASE_URL. Independiente de docker o host local.
#
# Usado por:
#   * scripts/deploy.sh (local, contra docker compose)
#   * .github/workflows/deploy.yml (validate + deploy)

if [ -z "${DATABASE_URL:-}" ]; then
    echo "Error: la variable DATABASE_URL no esta definida" >&2
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCHEMA_DIR="$(dirname "$SCRIPT_DIR")/schema"

if [ ! -d "$SCHEMA_DIR" ]; then
    echo "Error: no se encontro el directorio $SCHEMA_DIR" >&2
    exit 1
fi

apply_dir() {
    local dir="$1"
    local label="$2"
    local files=()

    while IFS= read -r -d '' file; do
        files+=("$file")
    done < <(find "$dir" -maxdepth 1 -name '*.sql' -print0 2>/dev/null | sort -z)

    if [ ${#files[@]} -eq 0 ]; then
        return
    fi

    echo ""
    echo "==> $label"
    for file in "${files[@]}"; do
        echo "  -> $(basename "$file")"
        psql "$DATABASE_URL" -f "$file" --set ON_ERROR_STOP=1
    done
}

echo "==> Recreando schema public..."
psql "$DATABASE_URL" -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;" --set ON_ERROR_STOP=1
echo "  -> Schema public recreado"

apply_dir "$SCHEMA_DIR"                "Extensiones"
apply_dir "$SCHEMA_DIR/01_tables"      "Tablas"
apply_dir "$SCHEMA_DIR/02_constraints" "Constraints"
apply_dir "$SCHEMA_DIR/03_indexes"     "Indices"
apply_dir "$SCHEMA_DIR/04_functions"   "Funciones / triggers / vistas"
apply_dir "$SCHEMA_DIR/05_seeds"       "Datos de prueba (seeds)"
apply_dir "$SCHEMA_DIR/06_permissions" "Permisos (roles, GRANT, REVOKE)"

echo ""
echo "==> Apply completado exitosamente."
