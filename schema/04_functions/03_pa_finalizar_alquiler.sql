CREATE OR REPLACE PROCEDURE pa_finalizar_alquiler(
    p_id_alquiler INT,
    p_km_fin INT,
    p_id_sucursal_devolucion INT,
    p_estado_final_vehiculo VARCHAR(20), -- 'disponible' o 'mantenimiento'
    p_id_taller BIGINT DEFAULT NULL,     -- Parámetro opcional para tu tabla 'mantenimiento'
    p_observaciones TEXT DEFAULT NULL    -- Observaciones sobre el estado del vehículo
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_id_vehiculo INT;
    v_km_inicio INT;
    v_id_factura_generada INT;
    v_estado_limpio VARCHAR(20);
    v_motivo_historial VARCHAR(255);
BEGIN
    -- Pasar a minúsculas para asegurar coincidencia estricta con las reglas de negocio
    v_estado_limpio := lower(p_estado_final_vehiculo);

    -- =========================================================================
    -- 1. VALIDACIONES PREVIAS (PRECONDICIONES DE NEGOCIO)
    -- =========================================================================
    
    -- Verifica que el alquiler exista y esté activo
    SELECT id_vehiculo, km_inicio INTO v_id_vehiculo, v_km_inicio
    FROM alquiler
    WHERE id_alquiler = p_id_alquiler AND estado = 'activo';
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'CONTROL DE INTEGRIDAD: El alquiler % no existe o ya fue cerrado previamente.', p_id_alquiler;
    END IF;

    -- Valida consistencia del kilometraje ingresado
    IF p_km_fin < v_km_inicio THEN
        RAISE EXCEPTION 'ERROR OPERATIVO: Los kilómetros finales (%) no pueden ser menores a los iniciales (%).', p_km_fin, v_km_inicio;
    END IF;

    -- Valida el texto del estado de destino directamente (sin tabla de catálogo)
    IF v_estado_limpio NOT IN ('disponible', 'mantenimiento') THEN
        RAISE EXCEPTION 'ERROR DE NEGOCIO: El estado "%" no es un estado válido de finalización (use disponible/mantenimiento).', p_estado_final_vehiculo;
    END IF;

    -- Si se define mantenimiento, exigir obligatoriamente que se indique a qué taller va
    IF v_estado_limpio = 'mantenimiento' AND p_id_taller IS NULL THEN
        RAISE EXCEPTION 'ERROR DE FLUJO: Si el vehículo queda en estado mantenimiento, debe especificar un id_taller válido.';
    END IF;

    -- Definir la descripción o motivo que se compartirá en el historial y el mantenimiento
    IF v_estado_limpio = 'mantenimiento' THEN
        v_motivo_historial := COALESCE(p_observaciones, 'Enviado a taller por imperfecciones detectadas al finalizar Alquiler #' || p_id_alquiler);
    ELSE
        v_motivo_historial := 'Cierre Alquiler #' || p_id_alquiler || ' - Destino Sucursal ID: ' || p_id_sucursal_devolucion;
    END IF;


    -- =========================================================================
    -- 2. EJECUCIÓN DE LA TRANSACCIÓN UNIFICADA (ATOMICIDAD)
    -- =========================================================================
    
    -- A. Actualiza la cabecera del Alquiler (Cierre de contrato)
    UPDATE alquiler 
    SET fecha_devolucion_real = NOW(),
        km_fin = p_km_fin,
        id_sucursal_devolucion = p_id_sucursal_devolucion,
        estado = 'cerrado'
    WHERE id_alquiler = p_id_alquiler;

    -- B. Actualiza datos operativos del Vehículo (Kilometraje y Estado como VARCHAR)
    UPDATE vehiculo 
    SET estado = v_estado_limpio,
        km_actuales = p_km_fin
    WHERE id_vehiculo = v_id_vehiculo;

    -- C. Actualiza Disponibilidad Geográfica (Cerrar tramo actual y abrir nuevo origen)
    UPDATE ubicacion_vehiculo
    SET fecha_hasta = NOW()
    WHERE id_vehiculo = v_id_vehiculo AND fecha_hasta IS NULL;

    INSERT INTO ubicacion_vehiculo (id_vehiculo, id_sucursal, fecha_desde, fecha_hasta)
    VALUES (v_id_vehiculo, p_id_sucursal_devolucion, NOW(), NULL);

    -- D. Historial de Auditoría Interna del Vehículo (Guardando estado como VARCHAR)
    UPDATE historial_estado_vehiculo
    SET fecha_fin = NOW()
    WHERE id_vehiculo = v_id_vehiculo AND fecha_fin IS NULL;

    INSERT INTO historial_estado_vehiculo (id_vehiculo, estado, fecha_inicio, fecha_fin, motivo)
    VALUES (
        v_id_vehiculo, 
        v_estado_limpio, 
        NOW(), 
        NULL, 
        v_motivo_historial
    );

    -- E. CONTROL DE TALLER: Integración automática con tu tabla 'mantenimiento'
    IF v_estado_limpio = 'mantenimiento' THEN
        INSERT INTO mantenimiento (id_vehiculo, id_taller, fecha_envio, fecha_devolucion, observaciones)
        VALUES (v_id_vehiculo, p_id_taller, NOW(), NULL, v_motivo_historial);
        
        RAISE NOTICE 'ALERTA DE FLOTA: Registro automático creado en la tabla de mantenimiento para el vehículo %.', v_id_vehiculo;
    END IF;

    -- F. Invoca a función de calcular factura
    v_id_factura_generada := fn_calcular_factura(p_id_alquiler);


    -- Notificación de éxito 
    RAISE NOTICE 'TRANSACCIÓN EXITOSA: Alquiler % cerrado. Vehículo % actualizado a estado "%". Factura % emitida.', 
                 p_id_alquiler, v_id_vehiculo, v_estado_limpio, v_id_factura_generada;

EXCEPTION
    WHEN OTHERS THEN
        -- Si cualquier query o cálculo falla, PostgreSQL intercepta el error aquí
        -- y revierte automáticamente (ROLLBACK) todo lo ejecutado en este bloque.
        RAISE EXCEPTION 'CRITICAL EXCEPTION: El proceso falló y la transacción fue abortada de forma segura. Detalles: %', SQLERRM;
END;
$$;