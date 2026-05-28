-- Indices de soporte para las FKs de mantenimiento.
--
-- Aceleran las consultas "historial de mantenimiento de un vehiculo" y
-- "todos los envios a un taller" que usan los paneles del personal.
CREATE INDEX idx_mantenimiento_vehiculo ON mantenimiento (id_vehiculo);
CREATE INDEX idx_mantenimiento_taller   ON mantenimiento (id_taller);
