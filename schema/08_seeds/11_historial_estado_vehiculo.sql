-- Datos demo de historial_estado_vehiculo (R10).
-- Una unica fila vigente por vehiculo (fecha_fin IS NULL) con estado
-- 'disponible' como punto de partida. El UNIQUE parcial
-- uq_historial_estado_vigente sostiene la invariante en la BD. Los
-- triggers de lifecycle (disparados por los seeds posteriores de alquiler
-- y mantenimiento) cierran estas filas y abren las siguientes a medida
-- que el FSM evoluciona.
INSERT INTO historial_estado_vehiculo (id_vehiculo, id_estado, fecha_inicio, fecha_fin, motivo)
SELECT v.id_vehiculo,
       (SELECT id_estado FROM estado_vehiculo WHERE nombre = 'disponible'),
       '2026-01-01 00:00:00',
       NULL,
       'Alta inicial del vehiculo'
FROM vehiculo v
ORDER BY v.id_vehiculo;
