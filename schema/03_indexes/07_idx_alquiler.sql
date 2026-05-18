CREATE INDEX idx_alquiler_cliente               ON alquiler (id_cliente);
CREATE INDEX idx_alquiler_vehiculo              ON alquiler (id_vehiculo);
CREATE INDEX idx_alquiler_tarifa                ON alquiler (id_tarifa);
CREATE INDEX idx_alquiler_sucursal_devolucion   ON alquiler (id_sucursal_devolucion);
CREATE INDEX idx_alquiler_estado                ON alquiler (estado);
CREATE INDEX idx_alquiler_fechas                ON alquiler (fecha_inicio, fecha_fin_prevista);
