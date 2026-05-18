CREATE OR REPLACE PROCEDURE pa_registrar_devolucion_mantenimiento(
    p_id_vehiculo BIGINT,
    p_km_salida_taller INTEGER DEFAULT NULL -- Parámetro opcional por si variaron los kms en el taller
)
LANGUAGE plpgsql AS $$
DECLARE
    v_id_estado_mantenimiento BIGINT;
    v_id_estado_actual BIGINT;
    v_id_mantenimiento_abierto BIGINT;
BEGIN

    -- 1. OBTENER ID DEL ESTADO MANTENIMIENTO DESDE EL CATÁLOGO
    SELECT id_estado INTO v_id_estado_mantenimiento 
    FROM estado_vehiculo 
    WHERE lower(nombre) = 'mantenimiento';


    -- 2. CONTROL DE PRECONDICIONES (VALIDACIÓN DE FLOTA Y ORDEN)
    -- Bloqueamos la fila del vehículo para la transacción
    SELECT id_estado INTO v_id_estado_actual
    FROM vehiculo
    WHERE id_vehiculo = p_id_vehiculo
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'CONTROL DE INTEGRIDAD: El vehículo con ID % no existe.', p_id_vehiculo;
    END IF;

    -- Validar que el vehículo esté operativamente en mantenimiento
    IF v_id_estado_actual IS DISTINCT FROM v_id_estado_mantenimiento THEN
        RAISE EXCEPTION 'REGLA DE NEGOCIO: El vehículo no puede registrar devolución porque su estado actual no es "mantenimiento".';
    END IF;

    -- Verificar que exista una orden abierta en la tabla mantenimiento para este vehículo
    SELECT id_mantenimiento INTO v_id_mantenimiento_abierto
    FROM mantenimiento
    WHERE id_vehiculo = p_id_vehiculo 
      AND fecha_devolucion IS NULL;

    IF v_id_mantenimiento_abierto IS NULL THEN
        RAISE EXCEPTION 'ERROR OPERATIVO: No se encontró ninguna orden de trabajo abierta en la tabla mantenimiento para el vehículo ID %.', p_id_vehiculo;
    END IF;

    -- 3. ACTUALIZACIÓN OPERATIVA (CIERRE DE ORDEN Y KILOMETRAJE)
    -- Si se enviaron los kilómetros de salida de taller, actualizamos la tabla vehículo
    IF p_km_salida_taller IS NOT NULL THEN
        -- Validación de consistencia de kilómetros
        IF p_km_salida_taller < (SELECT km_actuales FROM vehiculo WHERE id_vehiculo = p_id_vehiculo) THEN
            RAISE EXCEPTION 'ERROR OPERATIVO: Los kilómetros informados al salir del taller (%) no pueden ser menores a los actuales.', p_km_salida_taller;
        END IF;

        UPDATE vehiculo
        SET km_actuales = p_km_salida_taller
        WHERE id_vehiculo = p_id_vehiculo;
    END IF;

    -- Cerramos la orden de mantenimiento asignando la fecha de hoy
    -- NOTA: Esto dispara de forma automática el trigger trg_mantenimiento_devolucion
    UPDATE mantenimiento
    SET fecha_devolucion = CURRENT_DATE
    WHERE id_mantenimiento = v_id_mantenimiento_abierto;

    RAISE NOTICE 'PROCESO EXITOSO: Se registró el retorno del vehículo %. La base de datos activa lo ha restablecido a estado "disponible".', p_id_vehiculo;
END;
$$;