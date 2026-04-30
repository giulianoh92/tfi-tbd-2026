CREATE INDEX IF NOT EXISTS idx_reserva_cliente   ON reserva (id_cliente);
CREATE INDEX IF NOT EXISTS idx_reserva_vehiculo  ON reserva (id_vehiculo);
CREATE INDEX IF NOT EXISTS idx_reserva_estado    ON reserva (estado);
CREATE INDEX IF NOT EXISTS idx_reserva_fechas    ON reserva (fecha_inicio, fecha_fin_prevista);
