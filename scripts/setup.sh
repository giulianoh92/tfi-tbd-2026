#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "==> Configurando entorno local..."

# Crear .env si no existe
if [ ! -f "$PROJECT_DIR/.env" ]; then
  cp "$PROJECT_DIR/.env.example" "$PROJECT_DIR/.env"
  echo "  -> .env creado desde .env.example"
  echo "     (Edita .env si queres cambiar la password de PostgreSQL)"
else
  echo "  -> .env ya existe, no se modifico"
fi

# Levantar containers
echo "==> Levantando Docker..."
docker compose -f "$PROJECT_DIR/docker-compose.yml" up -d

# Esperar a que PostgreSQL este listo
echo "==> Esperando a que PostgreSQL este listo..."
until docker compose -f "$PROJECT_DIR/docker-compose.yml" exec -T db pg_isready -U postgres &>/dev/null; do
  sleep 1
done

# Desplegar schema completo
echo "==> Desplegando schema..."
"$SCRIPT_DIR/deploy.sh"

echo ""
echo "==> Todo listo!"
echo ""
echo "  pgweb (cliente SQL):  http://localhost:8081"
echo "  PostgreSQL directo:   psql -h localhost -p 5432 -U postgres -d tbd_tfi"
echo ""
