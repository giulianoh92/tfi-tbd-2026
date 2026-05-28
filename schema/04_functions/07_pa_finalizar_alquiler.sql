-- pa_finalizar_alquiler(...) -- Orquestador transaccional del CU-06 (R10).
--
-- Cierra un alquiler activo, activa los disparadores del ciclo de vida del vehiculo
-- (ubicacion + historial + estado en el catalogo), emite la factura y opcionalmente
-- envia el vehiculo a mantenimiento.
--
-- Diseno transaccional (R2):
--   * El cuerpo va envuelto en BEGIN ... EXCEPTION WHEN ... THEN ... END para
--     cumplir el manejo de excepciones (confirmar/revertir transaccion). En
--     Postgres el BEGIN del procedure asocia un savepoint implicito: si una
--     excepcion se captura, se revierte al savepoint; si el bloque
--     termina sin excepcion, la transaccion del caller se confirma
--     normalmente.
--   * Los parametros OUT estandarizados (p_estado, p_mensaje, p_id_factura)
--     permiten a la aplicacion cliente mostrar mensajes legibles en lugar de
--     un error 500. Mismo contrato que pa_registrar_reserva / etc.
--
-- Aporte original: Marcia Viera (commit 257d86f del 2026-05-16,
-- "funcionalidad finalizar alquiler"). Adaptaciones al esquema reescrito:
--   * Se eliminaron UPDATE directos de vehiculo.estado / historial_estado_vehiculo.estado
--     (columnas inexistentes en el nuevo modelo): el disparador fn_alquiler_close
--     ya cierra historial, abre ubicacion en la sucursal de devolucion y
--     refleja id_estado en vehiculo desde el catalogo estado_vehiculo.
--   * Si el destino es mantenimiento, basta con INSERT en mantenimiento: el
--     disparador fn_mantenimiento_envio propaga el estado 'en_mantenimiento' al
--     vehiculo via catalogo. La secuencia produce dos transiciones en historial
--     (alquilado -> disponible -> en_mantenimiento), correctas para auditoria.
--   * Valida el estado destino contra el catalogo (no como cadena fija).
--
-- Los 3 ultimos parametros IN van con DEFAULT NULL para que el caso mas
-- frecuente (cierre con destino "disponible", flujo normal sin envio a
-- taller) pueda invocar la funcion solo con los 3 argumentos obligatorios via
-- PostgREST RPC.
--
-- Regla de Postgres: los parametros IN con DEFAULT deben ir AL FINAL de la
-- lista de IN; los OUT son separados y pueden ir despues. Esta firma es valida.
--
-- Llamadas validas desde PostgREST:
--   * { p_id_alquiler, p_km_fin, p_id_sucursal_devolucion }
--       -> destino "disponible" (por defecto), sin mantenimiento
--   * Mismos 3 + { p_estado_destino_vehiculo:'en_mantenimiento', p_id_taller, p_observaciones }
--       -> destino mantenimiento al cierre
--
-- R11: declarada como FUNCTION (no PROCEDURE) para que PostgREST la
-- exponga via /rest/v1/rpc.
CREATE OR REPLACE FUNCTION pa_finalizar_alquiler(
    p_id_alquiler              BIGINT,
    p_km_fin                   INTEGER,
    p_id_sucursal_devolucion   BIGINT,
    p_estado_destino_vehiculo  VARCHAR DEFAULT NULL,
    p_id_taller                BIGINT  DEFAULT NULL,
    p_observaciones            TEXT    DEFAULT NULL,
    OUT p_estado               TEXT,
    OUT p_mensaje              TEXT,
    OUT p_id_factura           BIGINT
)
RETURNS RECORD
LANGUAGE plpgsql
AS $$
DECLARE
    v_id_vehiculo      BIGINT;
    v_km_inicio        INTEGER;
    v_estado_limpio    VARCHAR(50);
    v_motivo_mantto    VARCHAR(255);
    v_estado_existe    BOOLEAN;
