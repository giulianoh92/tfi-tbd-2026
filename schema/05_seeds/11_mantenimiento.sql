-- Mantenimientos: dos cerrados (historial) y uno abierto (vehiculo en taller)
INSERT INTO mantenimiento (id_vehiculo, id_taller, fecha_envio, fecha_devolucion, observaciones) VALUES
    (1, 1, '2025-12-01 09:00', '2025-12-05 17:00', 'Service de 30.000 km: cambio de aceite, filtros y pastillas de freno.'),
    (7, 3, '2026-02-15 10:00', '2026-02-20 16:00', 'Reparacion de embrague y revision de tren delantero.'),
    (5, 2, '2026-04-20 11:00', NULL,               'Falla en caja de cambios. Diagnostico en curso.');
