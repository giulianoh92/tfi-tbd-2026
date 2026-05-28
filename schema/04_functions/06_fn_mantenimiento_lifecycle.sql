-- Ciclo de vida del mantenimiento.
--
-- Dos funciones de disparador que reflejan en la maquina de estados del vehiculo
-- los hitos del envio y la devolucion de un mantenimiento:
--
--   1) fn_mantenimiento_envio (AFTER INSERT): cuando se inserta una fila
--      en mantenimiento (apertura del servicio), mueve al vehiculo a
--      estado 'en_mantenimiento', cierra la fila vigente del historial y
--      abre una nueva.
--   2) fn_mantenimiento_devolucion (AFTER UPDATE): cuando se completa la
--      devolucion (fecha_devolucion NULL -> no-NULL), mueve al vehiculo
--      de vuelta a 'disponible' y rota nuevamente el historial.
--
-- En conjunto cubren parte del flujo R10 (el vehiculo se reintegra al
-- inventario operativo luego de un servicio) y mantienen consistente la
-- maquina de estados con el resto de los procesos.

-- fn_mantenimiento_envio (AFTER INSERT): mueve la maquina de estados del vehiculo a
-- 'en_mantenimiento' cuando se abre una orden de mantenimiento.
CREATE OR REPLACE FUNCTION fn_mantenimiento_envio()
RETURNS TRIGGER AS $$
DECLARE
    v_id_estado BIGINT;
BEGIN
    -- El catalogo estado_vehiculo registra "en_mantenimiento" (no
    -- "mantenimiento"). Consulta sin distincion de mayusculas contra el catalogo:
    -- el CHECK del catalogo ya fuerza minusculas; usar lower() aqui hace al
    -- codigo robusto ante posibles variaciones futuras.
    SELECT id_estado INTO v_id_estado
    FROM estado_vehiculo WHERE lower(nombre) = 'en_mantenimiento';

    IF v_id_estado IS NULL THEN
        RAISE EXCEPTION 'Estado vehiculo "en_mantenimiento" no encontrado en catalogo';
    END IF;

    -- Cierra la fila vigente del historial de estados del vehiculo.
    UPDATE historial_estado_vehiculo
    SET fecha_fin = NOW()
    WHERE id_vehiculo = NEW.id_vehiculo
      AND fecha_fin IS NULL;

    -- Inserta la nueva fila vigente: el vehiculo entra a mantenimiento.
    INSERT INTO historial_estado_vehiculo (id_vehiculo, id_estado, fecha_inicio, fecha_fin, motivo)
    VALUES (NEW.id_vehiculo, v_id_estado, NOW(), NULL, 'Envio a mantenimiento');

    -- Reflejo del estado vigente sobre el campo denormalizado de vehiculo.
    UPDATE vehiculo
    SET id_estado = v_id_estado
    WHERE id_vehiculo = NEW.id_vehiculo;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_mantenimiento_envio ON mantenimiento;

CREATE TRIGGER trg_mantenimiento_envio
    AFTER INSERT ON mantenimiento
    FOR EACH ROW
    EXECUTE FUNCTION fn_mantenimiento_envio();


-- fn_mantenimiento_devolucion (AFTER UPDATE): cuando fecha_devolucion
-- pasa de NULL a no-NULL, mueve la maquina de estados del vehiculo de vuelta a
-- 'disponible' y rota la fila vigente del historial.
CREATE OR REPLACE FUNCTION fn_mantenimiento_devolucion()
RETURNS TRIGGER AS $$
DECLARE
    v_id_estado BIGINT;
BEGIN
    SELECT id_estado INTO v_id_estado
    FROM estado_vehiculo WHERE lower(nombre) = 'disponible';

    IF v_id_estado IS NULL THEN
        RAISE EXCEPTION 'Estado vehiculo "disponible" no encontrado en catalogo';
    END IF;

    -- Cierra la fila vigente del historial de estados.
    UPDATE historial_estado_vehiculo
    SET fecha_fin = NOW()
    WHERE id_vehiculo = NEW.id_vehiculo
      AND fecha_fin IS NULL;

    -- Inserta la nueva fila vigente: vehiculo nuevamente 'disponible'.
    INSERT INTO historial_estado_vehiculo (id_vehiculo, id_estado, fecha_inicio, fecha_fin, motivo)
    VALUES (NEW.id_vehiculo, v_id_estado, NOW(), NULL, 'Devolucion de mantenimiento');

    -- Reflejo del estado vigente sobre el campo denormalizado de vehiculo.
    UPDATE vehiculo
    SET id_estado = v_id_estado
    WHERE id_vehiculo = NEW.id_vehiculo;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_mantenimiento_devolucion ON mantenimiento;

CREATE TRIGGER trg_mantenimiento_devolucion
    AFTER UPDATE ON mantenimiento
    FOR EACH ROW
    WHEN (OLD.fecha_devolucion IS NULL AND NEW.fecha_devolucion IS NOT NULL)
    EXECUTE FUNCTION fn_mantenimiento_devolucion();
