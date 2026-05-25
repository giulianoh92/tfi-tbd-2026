-- 6 reservas con escenario NEA. Fechas no se superponen con alquileres existentes
-- del mismo vehiculo (trigger trg_reserva_no_overlap lo bloquearia).
-- Reservas 1 y 2 se concretan via alquileres 4 y 5 (el trigger fn_alquiler_start
-- las marca como 'concretada' automaticamente).
INSERT INTO reserva (id_cliente, id_vehiculo, id_tipo_reserva, fecha_inicio, fecha_fin_prevista, estado) VALUES
    -- r1: Luis Rodriguez (Obera) reserva el VW Gol Trend, tipo estandar (requiere garantia)
    (3, 3,  1, '2026-03-01 09:00:00', '2026-03-07 09:00:00', 'pendiente'),
    -- r2: Ana Sanchez (Corrientes) reserva la Ford Ranger, tipo express
    (4, 9,  2, '2026-03-10 10:00:00', '2026-03-15 10:00:00', 'pendiente'),
    -- r3: Juan Perez (Posadas) reserva el Jeep Renegade para escapada a Iguazu
    (1, 6,  1, '2026-04-01 08:00:00', '2026-04-05 08:00:00', 'pendiente'),
    -- r4: Maria Gomez (turista CABA) reserva la SW4 para turismo, tipo corporativa
    (2, 7,  3, '2026-04-10 08:00:00', '2026-04-15 08:00:00', 'pendiente'),
    -- r5: Carlos Martinez (Resistencia) reserva el VW T-Cross, tipo estandar
    (5, 10, 1, '2026-05-01 10:00:00', '2026-05-07 10:00:00', 'pendiente'),
    -- r6: Sofia Lopez (walk-in Iguazu) reservo Kangoo en Corrientes, despues cancelo
    (6, 8,  2, '2026-06-01 09:00:00', '2026-06-03 09:00:00', 'cancelada');
