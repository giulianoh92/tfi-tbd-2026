-- Datos demo de garantia_reserva (R7).
-- Tres garantias asociadas a las reservas 1, 3 y 5 (las del tipo
-- 'estandar', que tiene requiere_garantia = TRUE). El numero de tarjeta
-- se almacena con bcrypt (crypt + gen_salt('bf'), de pgcrypto): estos datos
-- demuestran que la columna numero_tarjeta_hash nunca recibe el numero en
-- claro, en linea con la politica de la tabla.
INSERT INTO garantia_reserva (id_reserva, tipo, titular, numero_tarjeta_hash, vencimiento, activa) VALUES
    (1, 'Visa',       'Luis Rodriguez', crypt('4111111111111111', gen_salt('bf')), '2028-12-31', TRUE),
    (3, 'Mastercard', 'Juan Perez',     crypt('5500000000000004', gen_salt('bf')), '2027-09-30', TRUE),
    (5, 'Visa',       'Carlos Martinez',crypt('4111111111111111', gen_salt('bf')), '2029-06-30', TRUE);

-- Garantias de las reservas no-show estandar (r7, r9, r11, r12). Nacen
-- activas; la tarea programada pa_expirar_reservas_vencidas las pasa a
-- activa=FALSE en lote cuando expira la reserva asociada (baja logica con
-- trazabilidad), demostrando la desactivacion masiva.
INSERT INTO garantia_reserva (id_reserva, tipo, titular, numero_tarjeta_hash, vencimiento, activa) VALUES
    (7,  'Visa',       'Juan Perez',      crypt('4111111111111111', gen_salt('bf')), '2028-03-31', TRUE),
    (9,  'Mastercard', 'Luis Rodriguez',  crypt('5500000000000004', gen_salt('bf')), '2027-11-30', TRUE),
    (11, 'Mastercard', 'Carlos Martinez', crypt('5500000000000004', gen_salt('bf')), '2028-08-31', TRUE),
    (12, 'Visa',       'Pedro Fernandez', crypt('4111111111111111', gen_salt('bf')), '2029-01-31', TRUE);
