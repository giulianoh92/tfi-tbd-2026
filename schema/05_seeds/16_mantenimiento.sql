-- Two-step pattern for closed mantenimientos: INSERT with fecha_devolucion=NULL,
-- then UPDATE to set fecha_devolucion.
-- The AFTER UPDATE trigger transitions the vehicle back to 'disponible'.

-- Mantenimiento 1: vehiculo 8 (Logan), cerrado
INSERT INTO mantenimiento (id_vehiculo, id_taller, fecha_envio, fecha_devolucion, observaciones)
VALUES (8, 3, '2026-01-05', NULL, 'Cambio de aceite y revision general');

UPDATE mantenimiento
SET fecha_devolucion = '2026-01-08'
WHERE id_mantenimiento = 1;

-- Mantenimiento 2: vehiculo 7 (Hilux), cerrado
INSERT INTO mantenimiento (id_vehiculo, id_taller, fecha_envio, fecha_devolucion, observaciones)
VALUES (7, 1, '2026-02-10', NULL, 'Reparacion suspension delantera');

UPDATE mantenimiento
SET fecha_devolucion = '2026-02-15'
WHERE id_mantenimiento = 2;

-- Mantenimiento 3: vehiculo 5 (208 GT), abierto -> trigger sets vehicle 5 to 'en_mantenimiento'
INSERT INTO mantenimiento (id_vehiculo, id_taller, fecha_envio, fecha_devolucion, observaciones)
VALUES (5, 2, '2026-03-05', NULL, 'Revision frenos y sistema de escape');
