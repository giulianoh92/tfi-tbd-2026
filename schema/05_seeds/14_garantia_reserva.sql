-- Garantias for reservas that require it (tipo_reserva.requiere_garantia = TRUE).
-- Reservas 1, 3, 5 are tipo 'estandar' (requiere_garantia = TRUE).
INSERT INTO garantia_reserva (id_reserva, tipo, titular, numero_tarjeta_hash, vencimiento, activa) VALUES
    (1, 'Visa',       'Luis Rodriguez', crypt('4111111111111111', gen_salt('bf')), '2028-12-31', TRUE),
    (3, 'Mastercard', 'Juan Perez',     crypt('5500000000000004', gen_salt('bf')), '2027-09-30', TRUE),
    (5, 'Visa',       'Carlos Martinez',crypt('4111111111111111', gen_salt('bf')), '2029-06-30', TRUE);
