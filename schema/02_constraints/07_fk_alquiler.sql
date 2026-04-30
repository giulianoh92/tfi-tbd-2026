ALTER TABLE alquiler
    ADD CONSTRAINT fk_alquiler_reserva
        FOREIGN KEY (id_reserva) REFERENCES reserva (id_reserva)
        ON UPDATE CASCADE ON DELETE SET NULL;

ALTER TABLE alquiler
    ADD CONSTRAINT fk_alquiler_cliente
        FOREIGN KEY (id_cliente) REFERENCES cliente (id_cliente)
        ON UPDATE CASCADE ON DELETE RESTRICT;

ALTER TABLE alquiler
    ADD CONSTRAINT fk_alquiler_vehiculo
        FOREIGN KEY (id_vehiculo) REFERENCES vehiculo (id_vehiculo)
        ON UPDATE CASCADE ON DELETE RESTRICT;

ALTER TABLE alquiler
    ADD CONSTRAINT fk_alquiler_tarifa
        FOREIGN KEY (id_tarifa) REFERENCES tarifa (id_tarifa)
        ON UPDATE CASCADE ON DELETE RESTRICT;
