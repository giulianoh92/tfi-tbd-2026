-- 6 reservas con escenario NEA. Las fechas no se solapan con alquileres existentes
-- del mismo vehiculo (el disparador trg_reserva_no_overlap lo bloquearia).
-- Las reservas 1 y 2 se concretan a traves de los alquileres 4 y 5 (el disparador
-- fn_alquiler_start las marca como 'concretada' automaticamente).
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
    -- r6: Sofia Lopez (presencial Iguazu) reservo Kangoo en Corrientes, despues cancelo
    (6, 8,  2, '2026-06-01 09:00:00', '2026-06-03 09:00:00', 'cancelada');

-- Reservas no-show (R12): pendientes cuya ventana de retiro vencio hace mas
-- de 24h y que el cliente nunca concreto (sin alquiler asociado). La tarea
-- programada pa_expirar_reservas_vencidas las cancela en lote y desactiva sus
-- garantias. Fechas pasadas (marzo-mayo 2026), vehiculos/periodos que no se
-- solapan con reservas pendiente/concretada ni alquileres activos existentes
-- (no disparan excl_reserva_overlap).
INSERT INTO reserva (id_cliente, id_vehiculo, id_tipo_reserva, fecha_inicio, fecha_fin_prevista, estado) VALUES
    -- r7: Juan Perez (Posadas) reservo el Fiat Cronos y nunca se presento, tipo estandar (con garantia)
    (1, 1,  1, '2026-03-20 09:00:00', '2026-03-25 09:00:00', 'pendiente'),
    -- r8: Maria Gomez (CABA) reservo el Toyota Corolla, tipo express (sin garantia)
    (2, 2,  2, '2026-03-22 10:00:00', '2026-03-27 10:00:00', 'pendiente'),
    -- r9: Luis Rodriguez (Obera) reservo el Chevrolet Onix, tipo estandar (con garantia)
    (3, 4,  1, '2026-04-02 08:00:00', '2026-04-06 08:00:00', 'pendiente'),
    -- r10: Ana Sanchez (Corrientes) reservo la Toyota Hilux, tipo corporativa (sin garantia)
    (4, 5,  3, '2026-04-08 08:00:00', '2026-04-12 08:00:00', 'pendiente'),
    -- r11: Carlos Martinez (Resistencia) reservo la Kangoo, tipo estandar (con garantia)
    (5, 8,  1, '2026-04-20 10:00:00', '2026-04-25 10:00:00', 'pendiente'),
    -- r12: Pedro Fernandez (presencial Posadas) reservo el Jeep Renegade, tipo estandar (con garantia)
    (7, 6,  1, '2026-05-10 09:00:00', '2026-05-15 09:00:00', 'pendiente');
