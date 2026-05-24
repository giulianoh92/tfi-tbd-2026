-- BEFORE UPDATE: set estado='cerrado' when fecha_devolucion_real transitions from NULL to non-NULL.
-- This runs before AFTER UPDATE triggers to avoid a recursive UPDATE on alquiler.
CREATE OR REPLACE FUNCTION fn_alquiler_set_cerrado()
RETURNS TRIGGER AS $$
BEGIN
    NEW.estado := 'cerrado';
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_alquiler_set_cerrado ON alquiler;

CREATE TRIGGER trg_alquiler_set_cerrado
    BEFORE UPDATE ON alquiler
    FOR EACH ROW
    WHEN (OLD.fecha_devolucion_real IS NULL AND NEW.fecha_devolucion_real IS NOT NULL)
    EXECUTE FUNCTION fn_alquiler_set_cerrado();


-- AFTER INSERT: move vehicle FSM to 'alquilado', mark reserva as 'concretada'.
CREATE OR REPLACE FUNCTION fn_alquiler_start()
RETURNS TRIGGER AS $$
DECLARE
    v_id_estado_alquilado BIGINT;
BEGIN
    -- Sprint 6 (B5.3): se compara con lower(nombre) para alinear con el
    -- CHECK del catalogo (estado_vehiculo.nombre = lower(nombre)). El
    -- catalogo queda forzado a minusculas, pero usar lower() en el lookup
    -- hace al codigo robusto si en el futuro entra una cadena distinta.
    SELECT id_estado INTO v_id_estado_alquilado
    FROM estado_vehiculo WHERE lower(nombre) = 'alquilado';

    IF v_id_estado_alquilado IS NULL THEN
        RAISE EXCEPTION 'Estado vehiculo "alquilado" no encontrado en catalogo';
    END IF;

    -- Close current open historial row for this vehicle
    UPDATE historial_estado_vehiculo
    SET fecha_fin = NOW()
    WHERE id_vehiculo = NEW.id_vehiculo
      AND fecha_fin IS NULL;

    -- Insert new historial row for 'alquilado'
    INSERT INTO historial_estado_vehiculo (id_vehiculo, id_estado, fecha_inicio, fecha_fin, motivo)
    VALUES (NEW.id_vehiculo, v_id_estado_alquilado, NOW(), NULL, 'Inicio de alquiler');

    -- Mirror current state on vehiculo
    UPDATE vehiculo
    SET id_estado = v_id_estado_alquilado
    WHERE id_vehiculo = NEW.id_vehiculo;

    -- Mark associated reserva as 'concretada'
    IF NEW.id_reserva IS NOT NULL THEN
        UPDATE reserva
        SET estado = 'concretada'
        WHERE id_reserva = NEW.id_reserva;
    END IF;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_alquiler_start ON alquiler;

CREATE TRIGGER trg_alquiler_start
    AFTER INSERT ON alquiler
    FOR EACH ROW
    EXECUTE FUNCTION fn_alquiler_start();


-- AFTER UPDATE: when fecha_devolucion_real transitions NULL -> non-NULL,
-- move vehicle FSM to 'disponible', update km, update ubicacion.
CREATE OR REPLACE FUNCTION fn_alquiler_close()
RETURNS TRIGGER AS $$
DECLARE
    v_id_estado_disponible BIGINT;
BEGIN
    IF NEW.id_sucursal_devolucion IS NULL THEN
        RAISE EXCEPTION 'id_sucursal_devolucion es obligatorio para cerrar el alquiler %', NEW.id_alquiler;
    END IF;

    SELECT id_estado INTO v_id_estado_disponible
    FROM estado_vehiculo WHERE lower(nombre) = 'disponible';

    IF v_id_estado_disponible IS NULL THEN
        RAISE EXCEPTION 'Estado vehiculo "disponible" no encontrado en catalogo';
    END IF;

    -- Close current open historial row
    UPDATE historial_estado_vehiculo
    SET fecha_fin = NOW()
    WHERE id_vehiculo = NEW.id_vehiculo
      AND fecha_fin IS NULL;

    -- Insert new historial row for 'disponible'
    INSERT INTO historial_estado_vehiculo (id_vehiculo, id_estado, fecha_inicio, fecha_fin, motivo)
    VALUES (NEW.id_vehiculo, v_id_estado_disponible, NOW(), NULL, 'Devolucion de alquiler');

    -- Mirror current state on vehiculo and update km
    UPDATE vehiculo
    SET id_estado   = v_id_estado_disponible,
        km_actuales = NEW.km_fin
    WHERE id_vehiculo = NEW.id_vehiculo;

    -- Close current open ubicacion row
    UPDATE ubicacion_vehiculo
    SET fecha_hasta = NOW()
    WHERE id_vehiculo = NEW.id_vehiculo
      AND fecha_hasta IS NULL;

    -- Insert new ubicacion row at devolucion sucursal
    IF NEW.id_sucursal_devolucion IS NOT NULL THEN
        INSERT INTO ubicacion_vehiculo (id_vehiculo, id_sucursal, fecha_desde, fecha_hasta)
        VALUES (NEW.id_vehiculo, NEW.id_sucursal_devolucion, NOW(), NULL);
    END IF;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_alquiler_close ON alquiler;

CREATE TRIGGER trg_alquiler_close
    AFTER UPDATE ON alquiler
    FOR EACH ROW
    WHEN (OLD.fecha_devolucion_real IS NULL AND NEW.fecha_devolucion_real IS NOT NULL)
    EXECUTE FUNCTION fn_alquiler_close();
