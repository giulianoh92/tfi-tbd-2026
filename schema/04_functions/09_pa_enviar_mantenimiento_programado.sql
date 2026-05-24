-- pa_enviar_mantenimiento_programado(...) — Envia un vehiculo disponible a
-- mantenimiento. El trigger fn_mantenimiento_envio (sobre la tabla
-- mantenimiento) propaga el estado 'en_mantenimiento' al vehiculo via
-- catalogo estado_vehiculo.
--
-- Sprint 5 (R2) — refactor:
--   * Cuerpo envuelto en BEGIN ... EXCEPTION WHEN ... THEN ... END.
--   * Agregados OUT p_estado / p_mensaje (contrato estandar JUSTIFICACION.md
--     §R4).
--
-- Cambio de firma -> DROP PROCEDURE previo con la firma vieja explicita.

DROP PROCEDURE IF EXISTS pa_enviar_mantenimiento_programado(
    BIGINT, BIGINT, TEXT
) CASCADE;

CREATE OR REPLACE PROCEDURE pa_enviar_mantenimiento_programado(
    IN  p_id_vehiculo   BIGINT,
    IN  p_id_taller     BIGINT,
    IN  p_observaciones TEXT,
    OUT p_estado        TEXT,
    OUT p_mensaje       TEXT
)
LANGUAGE plpgsql AS $$
DECLARE
    v_id_estado_disponible BIGINT;
    v_id_estado_actual     BIGINT;
BEGIN
    p_estado  := 'ERROR';
    p_mensaje := NULL;

    SELECT id_estado INTO v_id_estado_disponible
    FROM estado_vehiculo
    WHERE lower(nombre) = 'disponible';

    -- FOR UPDATE bloquea la fila del vehiculo para evitar carrera con un
    -- alquiler que se cree en paralelo.
    SELECT id_estado INTO v_id_estado_actual
    FROM vehiculo
    WHERE id_vehiculo = p_id_vehiculo
    FOR UPDATE;

    IF NOT FOUND THEN
        p_estado  := 'ERROR_REFERENCIAL';
        p_mensaje := format('El vehiculo con ID %s no existe.', p_id_vehiculo);
        RETURN;
    END IF;

    IF v_id_estado_actual IS DISTINCT FROM v_id_estado_disponible THEN
        p_estado  := 'ERROR_ESTADO';
        p_mensaje := format(
            'REGLA DE NEGOCIO: El vehiculo %s no esta "disponible" para mantenimiento.',
            p_id_vehiculo
        );
        RETURN;
    END IF;

    -- Al insertar aqui, se dispara automaticamente fn_mantenimiento_envio()
    INSERT INTO mantenimiento (id_vehiculo, id_taller, fecha_envio, fecha_devolucion, observaciones)
    VALUES (p_id_vehiculo, p_id_taller, CURRENT_DATE, NULL, p_observaciones);

    p_estado  := 'OK';
    p_mensaje := format('Vehiculo %s enviado a mantenimiento en taller %s.', p_id_vehiculo, p_id_taller);

EXCEPTION
    WHEN unique_violation THEN
        p_estado  := 'ERROR_DUPLICADO';
        p_mensaje := SQLERRM;
    WHEN foreign_key_violation THEN
        p_estado  := 'ERROR_REFERENCIAL';
        p_mensaje := SQLERRM;
    WHEN check_violation THEN
        p_estado  := 'ERROR_VALIDACION';
        p_mensaje := SQLERRM;
    WHEN OTHERS THEN
        p_estado  := 'ERROR';
        p_mensaje := SQLERRM;
END;
$$;
