-- Datos demo de ubicacion_vehiculo.
-- Una unica fila vigente por vehiculo (fecha_hasta IS NULL), apuntando a
-- la sucursal de origen. El UNIQUE parcial uq_ubicacion_vehiculo_vigente
-- garantiza esta invariante en la BD: cualquier intento de dejar dos
-- filas vigentes simultaneas aborta la transaccion.
INSERT INTO ubicacion_vehiculo (id_vehiculo, id_sucursal, fecha_desde, fecha_hasta) VALUES
    (1,  1, '2026-01-01 00:00:00', NULL),
    (2,  1, '2026-01-01 00:00:00', NULL),
    (3,  2, '2026-01-01 00:00:00', NULL),
    (4,  2, '2026-01-01 00:00:00', NULL),
    (5,  2, '2026-01-01 00:00:00', NULL),
    (6,  3, '2026-01-01 00:00:00', NULL),
    (7,  3, '2026-01-01 00:00:00', NULL),
    (8,  4, '2026-01-01 00:00:00', NULL),
    (9,  4, '2026-01-01 00:00:00', NULL),
    (10, 5, '2026-01-01 00:00:00', NULL);
