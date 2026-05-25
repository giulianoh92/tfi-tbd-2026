-- FKs de vehiculo.
--
-- ON DELETE RESTRICT en las tres referencias (sucursal, tipo, estado):
-- nunca se admite borrar un maestro que tenga vehiculos colgados. Es la
-- politica conservadora correcta para entidades de catalogo cuya
-- desaparicion dejaria al vehiculo en estado inconsistente. La forma de
-- "retirar" un vehiculo de la flota es ponerlo en estado
-- 'fuera_de_servicio', no borrarlo.
ALTER TABLE vehiculo
    ADD CONSTRAINT fk_vehiculo_sucursal
        FOREIGN KEY (id_sucursal_origen)
        REFERENCES sucursal (id_sucursal)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    ADD CONSTRAINT fk_vehiculo_tipo
        FOREIGN KEY (id_tipo)
        REFERENCES tipo_vehiculo (id_tipo)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    ADD CONSTRAINT fk_vehiculo_estado
        FOREIGN KEY (id_estado)
        REFERENCES estado_vehiculo (id_estado)
        ON UPDATE CASCADE
        ON DELETE RESTRICT;
