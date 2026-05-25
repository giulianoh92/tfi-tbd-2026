-- Indices de alquiler (R6, R10).
--
-- Soportan las FKs y las consultas tipicas del panel: alquileres por
-- cliente, por vehiculo, por sucursal de devolucion. El indice por estado
-- alimenta la vista vw_alquileres_activos. El indice por (fecha_inicio,
-- fecha_fin_prevista) acompana la validacion de overlap temporal del
-- trigger fn_check_vehiculo_overlap antes de que actue la EXCLUDE.
CREATE INDEX idx_alquiler_cliente               ON alquiler (id_cliente);
CREATE INDEX idx_alquiler_vehiculo              ON alquiler (id_vehiculo);
CREATE INDEX idx_alquiler_tarifa                ON alquiler (id_tarifa);
CREATE INDEX idx_alquiler_sucursal_devolucion   ON alquiler (id_sucursal_devolucion);
CREATE INDEX idx_alquiler_estado                ON alquiler (estado);
CREATE INDEX idx_alquiler_fechas                ON alquiler (fecha_inicio, fecha_fin_prevista);
