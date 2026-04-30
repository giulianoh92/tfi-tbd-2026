-- Valida que no exista superposicion de fechas para un mismo vehiculo
-- entre reservas activas (pendiente, confirmada) y alquileres en curso.
-- Se aplica BEFORE INSERT/UPDATE en reserva y alquiler.
CREATE OR REPLACE FUNCTION fn_check_vehiculo_overlap()
RETURNS TRIGGER AS $$
DECLARE
    v_id_vehiculo  BIGINT     := NEW.id_vehiculo;
    v_inicio       TIMESTAMP  := NEW.fecha_inicio;
    v_fin          TIMESTAMP  := NEW.fecha_fin_prevista;
    -- Reserva a excluir del chequeo:
    --   * en INSERT/UPDATE de reserva: la propia reserva (auto-exclusion)
    --   * en INSERT/UPDATE de alquiler: la reserva vinculada (la que se esta concretando)
    -- Ambas tablas tienen la columna id_reserva, asi que la asignacion es valida.
    v_exclude_res  BIGINT     := NEW.id_reserva;
    -- Alquiler a excluir (solo aplica en INSERT/UPDATE de alquiler).
    -- Se asigna condicionalmente porque la tabla reserva no tiene id_alquiler
    -- y PL/pgSQL valida la referencia al planificar.
    v_exclude_alq  BIGINT;
BEGIN
    IF TG_TABLE_NAME = 'alquiler' THEN
        v_exclude_alq := NEW.id_alquiler;
    END IF;
    -- Conflicto contra otras reservas activas del mismo vehiculo
    IF EXISTS (
        SELECT 1
        FROM reserva r
        WHERE r.id_vehiculo = v_id_vehiculo
          AND r.estado IN ('pendiente', 'confirmada')
          AND r.id_reserva IS DISTINCT FROM v_exclude_res
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
          AND a.id_alquiler IS DISTINCT FROM v_exclude_alq
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
