-- Indices de ubicacion_vehiculo.
--
-- Los dos primeros soportan las claves forneas y las combinaciones por
-- vehiculo/sucursal.
-- El UNIQUE PARCIAL uq_ubicacion_vehiculo_vigente garantiza UNA SOLA fila
-- vigente (fecha_hasta IS NULL) por vehiculo: el disparador de ciclo de vida,
-- al cambiar ubicacion, debe cerrar la fila anterior antes de insertar la
-- nueva. Cualquier error que intente dejar dos filas vigentes simultaneas
-- aborta la transaccion.
CREATE INDEX idx_ubicacion_vehiculo_vehiculo  ON ubicacion_vehiculo (id_vehiculo);
CREATE INDEX idx_ubicacion_vehiculo_sucursal  ON ubicacion_vehiculo (id_sucursal);

CREATE UNIQUE INDEX uq_ubicacion_vehiculo_vigente
    ON ubicacion_vehiculo (id_vehiculo)
    WHERE fecha_hasta IS NULL;
