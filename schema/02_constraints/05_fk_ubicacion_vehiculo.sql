-- FKs de ubicacion_vehiculo.
--
-- ON DELETE CASCADE a vehiculo: el historial de ubicacion fisica acompana
-- al vehiculo; si se borra el vehiculo (caso excepcional), las filas
-- pierden sentido. ON DELETE RESTRICT a sucursal: una sucursal no se
-- puede borrar mientras haya ubicaciones que la referencien (politica
-- conservadora sobre datos maestros).
ALTER TABLE ubicacion_vehiculo
    ADD CONSTRAINT fk_ubicacion_vehiculo_vehiculo
        FOREIGN KEY (id_vehiculo)
        REFERENCES vehiculo (id_vehiculo)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    ADD CONSTRAINT fk_ubicacion_vehiculo_sucursal
        FOREIGN KEY (id_sucursal)
        REFERENCES sucursal (id_sucursal)
        ON UPDATE CASCADE
        ON DELETE RESTRICT;
