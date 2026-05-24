-- Tabla general de auditoria (R1).
--
-- Una unica tabla para todas las entidades auditadas: simplifica triggers
-- (un solo fn_audit_generic), simplifica la interfaz de consulta y permite
-- filtrar por tabla via la columna `tabla`. Justificacion completa en
-- docs/requisitos/JUSTIFICACION.md seccion R1.
--
-- Doble identidad de usuario:
--   * usuario_db   = current_user (rol Postgres efectivo: authenticator,
--                    authenticated, anon, postgres, quique, etc).
--   * usuario_app  = sub del JWT de Supabase (UUID logico del cliente/staff
--                    que disparo la operacion). NULL si no hay JWT (ej:
--                    operaciones desde psql / apply.sh).
--
-- id_registro es TEXT porque las distintas tablas auditadas tienen PKs de
-- tipos distintos (BIGINT en general, pero queda abierto a UUID/etc).
-- Se serializa con ::text desde el trigger.
CREATE TABLE IF NOT EXISTS audit_log (
    id_audit           BIGSERIAL    PRIMARY KEY,
    tabla              TEXT         NOT NULL,
    id_registro        TEXT,
    tipo_op            CHAR(1)      NOT NULL,
    usuario_db         TEXT         NOT NULL,
    usuario_app        UUID,
    fecha_hora         TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    valores_anteriores JSONB,
    valores_nuevos     JSONB,
    CONSTRAINT chk_audit_tipo_op CHECK (tipo_op IN ('I', 'U', 'D'))
);
