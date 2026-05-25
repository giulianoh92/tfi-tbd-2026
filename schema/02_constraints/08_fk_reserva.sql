-- FKs de reserva (R7).
--
-- ON DELETE RESTRICT en las tres referencias (cliente, vehiculo,
-- tipo_reserva): la reserva es un documento de negocio y nunca queremos
-- borrar maestros que la sostengan. Para "anular" una reserva existe el
-- procedure pa_cancelar_reserva (R8) que cambia el estado, sin tocar las
-- referencias.
ALTER TABLE reserva
    ADD CONSTRAINT fk_reserva_cliente
        FOREIGN KEY (id_cliente)
        REFERENCES cliente (id_cliente)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    ADD CONSTRAINT fk_reserva_vehiculo
        FOREIGN KEY (id_vehiculo)
        REFERENCES vehiculo (id_vehiculo)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    ADD CONSTRAINT fk_reserva_tipo
        FOREIGN KEY (id_tipo_reserva)
        REFERENCES tipo_reserva (id_tipo_reserva)
        ON UPDATE CASCADE
        ON DELETE RESTRICT;
