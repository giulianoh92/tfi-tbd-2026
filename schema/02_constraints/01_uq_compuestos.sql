ALTER TABLE tarifa
    ADD CONSTRAINT uq_tarifa_sucursal_tipo UNIQUE (id_sucursal, id_tipo);

ALTER TABLE imagen_vehiculo
    ADD CONSTRAINT uq_imagen_vehiculo_orden UNIQUE (id_vehiculo, orden);
