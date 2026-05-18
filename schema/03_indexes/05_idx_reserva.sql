CREATE INDEX idx_reserva_cliente        ON reserva (id_cliente);
CREATE INDEX idx_reserva_vehiculo       ON reserva (id_vehiculo);
CREATE INDEX idx_reserva_tipo_reserva   ON reserva (id_tipo_reserva);
CREATE INDEX idx_reserva_estado         ON reserva (estado);
CREATE INDEX idx_reserva_fechas         ON reserva (fecha_inicio, fecha_fin_prevista);
