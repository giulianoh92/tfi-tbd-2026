ALTER TABLE reserva
    ADD CONSTRAINT fk_reserva_cliente
        FOREIGN KEY (id_cliente) REFERENCES cliente (id_cliente)
        ON UPDATE CASCADE ON DELETE RESTRICT;

ALTER TABLE reserva
    ADD CONSTRAINT fk_reserva_vehiculo
        FOREIGN KEY (id_vehiculo) REFERENCES vehiculo (id_vehiculo)
        ON UPDATE CASCADE ON DELETE RESTRICT;
