-- One vigente row per vehicle (fecha_hasta IS NULL), matching origin sucursal.
-- The partial unique index uq_ubicacion_vehiculo_vigente enforces one open row per vehicle.
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
