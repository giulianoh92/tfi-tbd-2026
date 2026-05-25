-- FKs de mantenimiento.
--
-- ON DELETE CASCADE a vehiculo: el historial de mantenimiento es
-- accesorio al vehiculo. ON DELETE RESTRICT a taller: un taller con
-- historial de servicios prestados no se puede borrar (preserva la
-- trazabilidad de a donde se envio cada vehiculo).
ALTER TABLE mantenimiento
    ADD CONSTRAINT fk_mantenimiento_vehiculo
        FOREIGN KEY (id_vehiculo)
        REFERENCES vehiculo (id_vehiculo)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    ADD CONSTRAINT fk_mantenimiento_taller
        FOREIGN KEY (id_taller)
        REFERENCES taller (id_taller)
        ON UPDATE CASCADE
        ON DELETE RESTRICT;
