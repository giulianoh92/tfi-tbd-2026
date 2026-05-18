CREATE INDEX idx_ubicacion_vehiculo_vehiculo  ON ubicacion_vehiculo (id_vehiculo);
CREATE INDEX idx_ubicacion_vehiculo_sucursal  ON ubicacion_vehiculo (id_sucursal);

CREATE UNIQUE INDEX uq_ubicacion_vehiculo_vigente
    ON ubicacion_vehiculo (id_vehiculo)
    WHERE fecha_hasta IS NULL;
