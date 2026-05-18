ALTER TABLE garantia_reserva
    ADD CONSTRAINT fk_garantia_reserva
        FOREIGN KEY (id_reserva)
        REFERENCES reserva (id_reserva)
        ON UPDATE CASCADE
        ON DELETE CASCADE;
