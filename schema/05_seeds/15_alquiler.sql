-- Two-step pattern for closed alquileres: INSERT with estado='activo' / fecha_devolucion_real=NULL,
-- then UPDATE to set fecha_devolucion_real, km_fin, id_sucursal_devolucion.
-- The BEFORE UPDATE trigger sets estado='cerrado'; the AFTER UPDATE trigger closes historial+ubicacion.

-- Alquiler 1: vehiculo 1 (Corolla), cerrado, devolucion en Centro
INSERT INTO alquiler (id_reserva, id_cliente, id_vehiculo, id_tarifa, id_sucursal_devolucion, fecha_inicio, fecha_fin_prevista, fecha_devolucion_real, km_inicio, km_fin, estado)
VALUES (NULL, 1, 1, 1, NULL, '2026-01-10 09:00:00', '2026-01-15 09:00:00', NULL, 35000, NULL, 'activo');

UPDATE alquiler
SET fecha_devolucion_real  = '2026-01-15 11:30:00',
    km_fin                 = 35620,
    id_sucursal_devolucion = 1
WHERE id_alquiler = 1;

-- Alquiler 2: vehiculo 2 (Tiguan), cerrado, devolucion en Palermo
INSERT INTO alquiler (id_reserva, id_cliente, id_vehiculo, id_tarifa, id_sucursal_devolucion, fecha_inicio, fecha_fin_prevista, fecha_devolucion_real, km_inicio, km_fin, estado)
VALUES (NULL, 2, 2, 2, NULL, '2026-01-20 10:00:00', '2026-01-27 10:00:00', NULL, 18000, NULL, 'activo');

UPDATE alquiler
SET fecha_devolucion_real  = '2026-01-28 08:00:00',
    km_fin                 = 18780,
    id_sucursal_devolucion = 2
WHERE id_alquiler = 2;

-- Alquiler 3: vehiculo 6 (Tracker), cerrado, devolucion en San Isidro
INSERT INTO alquiler (id_reserva, id_cliente, id_vehiculo, id_tarifa, id_sucursal_devolucion, fecha_inicio, fecha_fin_prevista, fecha_devolucion_real, km_inicio, km_fin, estado)
VALUES (NULL, 5, 6, 5, NULL, '2026-02-01 09:00:00', '2026-02-05 09:00:00', NULL, 15000, NULL, 'activo');

UPDATE alquiler
SET fecha_devolucion_real  = '2026-02-05 10:00:00',
    km_fin                 = 15320,
    id_sucursal_devolucion = 3
WHERE id_alquiler = 3;

-- Alquiler 4: vehiculo 3 (Focus), activo, linked to reserva 1 (trigger marks reserva 1 as concretada)
INSERT INTO alquiler (id_reserva, id_cliente, id_vehiculo, id_tarifa, id_sucursal_devolucion, fecha_inicio, fecha_fin_prevista, fecha_devolucion_real, km_inicio, km_fin, estado)
VALUES (1, 3, 3, 3, NULL, '2026-03-01 09:00:00', '2026-03-07 09:00:00', NULL, 52000, NULL, 'activo');

-- Alquiler 5: vehiculo 9 (Polo), activo, linked to reserva 2 (trigger marks reserva 2 as concretada)
INSERT INTO alquiler (id_reserva, id_cliente, id_vehiculo, id_tarifa, id_sucursal_devolucion, fecha_inicio, fecha_fin_prevista, fecha_devolucion_real, km_inicio, km_fin, estado)
VALUES (2, 4, 9, 8, NULL, '2026-03-10 10:00:00', '2026-03-15 10:00:00', NULL, 38000, NULL, 'activo');
