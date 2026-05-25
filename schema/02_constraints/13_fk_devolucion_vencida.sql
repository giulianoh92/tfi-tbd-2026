-- FKs de devolucion_vencida (R9).
--
-- ON DELETE CASCADE en id_alquiler: si por alguna razon (correccion manual,
-- DBA) se elimina un alquiler, la fila historica deja de tener sentido y
-- se borra. ON DELETE RESTRICT en vehiculo/cliente: nunca queremos perder
-- referencia del cliente o el vehiculo que tuvieron una devolucion vencida.
ALTER TABLE devolucion_vencida
    ADD CONSTRAINT fk_devolucion_vencida_alquiler
        FOREIGN KEY (id_alquiler)
        REFERENCES alquiler (id_alquiler)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    ADD CONSTRAINT fk_devolucion_vencida_vehiculo
        FOREIGN KEY (id_vehiculo)
        REFERENCES vehiculo (id_vehiculo)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    ADD CONSTRAINT fk_devolucion_vencida_cliente
        FOREIGN KEY (id_cliente)
        REFERENCES cliente (id_cliente)
        ON UPDATE CASCADE
        ON DELETE RESTRICT;
