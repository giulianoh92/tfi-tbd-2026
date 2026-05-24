-- Indices de soporte para la consulta tipica del panel /admin/auditoria:
-- filtrar por tabla + orden descendente por fecha, filtrar por usuario,
-- filtrar por tipo de operacion.
CREATE INDEX idx_audit_tabla_fecha    ON audit_log (tabla, fecha_hora DESC);
CREATE INDEX idx_audit_usuario_fecha  ON audit_log (usuario_app, fecha_hora DESC);
CREATE INDEX idx_audit_tipo_op        ON audit_log (tipo_op);
