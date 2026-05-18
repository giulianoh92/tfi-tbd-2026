-- Patron de dos pasos para alquileres cerrados:
--   1. INSERT con estado='activo' y fecha_devolucion_real=NULL.
--   2. UPDATE seteando fecha_devolucion_real, km_fin, id_sucursal_devolucion.
-- El trigger trg_alquiler_set_cerrado (BEFORE UPDATE) cambia estado a 'cerrado';
-- trg_alquiler_close (AFTER UPDATE) cierra historial + ubicacion, abre nueva
-- ubicacion en la sucursal de devolucion, mirrorea vehiculo.id_estado='disponible'
-- y actualiza vehiculo.km_actuales.

-- Alquiler 1: v1 Fiat Cronos, cliente Juan Perez (Posadas), 5 dias en zona Posadas,
-- devolucion en sucursal de origen (1) con 2h30m de demora.
INSERT INTO alquiler (id_reserva, id_cliente, id_vehiculo, id_tarifa, id_sucursal_devolucion, fecha_inicio, fecha_fin_prevista, fecha_devolucion_real, km_inicio, km_fin, estado)
VALUES (NULL, 1, 1, 1, NULL, '2026-01-10 09:00:00', '2026-01-15 09:00:00', NULL, 35000, NULL, 'activo');

UPDATE alquiler
SET fecha_devolucion_real  = '2026-01-15 11:30:00',
    km_fin                 = 35620,
    id_sucursal_devolucion = 1
WHERE id_alquiler = 1;

-- Alquiler 2: v2 Toyota Corolla, cliente Maria Gomez (turista CABA), 7 dias.
-- Cross-branch return: retiro Posadas (1), devolucion Corrientes (4) tras 22h
-- de demora (cobra recargo). Demuestra feature id_sucursal_devolucion != origen.
INSERT INTO alquiler (id_reserva, id_cliente, id_vehiculo, id_tarifa, id_sucursal_devolucion, fecha_inicio, fecha_fin_prevista, fecha_devolucion_real, km_inicio, km_fin, estado)
VALUES (NULL, 2, 2, 1, NULL, '2026-01-20 10:00:00', '2026-01-27 10:00:00', NULL, 18000, NULL, 'activo');

UPDATE alquiler
SET fecha_devolucion_real  = '2026-01-28 08:00:00',
    km_fin                 = 18780,
    id_sucursal_devolucion = 4
WHERE id_alquiler = 2;

-- Alquiler 3: v6 Jeep Renegade, cliente Carlos Martinez (Resistencia), 4 dias
-- de turismo en Iguazu. Devolucion en Iguazu (3) con 1h de demora.
INSERT INTO alquiler (id_reserva, id_cliente, id_vehiculo, id_tarifa, id_sucursal_devolucion, fecha_inicio, fecha_fin_prevista, fecha_devolucion_real, km_inicio, km_fin, estado)
VALUES (NULL, 5, 6, 5, NULL, '2026-02-01 09:00:00', '2026-02-05 09:00:00', NULL, 15000, NULL, 'activo');

UPDATE alquiler
SET fecha_devolucion_real  = '2026-02-05 10:00:00',
    km_fin                 = 15320,
    id_sucursal_devolucion = 3
WHERE id_alquiler = 3;

-- Alquiler 4: v3 VW Gol Trend, cliente Luis Rodriguez (Obera), activo,
-- vinculado a reserva 1 (el trigger marca reserva 1 como concretada).
INSERT INTO alquiler (id_reserva, id_cliente, id_vehiculo, id_tarifa, id_sucursal_devolucion, fecha_inicio, fecha_fin_prevista, fecha_devolucion_real, km_inicio, km_fin, estado)
VALUES (1, 3, 3, 3, NULL, '2026-03-01 09:00:00', '2026-03-07 09:00:00', NULL, 52000, NULL, 'activo');

-- Alquiler 5: v9 Ford Ranger, cliente Ana Sanchez (Corrientes), activo,
-- vinculado a reserva 2 (el trigger marca reserva 2 como concretada).
INSERT INTO alquiler (id_reserva, id_cliente, id_vehiculo, id_tarifa, id_sucursal_devolucion, fecha_inicio, fecha_fin_prevista, fecha_devolucion_real, km_inicio, km_fin, estado)
VALUES (2, 4, 9, 7, NULL, '2026-03-10 10:00:00', '2026-03-15 10:00:00', NULL, 38000, NULL, 'activo');
