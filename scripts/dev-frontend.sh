#!/usr/bin/env bash
set -euo pipefail

# dev-frontend.sh — Levanta el stack BaaS local y el frontend Next.js
#
# Uso (desde la raíz del repo):
#   bash scripts/dev-frontend.sh
#
# Qué hace:
#   1. Verifica que supabase CLI y bun estén instalados
#   2. Levanta el stack local con `supabase start` (idempotente)
#   3. Aplica el schema del repo a la base local con scripts/apply.sh
#   4. Imprime las URLs y keys para configurar .env.local
#   5. Arranca el servidor de desarrollo de Next.js

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FRONTEND_DIR="$REPO_ROOT/frontend"

# ── 1. Verificar dependencias ───────────────────────────────────────────────

if ! command -v supabase &>/dev/null; then
    echo ""
    echo "ERROR: supabase CLI no encontrado."
    echo ""
    echo "Instalalo con:"
    echo "  brew install supabase/tap/supabase        # macOS / Linux con Homebrew"
    echo "  # o bien, descargá el binario desde:"
    echo "  # https://github.com/supabase/cli/releases"
    echo ""
    exit 1
fi

if ! command -v bun &>/dev/null; then
    echo ""
    echo "ERROR: bun no encontrado."
    echo ""
    echo "Instalalo con:"
    echo "  curl -fsSL https://bun.sh/install | bash"
    echo "  # o via mise:"
    echo "  mise use bun@latest"
    echo ""
    exit 1
fi

if ! command -v docker &>/dev/null; then
    echo ""
    echo "ERROR: docker no encontrado. Supabase CLI requiere Docker corriendo."
    echo "  https://docs.docker.com/get-docker/"
    echo ""
    exit 1
fi

echo ""
echo "==> Verificando estado del stack Supabase local..."

# ── 2. Levantar supabase (idempotente) ─────────────────────────────────────

# `supabase start` falla si ya está corriendo — usamos `status` primero.
if supabase status --project-ref tbd-tfi-2026 &>/dev/null 2>&1; then
    echo "  -> Stack ya está corriendo, omitiendo start."
else
    echo "  -> Iniciando stack (esto puede tardar la primera vez que descarga imágenes)..."
    supabase start
fi

# ── 3. Obtener URLs y keys ──────────────────────────────────────────────────

echo ""
echo "==> Información del stack local:"
supabase status

# Extraer valores para sugerencia de .env.local
SUPABASE_URL=$(supabase status 2>/dev/null | grep "API URL" | awk '{print $NF}' || echo "http://127.0.0.1:54321")
ANON_KEY=$(supabase status 2>/dev/null | grep "anon key" | awk '{print $NF}' || echo "<ver supabase status>")

# ── 4. Aplicar schema del repo ─────────────────────────────────────────────

echo ""
echo "==> Aplicando schema del repo a la base local..."
echo "    (DROP + recreate + tablas + constraints + funciones + seeds + permisos)"
echo ""

LOCAL_DB_URL="postgresql://postgres:postgres@127.0.0.1:54322/postgres"
DATABASE_URL="$LOCAL_DB_URL" bash "$REPO_ROOT/scripts/apply.sh"

# ── 5. Configurar .env.local ───────────────────────────────────────────────

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Configuración de frontend/.env.local"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  Si todavía no creaste el archivo, copiá el ejemplo y editalo:"
echo ""
echo "    cp frontend/env.local.example frontend/.env.local"
echo ""
echo "  Y completalo con estos valores:"
echo ""
echo "    NEXT_PUBLIC_SUPABASE_URL=$SUPABASE_URL"
echo "    NEXT_PUBLIC_SUPABASE_ANON_KEY=$ANON_KEY"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Verificar que .env.local existe antes de arrancar el dev server
if [ ! -f "$FRONTEND_DIR/.env.local" ]; then
    echo ""
    echo "AVISO: $FRONTEND_DIR/.env.local no existe."
    echo "  El frontend no va a poder conectarse a Supabase."
    echo "  Crealo antes de correr 'bun dev' (ver arriba)."
    echo ""
    echo "  ¿Querés que lo cree automáticamente con los valores de arriba? (s/n)"
    read -r respuesta
    if [[ "$respuesta" =~ ^[Ss]$ ]]; then
        cat > "$FRONTEND_DIR/.env.local" <<EOF
NEXT_PUBLIC_SUPABASE_URL=$SUPABASE_URL
NEXT_PUBLIC_SUPABASE_ANON_KEY=$ANON_KEY
EOF
        echo "  -> $FRONTEND_DIR/.env.local creado."
    fi
fi

# ── 6. Instalar deps y arrancar dev server ─────────────────────────────────

echo ""
echo "==> Instalando dependencias de frontend (bun install)..."
cd "$FRONTEND_DIR"
bun install

echo ""
echo "==> Arrancando servidor de desarrollo en http://localhost:3000 ..."
echo "    (Ctrl+C para detener)"
echo ""
bun dev
