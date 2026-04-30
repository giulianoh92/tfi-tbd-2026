#!/usr/bin/env bash
set -euo pipefail

# Wrapper local. Aplica el schema contra el docker compose levantado.
# Si hay psql en el host, lo usa directo; si no, ejecuta apply.sh adentro
# del container postgres (que ya trae psql). Para CI / Supabase se llama
# a apply.sh directamente con DATABASE_URL exportada.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

if [ -f "$PROJECT_DIR/.env" ]; then
    set -a
    # shellcheck disable=SC1091
    source "$PROJECT_DIR/.env"
    set +a
fi

DB_USER="${POSTGRES_USER:-postgres}"
DB_PASS="${POSTGRES_PASSWORD:-postgres}"
DB_NAME="${POSTGRES_DB:-tbd_tfi}"
DB_PORT="${POSTGRES_PORT:-5432}"

if command -v psql &>/dev/null; then
    export DATABASE_URL="postgres://${DB_USER}:${DB_PASS}@localhost:${DB_PORT}/${DB_NAME}"
    exec "$SCRIPT_DIR/apply.sh"
else
    # Sin psql en el host -> ejecutamos apply.sh dentro del container db.
    # Desde ahi, localhost apunta al propio postgres.
    docker compose -f "$PROJECT_DIR/docker-compose.yml" exec -T \
        -e DATABASE_URL="postgres://${DB_USER}:${DB_PASS}@localhost:5432/${DB_NAME}" \
        db /sql/scripts/apply.sh
fi
