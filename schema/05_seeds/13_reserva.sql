-- Reserva 1 (vehiculo 3, estandar): will be concretada by alquiler seed (file 15).
-- Reserva 2 (vehiculo 9, express):  will be concretada by alquiler seed (file 15).
-- Reservas 3-6: standalone reservas on vehicles 6, 7, 8, 10 with non-overlapping dates.
INSERT INTO reserva (id_cliente, id_vehiculo, id_tipo_reserva, fecha_inicio, fecha_fin_prevista, estado) VALUES
    (3, 3,  1, '2026-03-01 09:00:00', '2026-03-07 09:00:00', 'pendiente'),
    (4, 9,  2, '2026-03-10 10:00:00', '2026-03-15 10:00:00', 'pendiente'),
    (1, 6,  1, '2026-04-01 08:00:00', '2026-04-05 08:00:00', 'pendiente'),
    (2, 7,  3, '2026-04-10 08:00:00', '2026-04-15 08:00:00', 'pendiente'),
    (5, 10, 1, '2026-05-01 10:00:00', '2026-05-07 10:00:00', 'pendiente'),
    (6, 8,  2, '2026-06-01 09:00:00', '2026-06-03 09:00:00', 'cancelada');
