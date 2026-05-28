-- pa_enviar_mantenimiento_programado(...) -- Envia un vehiculo a
-- mantenimiento. El disparador fn_mantenimiento_envio (sobre la tabla
-- mantenimiento) propaga el estado 'en_mantenimiento' al vehiculo via
-- catalogo estado_vehiculo.
--
-- Diseno transaccional (R2): cuerpo envuelto en BEGIN ... EXCEPTION WHEN
-- ... THEN ... END, con parametros OUT estandarizados (p_estado, p_mensaje)
-- segun el contrato R4.
--
-- Precondicion: el vehiculo no debe estar 'alquilado' (un vehiculo en
-- poder del cliente no puede enviarse al taller). Cualquier otro estado
-- operativo del catalogo (disponible, fuera_de_servicio, en_traslado, ...)
-- admite el envio.

-- R11: declarada como FUNCTION (no PROCEDURE) para que PostgREST la
-- exponga via /rest/v1/rpc.
CREATE OR REPLACE FUNCTION pa_enviar_mantenimiento_programado(
    p_id_vehiculo   BIGINT,
    p_id_taller     BIGINT,
    p_observaciones TEXT,
    OUT p_estado    TEXT,
    OUT p_mensaje   TEXT
)
RETURNS RECORD
LANGUAGE plpgsql AS $$
DECLARE
    v_id_estado_alquilado BIGINT;
    v_id_estado_actual    BIGINT;
    v_nombre_estado       VARCHAR(50);
BEGIN
    p_estado  := 'ERROR';
    p_mensaje := NULL;

    SELECT id_estado INTO v_id_estado_alquilado
    FROM estado_vehiculo
    WHERE lower(nombre) = 'alquilado';

    -- FOR UPDATE bloquea la fila del vehiculo para evitar condicion de carrera
    -- con un alquiler que se cree en paralelo.
    SELECT id_estado INTO v_id_estado_actual
    FROM vehiculo
    WHERE id_vehiculo = p_id_vehiculo
    FOR UPDATE;

    IF NOT FOUND THEN
        p_estado  := 'ERROR_REFERENCIAL';
        p_mensaje := format('El vehiculo con ID %s no existe.', p_id_vehiculo);
        RETURN;
    END IF;

    IF v_id_estado_actual = v_id_estado_alquilado THEN
        p_estado  := 'ERROR_ESTADO';
        p_mensaje := format(
            'REGLA DE NEGOCIO: el vehiculo %s esta "alquilado" y no puede enviarse a mantenimiento hasta que se cierre el alquiler.',
            p_id_vehiculo
        );
        RETURN;
    END IF;

    -- Tambien rechazamos si el vehiculo ya esta en mantenimiento (orden
    -- abierta sin devolucion). El disparador fn_mantenimiento_envio consulta
    -- el catalogo, no la tabla mantenimiento, por lo que la doble asignacion
    -- se previene aca.
    SELECT lower(ev.nombre)
      INTO v_nombre_estado
      FROM estado_vehiculo ev
     WHERE ev.id_estado = v_id_estado_actual;

    IF v_nombre_estado = 'en_mantenimiento' THEN
        p_estado  := 'ERROR_ESTADO';
        p_mensaje := format(
            'REGLA DE NEGOCIO: el vehiculo %s ya esta en mantenimiento.',
            p_id_vehiculo
        );
        RETURN;
    END IF;

    -- Al insertar aqui, se activa automaticamente el disparador fn_mantenimiento_envio()
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
