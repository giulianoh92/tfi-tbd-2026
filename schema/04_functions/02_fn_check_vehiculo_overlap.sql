-- Valida que no exista superposicion de fechas para un mismo vehiculo
-- entre reservas activas (pendiente, concretada) y alquileres activos.
-- Se aplica BEFORE INSERT/UPDATE en reserva y alquiler.
CREATE OR REPLACE FUNCTION fn_check_vehiculo_overlap()
RETURNS TRIGGER AS $$
DECLARE
    v_id_vehiculo  BIGINT    := NEW.id_vehiculo;
    v_inicio       TIMESTAMP := NEW.fecha_inicio;
    v_fin          TIMESTAMP := NEW.fecha_fin_prevista;
    v_exclude_res  BIGINT;
    v_exclude_alq  BIGINT;
BEGIN
    IF TG_TABLE_NAME = 'reserva' THEN
        v_exclude_res := NEW.id_reserva;
        v_exclude_alq := -1;
    ELSE
        -- alquiler: excluir la reserva vinculada (la que se esta concretando) y el propio alquiler
        v_exclude_res := COALESCE(NEW.id_reserva, -1);
        v_exclude_alq := NEW.id_alquiler;
    END IF;

    -- Conflicto contra otras reservas activas del mismo vehiculo
    IF EXISTS (
        SELECT 1
        FROM reserva r
        WHERE r.id_vehiculo = v_id_vehiculo
          AND r.estado IN ('pendiente', 'concretada')
          AND r.id_reserva <> v_exclude_res
          AND r.fecha_inicio       < v_fin
          AND r.fecha_fin_prevista > v_inicio
    ) THEN
        RAISE EXCEPTION
            'El vehiculo % tiene una reserva activa que se superpone con el periodo solicitado',
            v_id_vehiculo;
    END IF;

    -- Conflicto contra alquileres activos del mismo vehiculo.
    -- Excluye el alquiler que referencia la misma reserva (al concretar una reserva
    -- desde fn_alquiler_start, el alquiler ya existe en estado activo para el mismo periodo).
    IF EXISTS (
        SELECT 1
        FROM alquiler a
        WHERE a.id_vehiculo = v_id_vehiculo
          AND a.estado = 'activo'
          AND a.id_alquiler <> v_exclude_alq
          AND (NEW.id_reserva IS NULL OR a.id_reserva IS DISTINCT FROM NEW.id_reserva)
          AND a.fecha_inicio                                          < v_fin
          AND COALESCE(a.fecha_devolucion_real, a.fecha_fin_prevista) > v_inicio
    ) THEN
        RAISE EXCEPTION
            'El vehiculo % tiene un alquiler activo que se superpone con el periodo solicitado',
            v_id_vehiculo;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

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
