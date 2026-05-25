-- fn_check_vehiculo_overlap — Trigger BEFORE INSERT/UPDATE en reserva y
-- alquiler. Valida superposicion de fechas para un mismo vehiculo.
--
-- IMPORTANTE: este trigger NO es la garantia de unicidad
-- temporal. La garantia DURA la da la EXCLUDE constraint excl_alquiler_overlap
-- / excl_reserva_overlap (schema/02_constraints/14_exclude_alquiler_reserva.sql),
-- que opera a nivel indice GiST y cierra la ventana de carrera entre
-- transacciones concurrentes que el trigger best-effort no podia cerrar.
--
-- Razon de mantener este trigger:
--   1) Mensajes mas amigables en el camino feliz (un solo cliente, sin
--      concurrencia): el RAISE EXCEPTION devuelve texto humano antes que
--      el codigo 23P01 generico del exclude.
--   2) Validacion en UPDATE: la EXCLUDE solo dispara cuando se inserta o
--      modifica una fila cuyo tsrange entra en conflicto, pero el trigger
--      tambien revisa transiciones que la EXCLUDE pasaria por alto (ej:
--      actualizar fechas de una reserva 'concretada' que ya queda
--      excluida por el WHERE de la constraint).
--   3) Permite excluir el alquiler que proviene de la misma reserva
--      siendo concretada (caso especial que la EXCLUDE simple no expresa
--      sin escribir un WHERE muy complejo).
--
-- Es decir: la EXCLUDE es la garantia formal; este trigger es UX. Si en
-- el futuro se decide eliminarlo, la unicidad queda igual.
-- Se usa IS DISTINCT FROM (no COALESCE con -1) para tratar NULL como
-- valor sin sentinels que podrian colisionar con IDs reales.
CREATE OR REPLACE FUNCTION fn_check_vehiculo_overlap()
RETURNS TRIGGER AS $$
DECLARE
    v_id_vehiculo  BIGINT    := NEW.id_vehiculo;
    v_inicio       TIMESTAMP := NEW.fecha_inicio;
    v_fin          TIMESTAMP := NEW.fecha_fin_prevista;
    v_self_res     BIGINT;
    v_self_alq     BIGINT;
BEGIN
    -- Se usa NULL + IS DISTINCT FROM para excluir "la propia fila" (id NULL
    -- en INSERT, id real en UPDATE). NULL <> 5 = NULL (truthy false), pero
    -- NULL IS DISTINCT FROM 5 = TRUE. Es la forma idiomatica en Postgres
    -- sin riesgo de colisionar con un sentinel (ej: -1) que podria ser un
    -- id real en otro contexto.
    IF TG_TABLE_NAME = 'reserva' THEN
        v_self_res := NEW.id_reserva;     -- NULL en INSERT, id real en UPDATE
        v_self_alq := NULL;
    ELSE
        -- alquiler: NEW.id_reserva apunta a la reserva siendo concretada (si
        -- venimos del flujo "con reserva previa"); NEW.id_alquiler es NULL en
        -- INSERT o el id en UPDATE.
        v_self_res := NEW.id_reserva;
        v_self_alq := NEW.id_alquiler;
    END IF;

    -- CONTROL DE SUPERPOSICION CONTRA RESERVAS ACTIVAS.
    -- Conflicto contra otras reservas activas del mismo vehiculo.
    IF EXISTS (
        SELECT 1
        FROM reserva r
        WHERE r.id_vehiculo = v_id_vehiculo
          AND r.estado IN ('pendiente', 'concretada')
          AND r.id_reserva IS DISTINCT FROM v_self_res
          AND r.fecha_inicio       < v_fin
          AND r.fecha_fin_prevista > v_inicio
    ) THEN
        RAISE EXCEPTION
            'El vehiculo % tiene una reserva activa que se superpone con el periodo solicitado',
            v_id_vehiculo;
    END IF;

    -- CONTROL DE SUPERPOSICION CONTRA ALQUILERES ACTIVOS.
    -- Excluye el alquiler que referencia la misma reserva (al concretar una
    -- reserva desde fn_alquiler_start, el alquiler ya existe en estado
    -- activo para el mismo periodo).
    IF EXISTS (
        SELECT 1
        FROM alquiler a
        WHERE a.id_vehiculo = v_id_vehiculo
          AND a.estado = 'activo'
          AND a.id_alquiler IS DISTINCT FROM v_self_alq
          -- Excluye el alquiler que proviene de la misma reserva que se
          -- esta concretando (caso fn_alquiler_start).
          AND (NEW.id_reserva IS NULL OR a.id_reserva IS DISTINCT FROM NEW.id_reserva)
          AND a.fecha_inicio                                                            < v_fin
          AND GREATEST(a.fecha_fin_prevista, COALESCE(a.fecha_devolucion_real, NOW())) > v_inicio
    ) THEN
        RAISE EXCEPTION
            'El vehiculo % tiene un alquiler activo que se superpone con el periodo solicitado',
            v_id_vehiculo;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- CREACIÓN DE DISPARADORES ASOCIADOS
DROP TRIGGER IF EXISTS trg_reserva_no_overlap  ON reserva;
DROP TRIGGER IF EXISTS trg_alquiler_no_overlap ON alquiler;

CREATE TRIGGER trg_reserva_no_overlap
    BEFORE INSERT OR UPDATE ON reserva
    FOR EACH ROW
    EXECUTE FUNCTION fn_check_vehiculo_overlap();

CREATE TRIGGER trg_alquiler_no_overlap
    BEFORE INSERT OR UPDATE ON alquiler
    FOR EACH ROW
    EXECUTE FUNCTION fn_check_vehiculo_overlap();
