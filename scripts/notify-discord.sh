#!/usr/bin/env bash
set -euo pipefail

# Envia una notificacion a Discord cuando un job del workflow falla.
# Lo invocan los pasos del workflow con `if: failure()`.
#
# Uso: notify-discord.sh <job_name> <log_file>
#
# Variables de entorno requeridas:
#   DISCORD_WEBHOOK     - URL del webhook (secret del repo). Si no esta
#                         seteada, el script sale 0 sin enviar nada.
#   GITHUB_*            - inyectadas automaticamente por GitHub Actions.

JOB_NAME="${1:-desconocido}"
LOG_FILE="${2:-}"

if [ -z "${DISCORD_WEBHOOK:-}" ]; then
    echo "DISCORD_WEBHOOK no configurado, salteando notificacion."
    exit 0
fi

if ! command -v jq &>/dev/null; then
    echo "jq no disponible en el runner, salteando notificacion."
    exit 0
fi

COMMIT_SHA="${GITHUB_SHA:-unknown}"
COMMIT_SHORT="${COMMIT_SHA:0:7}"
REPO="${GITHUB_REPOSITORY:-?}"
RUN_URL="${GITHUB_SERVER_URL:-https://github.com}/${REPO}/actions/runs/${GITHUB_RUN_ID:-?}"

# Info del commit: viene del checkout. Si por algun motivo no esta
# disponible, usamos placeholders.
COMMIT_MSG=$(git log -1 --pretty=%s 2>/dev/null || echo "(no disponible)")
COMMIT_AUTHOR=$(git log -1 --pretty=%an 2>/dev/null || echo "(no disponible)")

# Cola del log con el error. Limitamos a ~1500 caracteres para no exceder
# el maximo de descripcion de un embed de Discord (4096) dejando margen
# para el code-block y el resto del texto.
if [ -n "$LOG_FILE" ] && [ -f "$LOG_FILE" ]; then
    LOG_TAIL=$(tail -c 1500 "$LOG_FILE" || echo "(log truncado o ilegible)")
else
    LOG_TAIL="(log no disponible)"
fi

PAYLOAD=$(jq -n \
    --arg job    "$JOB_NAME" \
    --arg sha    "$COMMIT_SHORT" \
    --arg msg    "$COMMIT_MSG" \
    --arg author "$COMMIT_AUTHOR" \
    --arg log    "$LOG_TAIL" \
    --arg url    "$RUN_URL" \
    --arg repo   "$REPO" \
    '{
        username: "TBD CI",
        embeds: [{
            title:       ("Deploy fallido en job `" + $job + "`"),
            url:         $url,
            color:       15158332,
            description: ("**Repo:** " + $repo + "\n**Commit:** `" + $sha + "` " + $msg + "\n**Autor:** " + $author + "\n\n**Error (cola del log):**\n```\n" + $log + "\n```\n[Ver corrida completa](" + $url + ")")
        }]
    }')

if curl -sS -H "Content-Type: application/json" -X POST \
        --data-binary "$PAYLOAD" "$DISCORD_WEBHOOK" -o /dev/null; then
    echo "Notificacion enviada a Discord."
else
    echo "Fallo el envio a Discord (no critico, sigue el workflow)."
fi
