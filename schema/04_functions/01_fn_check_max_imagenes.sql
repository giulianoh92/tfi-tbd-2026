-- Limita a 5 imagenes por vehiculo (segun enunciado: "entre 1 y 5 imagenes").
-- El minimo de 1 se valida desde la capa de aplicacion al crear el vehiculo,
-- ya que un trigger no puede exigir filas en una tabla relacionada.
CREATE OR REPLACE FUNCTION fn_check_max_imagenes()
RETURNS TRIGGER AS $$
BEGIN
    IF (SELECT COUNT(*) FROM imagen_vehiculo WHERE id_vehiculo = NEW.id_vehiculo) >= 5 THEN
        RAISE EXCEPTION 'El vehiculo % ya tiene 5 imagenes (maximo permitido)', NEW.id_vehiculo;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_imagen_vehiculo_max ON imagen_vehiculo;

CREATE TRIGGER trg_imagen_vehiculo_max
    BEFORE INSERT ON imagen_vehiculo
    FOR EACH ROW
    EXECUTE FUNCTION fn_check_max_imagenes();
