-- Una unica tarifa por combinacion (sucursal, tipo_vehiculo)
ALTER TABLE tarifa
    ADD CONSTRAINT uq_tarifa_sucursal_tipo UNIQUE (id_sucursal, id_tipo);

-- El "orden" de imagen es unico dentro de cada vehiculo
ALTER TABLE imagen_vehiculo
    ADD CONSTRAINT uq_imagen_vehiculo_orden UNIQUE (id_vehiculo, orden);
