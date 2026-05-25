-- One vigente row per vehicle (fecha_fin IS NULL), with 'disponible' for all.
-- The partial unique index uq_historial_estado_vigente enforces one open row per vehicle.
-- Lifecycle triggers (alquiler/mantenimiento seeds) will close these and insert new state rows.
INSERT INTO historial_estado_vehiculo (id_vehiculo, id_estado, fecha_inicio, fecha_fin, motivo)
SELECT v.id_vehiculo,
       (SELECT id_estado FROM estado_vehiculo WHERE nombre = 'disponible'),
       '2026-01-01 00:00:00',
       NULL,
       'Alta inicial del vehiculo'
FROM vehiculo v
ORDER BY v.id_vehiculo;
