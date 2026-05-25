-- Indice de soporte para la FK imagen_vehiculo -> vehiculo.
--
-- Acelera la consulta tipica de "todas las imagenes de un vehiculo" del
-- frontend y las validaciones del trigger trg_check_max_imagenes que
-- cuenta filas por id_vehiculo.
CREATE INDEX idx_imagen_vehiculo_vehiculo ON imagen_vehiculo (id_vehiculo);
