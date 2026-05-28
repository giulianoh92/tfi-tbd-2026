-- Indices de soporte para las FKs de vehiculo.
--
-- Postgres no genera indices automaticamente sobre la columna de origen
-- de una clave fornea. Estos tres aceleran tanto las combinaciones tipicas
-- del listado de vehiculos por sucursal/tipo/estado como las validaciones
-- en cascada del motor cuando se actualiza el maestro referenciado.
CREATE INDEX idx_vehiculo_sucursal_origen ON vehiculo (id_sucursal_origen);
CREATE INDEX idx_vehiculo_tipo            ON vehiculo (id_tipo);
CREATE INDEX idx_vehiculo_estado          ON vehiculo (id_estado);
