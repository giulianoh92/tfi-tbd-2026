-- Indices de reserva (R7).
--
-- Soportan las claves forneas (cliente, vehiculo, tipo_reserva), el filtro
-- por estado del panel /admin/reservas y la consulta de solapamiento
-- temporal por (fecha_inicio, fecha_fin_prevista) que pa_registrar_reserva
-- ejecuta antes de insertar.
CREATE INDEX idx_reserva_cliente        ON reserva (id_cliente);
CREATE INDEX idx_reserva_vehiculo       ON reserva (id_vehiculo);
CREATE INDEX idx_reserva_tipo_reserva   ON reserva (id_tipo_reserva);
CREATE INDEX idx_reserva_estado         ON reserva (estado);
CREATE INDEX idx_reserva_fechas         ON reserva (fecha_inicio, fecha_fin_prevista);
