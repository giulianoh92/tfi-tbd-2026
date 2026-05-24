#!/usr/bin/env bash
set -euo pipefail

# scripts/demo-transaccional.sh — Wrapper que ejecuta la demostracion literal
# de COMMIT / ROLLBACK contra la base local (docker compose) via psql.
#
# Sprint 5 (R2). Este script SOLO es valido fuera de RPC/PostgREST. Por eso
# se invoca con `psql -f` directamente, no via supabase.rpc(). Cualquier
# intento de exponer `pa_demo_transaccional` por HTTP devolveria
# 2D000 invalid_transaction_termination — ver docs/requisitos/JUSTIFICACION.md
# §R2 para el fundamento completo.
#
# Uso:
#   ./scripts/demo-transaccional.sh
#
# Carga la misma .env que scripts/deploy.sh para resolver DATABASE_URL.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
DEMO_SQL="$PROJECT_DIR/tests/transacciones_explicitas.sql"

if [ ! -f "$DEMO_SQL" ]; then
    echo "Error: no se encontro $DEMO_SQL" >&2
    exit 1
fi

if [ -f "$PROJECT_DIR/.env" ]; then
    set -a
    # shellcheck disable=SC1091
    source "$PROJECT_DIR/.env"
    set +a
fi

# Si DATABASE_URL no esta seteada, la armamos a partir de POSTGRES_* (mismo
# patron que scripts/deploy.sh).
if [ -z "${DATABASE_URL:-}" ]; then
    DB_USER="${POSTGRES_USER:-postgres}"
    DB_PASS="${POSTGRES_PASSWORD:-postgres}"
    DB_NAME="${POSTGRES_DB:-tbd_tfi}"
    DB_PORT="${POSTGRES_PORT:-5432}"
    export DATABASE_URL="postgres://${DB_USER}:${DB_PASS}@localhost:${DB_PORT}/${DB_NAME}"
fi

if ! command -v psql &>/dev/null; then
    echo "Error: psql no esta instalado en el host." >&2
    echo "       Instala postgresql-client o ejecuta el script dentro del container db." >&2
    exit 1
fi

echo "==> Ejecutando demo transaccional contra $DATABASE_URL"
echo "    Archivo: $DEMO_SQL"
echo ""

psql "$DATABASE_URL" -f "$DEMO_SQL" --set ON_ERROR_STOP=1

echo ""
echo "==> Demo finalizada. Revisa los RAISE NOTICE de arriba para confirmar:"
echo "    * 'Fila #1 insertada y COMMITeada.'"
echo "    * 'Fila #2 insertada y luego ROLLBACKeada (no debe persistir).'"
echo "    * 'OK: COMMIT/ROLLBACK literales funcionaron como en Oracle.'"
