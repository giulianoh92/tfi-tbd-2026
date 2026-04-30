-- Alquileres: 3 finalizados con factura, 2 en curso (walk-in)
--   alq 1 -> reserva 1, finalizado a tiempo
--   alq 2 -> reserva 3, finalizado con 24 hs de retraso (genera recargo)
--   alq 3 -> walk-in (sin reserva), finalizado
--   alq 4 -> walk-in, en curso
--   alq 5 -> walk-in, en curso
INSERT INTO alquiler (id_reserva, id_cliente, id_vehiculo, id_tarifa, fecha_inicio, fecha_fin_prevista, fecha_devolucion_real, km_inicio, km_fin, estado) VALUES
    (1,    1, 1, 1, '2026-01-15 10:00', '2026-01-20 10:00', '2026-01-20 09:30', 30000, 30850, 'finalizado'),
    (3,    3, 8, 8, '2026-02-20 12:00', '2026-02-28 12:00', '2026-03-01 12:00', 60000, 60800, 'finalizado'),
    (NULL, 6, 4, 5, '2026-03-10 11:00', '2026-03-15 11:00', '2026-03-15 10:00', 18000, 18900, 'finalizado'),
    (NULL, 7, 9, 9, '2026-04-25 09:00', '2026-04-30 09:00', NULL,               37500, NULL,  'en_curso'),
    (NULL, 5, 3, 3, '2026-04-28 14:00', '2026-05-05 14:00', NULL,               51500, NULL,  'en_curso');
