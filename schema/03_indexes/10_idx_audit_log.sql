-- Indices de audit_log (R1).
--
-- Sostienen el rendimiento del panel de auditoria, que es uno de los
-- entregables de R1 (interfaz de consulta de registros de auditoria).
-- Cubren las consultas tipicas: filtrar por tabla con orden descendente por
-- fecha, filtrar por usuario de la aplicacion (JWT.sub) con la misma
-- ordenacion, y filtrar por tipo de operacion (I/U/D).
CREATE INDEX idx_audit_tabla_fecha    ON audit_log (tabla, fecha_hora DESC);
CREATE INDEX idx_audit_usuario_fecha  ON audit_log (usuario_app, fecha_hora DESC);
CREATE INDEX idx_audit_tipo_op        ON audit_log (tipo_op);
