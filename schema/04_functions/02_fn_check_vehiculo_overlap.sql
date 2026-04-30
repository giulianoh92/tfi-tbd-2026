-- Valida que no exista superposicion de fechas para un mismo vehiculo
-- entre reservas activas (pendiente, confirmada) y alquileres en curso.
-- Se aplica BEFORE INSERT/UPDATE en reserva y alquiler.
CREATE OR REPLACE FUNCTION fn_check_vehiculo_overlap()
RETURNS TRIGGER AS $$
DECLARE
    v_id_vehiculo  BIGINT     := NEW.id_vehiculo;
    v_inicio       TIMESTAMP  := NEW.fecha_inicio;
    v_fin          TIMESTAMP  := NEW.fecha_fin_prevista;
BEGIN
    -- Conflicto contra otras reservas activas del mismo vehiculo
    IF EXISTS (
        SELECT 1
        FROM reserva r
        WHERE r.id_vehiculo = v_id_vehiculo
          AND r.estado IN ('pendiente', 'confirmada')
          AND (TG_TABLE_NAME <> 'reserva' OR r.id_reserva <> NEW.id_reserva)
          AND r.fecha_inicio       <  v_fin
          AND r.fecha_fin_prevista >  v_inicio
    ) THEN
        RAISE EXCEPTION
            'El vehiculo % tiene una reserva activa que se superpone con el periodo solicitado',
            v_id_vehiculo;
    END IF;

    -- Conflicto contra alquileres en curso del mismo vehiculo
    IF EXISTS (
        SELECT 1
        FROM alquiler a
        WHERE a.id_vehiculo = v_id_vehiculo
          AND a.estado = 'en_curso'
          AND (TG_TABLE_NAME <> 'alquiler' OR a.id_alquiler <> NEW.id_alquiler)
          AND a.fecha_inicio                                          <  v_fin
          AND COALESCE(a.fecha_devolucion_real, a.fecha_fin_prevista) >  v_inicio
    ) THEN
        RAISE EXCEPTION
            'El vehiculo % tiene un alquiler en curso que se superpone con el periodo solicitado',
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
