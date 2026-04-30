-- Reservas: mix de estados.
--   reserva 1 -> se concreto en alquiler 1 (estado 'confirmada')
--   reserva 2 -> cancelada antes del retiro
--   reserva 3 -> se concreto en alquiler 2 (estado 'confirmada')
--   reserva 4 -> 'expirada' (no-show del cliente)
--   reserva 5 -> 'pendiente' a futuro
--   reserva 6 -> 'confirmada' a futuro
INSERT INTO reserva (id_cliente, id_vehiculo, fecha_inicio, fecha_fin_prevista, estado, fecha_creacion) VALUES
    (1, 1,  '2026-01-15 10:00', '2026-01-20 10:00', 'confirmada', '2026-01-10 14:30'),
    (2, 2,  '2026-02-10 09:00', '2026-02-15 09:00', 'cancelada',  '2026-02-05 11:00'),
    (3, 8,  '2026-02-20 12:00', '2026-02-28 12:00', 'confirmada', '2026-02-18 16:00'),
    (4, 1,  '2026-03-01 10:00', '2026-03-05 10:00', 'expirada',   '2026-02-25 09:30'),
    (5, 10, '2026-05-15 11:00', '2026-05-20 11:00', 'pendiente',  '2026-04-25 17:00'),
    (1, 6,  '2026-05-25 10:00', '2026-06-01 10:00', 'confirmada', '2026-04-28 12:00');
