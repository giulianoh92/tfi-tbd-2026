-- Patron de dos pasos para mantenimientos cerrados: INSERT con fecha_devolucion=NULL,
-- luego UPDATE asignando la fecha. Los disparadores fn_mantenimiento_envio y
-- fn_mantenimiento_devolucion propagan el estado del vehiculo via catalogo.
--
-- Talleres asignados por proximidad geografica a la sucursal de origen del vehiculo.

-- Mantenimiento 1: v8 Renault Kangoo (Corrientes), cerrado.
-- Taller 2 (Mecanica Corrientes Centro) - service de rutina.
INSERT INTO mantenimiento (id_vehiculo, id_taller, fecha_envio, fecha_devolucion, observaciones)
VALUES (8, 2, '2026-01-05', NULL, 'Cambio de aceite y revision general post-uso intensivo de carga');

UPDATE mantenimiento
SET fecha_devolucion = '2026-01-08'
WHERE id_mantenimiento = 1;

-- Mantenimiento 2: v7 Toyota SW4 (Iguazu), cerrado.
-- Taller 3 (Iguazu Auto Service) - reparacion de suspension tras circuito off-road.
INSERT INTO mantenimiento (id_vehiculo, id_taller, fecha_envio, fecha_devolucion, observaciones)
VALUES (7, 3, '2026-02-10', NULL, 'Reparacion suspension delantera tras circuito off-road');

UPDATE mantenimiento
SET fecha_devolucion = '2026-02-15'
WHERE id_mantenimiento = 2;

-- Mantenimiento 3: v5 Toyota Hilux (Obera), abierto.
-- Taller 1 (Posadas Motors) - revision frenos y escape antes de temporada alta.
-- El trigger fn_mantenimiento_envio transiciona el vehiculo a 'en_mantenimiento'.
INSERT INTO mantenimiento (id_vehiculo, id_taller, fecha_envio, fecha_devolucion, observaciones)
VALUES (5, 1, '2026-03-05', NULL, 'Revision frenos y sistema de escape pre-temporada alta');
