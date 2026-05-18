CREATE OR REPLACE PROCEDURE pa_enviar_mantenimiento_programado(
    p_id_vehiculo BIGINT,
    p_id_taller BIGINT,
    p_observaciones TEXT
)
LANGUAGE plpgsql AS $$
DECLARE
    v_id_estado_disponible BIGINT;
    v_id_estado_actual BIGINT;
BEGIN
    SELECT id_estado INTO v_id_estado_disponible FROM estado_vehiculo WHERE lower(nombre) = 'disponible';

    SELECT id_estado INTO v_id_estado_actual FROM vehiculo WHERE id_vehiculo = p_id_vehiculo FOR UPDATE;
    --El FOR UPDATE bloquea el auto para que nadie lo alquile en el milisegundo en que lo estás mandando al taller.
    
    IF v_id_estado_actual IS DISTINCT FROM v_id_estado_disponible THEN
        RAISE EXCEPTION 'REGLA DE NEGOCIO: El vehiculo % no esta "disponible" para mantenimiento.', p_id_vehiculo;
    END IF;

    -- Al insertar aquí, se dispara automáticamente fn_mantenimiento_envio()
    INSERT INTO mantenimiento (id_vehiculo, id_taller, fecha_envio, fecha_devolucion, observaciones)
    VALUES (p_id_vehiculo, p_id_taller, CURRENT_DATE, NULL, p_observaciones);
END;
$$;