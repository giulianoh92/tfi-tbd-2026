-- Patron de dos pasos para alquileres cerrados:
--   1. INSERT con estado='activo' y fecha_devolucion_real=NULL.
--   2. UPDATE asignando fecha_devolucion_real, km_fin, id_sucursal_devolucion.
-- El disparador trg_alquiler_set_cerrado (BEFORE UPDATE) cambia el estado a
-- 'cerrado'; trg_alquiler_close (AFTER UPDATE) cierra historial + ubicacion,
-- abre nueva ubicacion en la sucursal de devolucion, refleja
-- vehiculo.id_estado='disponible' y actualiza vehiculo.km_actuales.

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
-- Devolucion en sucursal distinta al retiro: retiro Posadas (1), devolucion
-- Corrientes (4) tras 22h de demora (cobra recargo). Ejercita el caso
-- id_sucursal_devolucion != origen.
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

-- Alquileres CERRADOS de mayo 2026 (R13): cubren cinco sucursales de origen
-- distintas (Posadas, Obera, Iguazu, Corrientes, Resistencia) para que la
-- tarea programada pa_cerrar_facturacion_mensual consolide varias filas en
-- resumen_mensual_sucursal con numeros variados. Presenciales (id_reserva
-- NULL) sobre vehiculos en estado limpio. Patron de dos pasos: INSERT activo
-- + UPDATE de cierre (dispara fn_alquiler_close, devolucion en la sucursal de
-- origen). Las fechas de mayo no se solapan con periodos activos existentes y
-- los cerrados no participan de excl_alquiler_overlap.

-- Alquiler 6: v1 Fiat Cronos (origen Posadas, 1), 5 dias, devolucion 4h tarde.
INSERT INTO alquiler (id_reserva, id_cliente, id_vehiculo, id_tarifa, id_sucursal_devolucion, fecha_inicio, fecha_fin_prevista, fecha_devolucion_real, km_inicio, km_fin, estado)
VALUES (NULL, 1, 1, 1, NULL, '2026-05-05 09:00:00', '2026-05-10 09:00:00', NULL, 35620, NULL, 'activo');

UPDATE alquiler
SET fecha_devolucion_real  = '2026-05-10 13:00:00',
    km_fin                 = 36200,
    id_sucursal_devolucion = 1
WHERE id_alquiler = 6;

-- Alquiler 7: v4 Chevrolet Onix (origen Obera, 2), 4 dias, devolucion en hora.
INSERT INTO alquiler (id_reserva, id_cliente, id_vehiculo, id_tarifa, id_sucursal_devolucion, fecha_inicio, fecha_fin_prevista, fecha_devolucion_real, km_inicio, km_fin, estado)
VALUES (NULL, 3, 4, 3, NULL, '2026-05-08 08:00:00', '2026-05-12 08:00:00', NULL, 41000, NULL, 'activo');

UPDATE alquiler
SET fecha_devolucion_real  = '2026-05-12 08:00:00',
    km_fin                 = 41450,
    id_sucursal_devolucion = 2
WHERE id_alquiler = 7;

-- Alquiler 8: v7 Toyota SW4 (origen Iguazu, 3), 7 dias, devolucion 5h tarde.
INSERT INTO alquiler (id_reserva, id_cliente, id_vehiculo, id_tarifa, id_sucursal_devolucion, fecha_inicio, fecha_fin_prevista, fecha_devolucion_real, km_inicio, km_fin, estado)
VALUES (NULL, 2, 7, 5, NULL, '2026-05-12 08:00:00', '2026-05-19 08:00:00', NULL, 15000, NULL, 'activo');

UPDATE alquiler
SET fecha_devolucion_real  = '2026-05-19 13:00:00',
    km_fin                 = 16100,
    id_sucursal_devolucion = 3
WHERE id_alquiler = 8;

-- Alquiler 9: v8 Renault Kangoo (origen Corrientes, 4), 3 dias, devolucion en hora.
INSERT INTO alquiler (id_reserva, id_cliente, id_vehiculo, id_tarifa, id_sucursal_devolucion, fecha_inicio, fecha_fin_prevista, fecha_devolucion_real, km_inicio, km_fin, estado)
VALUES (NULL, 4, 8, 8, NULL, '2026-05-15 09:00:00', '2026-05-18 09:00:00', NULL, 65000, NULL, 'activo');

UPDATE alquiler
SET fecha_devolucion_real  = '2026-05-18 09:00:00',
    km_fin                 = 65300,
    id_sucursal_devolucion = 4
WHERE id_alquiler = 9;

-- Alquiler 10: v10 VW T-Cross (origen Resistencia, 5), 6 dias, devolucion 10h tarde.
INSERT INTO alquiler (id_reserva, id_cliente, id_vehiculo, id_tarifa, id_sucursal_devolucion, fecha_inicio, fecha_fin_prevista, fecha_devolucion_real, km_inicio, km_fin, estado)
VALUES (NULL, 5, 10, 10, NULL, '2026-05-20 10:00:00', '2026-05-26 10:00:00', NULL, 12000, NULL, 'activo');

UPDATE alquiler
SET fecha_devolucion_real  = '2026-05-26 20:00:00',
    km_fin                 = 12950,
    id_sucursal_devolucion = 5
WHERE id_alquiler = 10;
