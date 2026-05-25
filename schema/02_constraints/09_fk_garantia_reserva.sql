-- FK garantia_reserva -> reserva (R7).
--
-- ON DELETE CASCADE: la garantia es accesoria a la reserva, no tiene
-- entidad propia. Si la reserva desaparece (caso excepcional, no por
-- cancelacion: la cancelacion cambia el estado), la garantia tambien.
ALTER TABLE garantia_reserva
    ADD CONSTRAINT fk_garantia_reserva
        FOREIGN KEY (id_reserva)
        REFERENCES reserva (id_reserva)
        ON UPDATE CASCADE
        ON DELETE CASCADE;
