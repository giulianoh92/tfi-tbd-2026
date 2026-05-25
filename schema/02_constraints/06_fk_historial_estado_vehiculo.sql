-- FKs de historial_estado_vehiculo (R10).
--
-- ON DELETE CASCADE a vehiculo: el historial de transiciones acompana al
-- vehiculo. ON DELETE RESTRICT a estado_vehiculo: el catalogo de estados
-- no admite baja si hay historial referenciandolo, para preservar la
-- trazabilidad pasada de la maquina de estados.
ALTER TABLE historial_estado_vehiculo
    ADD CONSTRAINT fk_historial_vehiculo
        FOREIGN KEY (id_vehiculo)
        REFERENCES vehiculo (id_vehiculo)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    ADD CONSTRAINT fk_historial_estado
        FOREIGN KEY (id_estado)
        REFERENCES estado_vehiculo (id_estado)
        ON UPDATE CASCADE
        ON DELETE RESTRICT;