BEGIN
    -- Inicializacion preventiva por si alguna rama no asigna explicitamente.
    p_estado     := 'ERROR';
    p_mensaje    := NULL;
    p_id_factura := NULL;

    -- Si quien invoca no especifica estado destino, se asume 'disponible' (por
     -- defecto de negocio). Antes era un DEFAULT del IN; se movio aca para
     -- respetar la regla de Postgres "no DEFAULT antes de OUT".
    v_estado_limpio := lower(COALESCE(p_estado_destino_vehiculo, 'disponible'));

    -- 1. Precondiciones
    SELECT id_vehiculo, km_inicio INTO v_id_vehiculo, v_km_inicio
    FROM alquiler
    WHERE id_alquiler = p_id_alquiler AND estado = 'activo';

    IF NOT FOUND THEN
        p_estado  := 'ERROR_ESTADO';
        p_mensaje := format('pa_finalizar_alquiler: alquiler %s no existe o ya esta cerrado', p_id_alquiler);
        RETURN;
    END IF;

    IF p_km_fin < v_km_inicio THEN
        p_estado  := 'ERROR_VALIDACION';
        p_mensaje := format('pa_finalizar_alquiler: km_fin (%s) menor a km_inicio (%s)', p_km_fin, v_km_inicio);
        RETURN;
    END IF;

    IF p_id_sucursal_devolucion IS NULL THEN
        p_estado  := 'ERROR_VALIDACION';
        p_mensaje := 'pa_finalizar_alquiler: id_sucursal_devolucion es obligatorio';
        RETURN;
    END IF;

    IF v_estado_limpio NOT IN ('disponible', 'en_mantenimiento') THEN
        p_estado  := 'ERROR_VALIDACION';
        p_mensaje := format(
            'pa_finalizar_alquiler: estado destino "%s" invalido (use disponible o en_mantenimiento)',
            p_estado_destino_vehiculo
        );
        RETURN;
    END IF;

    SELECT EXISTS(SELECT 1 FROM estado_vehiculo WHERE nombre = v_estado_limpio)
        INTO v_estado_existe;
    IF NOT v_estado_existe THEN
        p_estado  := 'ERROR_REFERENCIAL';
        p_mensaje := format('pa_finalizar_alquiler: estado "%s" no existe en catalogo estado_vehiculo', v_estado_limpio);
        RETURN;
    END IF;

    IF v_estado_limpio = 'en_mantenimiento' AND p_id_taller IS NULL THEN
        p_estado  := 'ERROR_VALIDACION';
        p_mensaje := 'pa_finalizar_alquiler: si el destino es en_mantenimiento, p_id_taller es obligatorio';
        RETURN;
    END IF;

    -- 2. Cierre del alquiler. Disparadores asociados:
    --      trg_alquiler_set_cerrado (BEFORE UPDATE): NEW.estado := 'cerrado'
    --      trg_alquiler_close       (AFTER UPDATE):  cierra historial + ubicacion,
    --                                                abre ubicacion nueva en p_id_sucursal_devolucion,
    --                                                refleja vehiculo.id_estado = 'disponible',
    --                                                actualiza vehiculo.km_actuales
    UPDATE alquiler
    SET fecha_devolucion_real = NOW(),
        km_fin                = p_km_fin,
        id_sucursal_devolucion = p_id_sucursal_devolucion
    WHERE id_alquiler = p_id_alquiler;

    -- 3. Si va a taller, registrar mantenimiento. El disparador fn_mantenimiento_envio
    --    propaga el estado 'en_mantenimiento' al vehiculo via catalogo.
    IF v_estado_limpio = 'en_mantenimiento' THEN
        v_motivo_mantto := COALESCE(
            p_observaciones,
            'Enviado a taller al finalizar el alquiler #' || p_id_alquiler
        );
        INSERT INTO mantenimiento (id_vehiculo, id_taller, fecha_envio, fecha_devolucion, observaciones)
        VALUES (v_id_vehiculo, p_id_taller, CURRENT_DATE, NULL, v_motivo_mantto);
    END IF;

    -- 4. Emision de factura
    p_id_factura := fn_calcular_factura(p_id_alquiler);

    p_estado  := 'OK';
    p_mensaje := format(
        'Alquiler %s cerrado, vehiculo %s en estado "%s", factura %s emitida.',
        p_id_alquiler, v_id_vehiculo, v_estado_limpio, p_id_factura
    );

EXCEPTION
    WHEN unique_violation THEN
        p_estado     := 'ERROR_DUPLICADO';
        p_mensaje    := SQLERRM;
        p_id_factura := NULL;
    WHEN foreign_key_violation THEN
        p_estado     := 'ERROR_REFERENCIAL';
        p_mensaje    := SQLERRM;
        p_id_factura := NULL;
    WHEN check_violation THEN
        p_estado     := 'ERROR_VALIDACION';
        p_mensaje    := SQLERRM;
        p_id_factura := NULL;
    WHEN OTHERS THEN
        p_estado     := 'ERROR';
        p_mensaje    := SQLERRM;
        p_id_factura := NULL;
END;
$$;
