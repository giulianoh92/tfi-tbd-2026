#!/usr/bin/env bash
# Sprint 6 (B2.3, B2.4) — Smoke tests append-only + doble identidad.
#
# Requiere docker-compose levantado y schema aplicado:
#   docker compose down -v && docker compose up -d --wait
#   ./scripts/deploy.sh
#
# Uso:
#   ./tests/audit_append_only.sh
#
# Cubre:
#   V4. UPDATE/DELETE en audit_log desde rol con privilegios (quique) ->
#       falla con 'audit_log es append-only'.
#   V5. INSERT en cliente desde rol authenticated -> usuario_db = 'authenticated'.

set -euo pipefail

PSQL_ADMIN="${PSQL_ADMIN:-psql -h localhost -U postgres -d postgres}"
PSQL_QUIQUE="${PSQL_QUIQUE:-psql -h localhost -U quique -d postgres}"

echo "=== V4 — audit_log append-only desde quique ==="

# Insertar una fila de audit_log "manual" como postgres (la unica via valida es
# por trigger; aca lo hacemos directo para tener algo que intentar modificar).
LAST_AUDIT_ID=$(${PSQL_ADMIN} -tAc "
    INSERT INTO audit_log (tabla, id_registro, tipo_op, usuario_db)
    VALUES ('cliente', '1', 'I', 'postgres')
    RETURNING id_audit;
")
echo "Insertado audit_log id=${LAST_AUDIT_ID} desde postgres."

# UPDATE desde quique -> debe FALLAR.
set +e
OUTPUT=$(${PSQL_QUIQUE} -c "UPDATE audit_log SET tabla = 'x' WHERE id_audit = ${LAST_AUDIT_ID};" 2>&1)
RC=$?
set -e

if [[ $RC -eq 0 ]]; then
    echo "FAIL: el UPDATE no fue rechazado. Output: ${OUTPUT}"
    exit 1
fi

if [[ "${OUTPUT}" != *"audit_log es append-only"* ]]; then
    echo "FAIL: el UPDATE fue rechazado pero NO por el trigger esperado."
    echo "Output: ${OUTPUT}"
    exit 1
fi

echo "OK: el UPDATE desde quique fue rechazado por trigger append-only."

# Mismo test con DELETE.
set +e
OUTPUT=$(${PSQL_QUIQUE} -c "DELETE FROM audit_log WHERE id_audit = ${LAST_AUDIT_ID};" 2>&1)
RC=$?
set -e

if [[ $RC -eq 0 ]] || [[ "${OUTPUT}" != *"audit_log es append-only"* ]]; then
    echo "FAIL: el DELETE no fue rechazado correctamente."
    echo "Output: ${OUTPUT}"
    exit 1
fi

echo "OK: el DELETE desde quique fue rechazado por trigger append-only."

echo
echo "=== V5 — usuario_db = session_user en doble identidad ==="

# El requisito completo de V5 implica un flujo via PostgREST con JWT real.
# Como ese stack puede no estar disponible en CI, validamos el equivalente
# de bajo nivel: SET ROLE authenticated antes del INSERT debe producir
# usuario_db = 'authenticated' en audit_log, NO 'postgres'.
${PSQL_ADMIN} <<SQL
BEGIN;
SET LOCAL ROLE authenticated;
-- Suponemos un cliente seed con id 1; si tu seed no lo trae, ajustar.
INSERT INTO cliente (id_usuario, nombre, apellido, dni, email)
VALUES (
    (SELECT id_usuario FROM usuario LIMIT 1),
    'TestAppend', 'AppendOnly', '99999999', 'test-append@example.com'
);
COMMIT;
SQL

LAST_USUARIO_DB=$(${PSQL_ADMIN} -tAc "
    SELECT usuario_db
    FROM audit_log
    WHERE tabla = 'cliente' AND tipo_op = 'I'
    ORDER BY id_audit DESC
    LIMIT 1;
")

if [[ "${LAST_USUARIO_DB}" != "authenticated" ]]; then
    echo "FAIL: esperado usuario_db='authenticated', recibido '${LAST_USUARIO_DB}'."
    echo "Verificar que fn_audit_generic use session_user, no current_user."
    exit 1
fi

echo "OK: usuario_db='authenticated' como esperado (doble identidad preservada)."
echo
echo "=== Todos los smoke tests de B2 pasaron ==="
