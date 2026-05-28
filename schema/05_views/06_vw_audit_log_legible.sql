-- vw_audit_log_legible -- audit_log con tipo_op traducido y columnas renombradas semanticamente
--
-- Etapa 2 (R3, R1): vista sobre audit_log que simplifica el consumo desde el
-- panel /admin/auditoria. Traduce:
--   * tipo_op  I/U/D    -> 'INSERT' / 'UPDATE' / 'DELETE'
--   * usuario_db        -> rol_efectivo        (rol Postgres efectivo tras SET ROLE)
--   * rol_sesion        -> rol_postgres        (rol fisico de la conexion, no falsificable)
--   * usuario_app       -> usuario_aplicacion  (UUID logico del usuario final, JWT.sub)
--
-- El renombrado es solo presentacional; la justificacion de la triple identidad
-- y de cada columna esta en schema/01_tables/18_audit_log.sql. La vista no
-- expone datos nuevos: solo etiquetas mas legibles para el panel del personal.
--
-- Acceso: SELECT a staff, authenticated (el cliente final NO debe leer el
-- registro de auditoria completo; quien consume es el panel del personal),
-- service_role y quique. La tabla audit_log subyacente esta protegida por
-- trg_audit_log_append_only y por las RLS pertinentes.

CREATE OR REPLACE VIEW vw_audit_log_legible AS
SELECT
    al.id_audit,
    al.fecha_hora                       AS fecha_operacion,
    al.tabla,
    al.id_registro,
    CASE al.tipo_op
        WHEN 'I' THEN 'INSERT'
        WHEN 'U' THEN 'UPDATE'
        WHEN 'D' THEN 'DELETE'
        ELSE al.tipo_op::TEXT
    END                                 AS operacion,
    al.usuario_db                       AS rol_efectivo,
    al.rol_sesion                       AS rol_postgres,
    al.usuario_app                      AS usuario_aplicacion,
    al.valores_anteriores,
    al.valores_nuevos
FROM audit_log al;

COMMENT ON VIEW vw_audit_log_legible IS
'R1/R3 Etapa 2: vista presentacional sobre audit_log. Traduce tipo_op (I/U/D) a texto y renombra usuario_db/rol_sesion/usuario_app a rol_efectivo/rol_postgres/usuario_aplicacion para consumo del panel del personal.';
