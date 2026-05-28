-- Ciclo de vida del alquiler (R10).
--
-- Este archivo agrupa las tres funciones de disparador que sostienen la maquina
-- de estados del alquiler y del vehiculo asociado:
--
--   1) fn_alquiler_set_cerrado (BEFORE UPDATE): cuando fecha_devolucion
--      _real pasa de NULL a no-NULL, fuerza estado='cerrado' en la misma
--      fila. Va BEFORE para que el cambio quede en el row de NEW que ven
--      los disparadores AFTER, evitando un segundo UPDATE recursivo.
--   2) fn_alquiler_start (AFTER INSERT): mueve el vehiculo a 'alquilado',
--      cierra la fila vigente del historial de estados, abre una nueva, y
--      si el alquiler vino de una reserva, marca esa reserva como
--      'concretada'. Cumple parte del ciclo de vida (R10) y cierra el flujo
--      de R6 (alquiler con reserva).
--   3) fn_alquiler_close (AFTER UPDATE): cuando se completa la devolucion
--      (fecha_devolucion_real NULL -> no-NULL), mueve el vehiculo a
--      'disponible', actualiza km_actuales con km_fin, cierra la fila
--      vigente de ubicacion y abre una nueva en la sucursal de
--      devolucion. Es parte central de R10: disparadores que finalizan el
--      alquiler.
--
-- La factura no se emite aca: la emision la dispara el orquestador
-- pa_finalizar_alquiler invocando fn_calcular_factura antes del UPDATE de
-- fecha_devolucion_real, de modo que el cliente reciba el id_factura en
-- la respuesta.

-- fn_alquiler_set_cerrado (BEFORE UPDATE): pone estado='cerrado' cuando
-- fecha_devolucion_real pasa de NULL a no-NULL. Va BEFORE para que el
-- cambio se vea en los disparadores AFTER UPDATE, sin emitir un nuevo UPDATE
-- recursivo sobre alquiler.
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


-- fn_alquiler_start (AFTER INSERT): mueve la maquina de estados del vehiculo a
-- 'alquilado' y marca la reserva asociada como 'concretada' si la
-- hubiera.
CREATE OR REPLACE FUNCTION fn_alquiler_start()
RETURNS TRIGGER AS $$
DECLARE
    v_id_estado_alquilado BIGINT;
BEGIN
    -- Se compara con lower(nombre) para alinear con el CHECK del catalogo
    -- (estado_vehiculo.nombre = lower(nombre)). El catalogo queda forzado a
    -- minusculas, pero usar lower() en la consulta hace al codigo robusto si
    -- en el futuro entra una cadena distinta.
    SELECT id_estado INTO v_id_estado_alquilado
    FROM estado_vehiculo WHERE lower(nombre) = 'alquilado';

    IF v_id_estado_alquilado IS NULL THEN
        RAISE EXCEPTION 'Estado vehiculo "alquilado" no encontrado en catalogo';
    END IF;

    -- Cierra la fila vigente del historial (uq_historial_estado_vigente
    -- exige UNA sola fila con fecha_fin NULL por vehiculo).
    UPDATE historial_estado_vehiculo
    SET fecha_fin = NOW()
    WHERE id_vehiculo = NEW.id_vehiculo
      AND fecha_fin IS NULL;

    -- Inserta la nueva fila vigente con estado 'alquilado'.
    INSERT INTO historial_estado_vehiculo (id_vehiculo, id_estado, fecha_inicio, fecha_fin, motivo)
    VALUES (NEW.id_vehiculo, v_id_estado_alquilado, NOW(), NULL, 'Inicio de alquiler');

    -- Reflejo del estado vigente sobre el campo denormalizado de vehiculo.
    UPDATE vehiculo
    SET id_estado = v_id_estado_alquilado
    WHERE id_vehiculo = NEW.id_vehiculo;

    -- Si el alquiler proviene de una reserva, esa reserva queda 'concretada' (R6).
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


-- fn_alquiler_close (AFTER UPDATE): cuando fecha_devolucion_real pasa de
-- NULL a no-NULL, mueve la maquina de estados del vehiculo a 'disponible',
-- actualiza km_actuales con el kilometraje de devolucion y registra la nueva
-- ubicacion fisica (sucursal de devolucion).
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

    -- Cierra la fila vigente del historial de estados.
    UPDATE historial_estado_vehiculo
    SET fecha_fin = NOW()
    WHERE id_vehiculo = NEW.id_vehiculo
      AND fecha_fin IS NULL;

    -- Inserta la nueva fila vigente con estado 'disponible'.
    INSERT INTO historial_estado_vehiculo (id_vehiculo, id_estado, fecha_inicio, fecha_fin, motivo)
    VALUES (NEW.id_vehiculo, v_id_estado_disponible, NOW(), NULL, 'Devolucion de alquiler');

    -- Reflejo del estado y actualizacion del kilometraje real del vehiculo.
    UPDATE vehiculo
    SET id_estado   = v_id_estado_disponible,
        km_actuales = NEW.km_fin
    WHERE id_vehiculo = NEW.id_vehiculo;

    -- Cierra la fila de ubicacion fisica vigente (uq_ubicacion_vehiculo
    -- _vigente exige una sola fila con fecha_hasta NULL por vehiculo).
    UPDATE ubicacion_vehiculo
    SET fecha_hasta = NOW()
    WHERE id_vehiculo = NEW.id_vehiculo
      AND fecha_hasta IS NULL;

    -- Abre la nueva ubicacion vigente en la sucursal de devolucion. Cubre
    -- el caso de devolucion en una sucursal distinta a la de origen.
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
