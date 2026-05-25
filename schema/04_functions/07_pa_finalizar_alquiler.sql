-- pa_finalizar_alquiler(...) — Orquestador transaccional del CU-06 (R10).
--
-- Cierra un alquiler activo, dispara los triggers de ciclo de vida del vehiculo
-- (ubicacion + historial + estado en el catalogo), emite la factura y opcionalmente
-- envia el vehiculo a mantenimiento.
--
-- Diseno transaccional (R2):
--   * El cuerpo va envuelto en BEGIN ... EXCEPTION WHEN ... THEN ... END para
--     cumplir el manejo de excepciones (COMMIT/ROLLBACK por espiritu). En
--     Postgres el BEGIN del procedure asocia un savepoint implicito: si una
--     excepcion se captura, se hace rollback al savepoint; si el bloque
--     termina sin excepcion, la transaccion del caller se compromete
--     normalmente.
--   * Los OUT parameters estandarizados (p_estado, p_mensaje, p_id_factura)
--     permiten al frontend mostrar mensajes legibles en lugar de error 500.
--     Mismo contrato que pa_registrar_reserva / etc.
--
-- Aporte original: Marcia Viera (commit 257d86f del 2026-05-16,
-- "funcionalidad finalizar alquiler"). Adaptaciones al schema reescrito:
--   * Drop UPDATE directo de vehiculo.estado / historial_estado_vehiculo.estado
--     (columnas inexistentes en el nuevo modelo): el trigger fn_alquiler_close
--     ya cierra historial, abre ubicacion en la sucursal de devolucion y
--     mirrorea id_estado en vehiculo desde el catalogo estado_vehiculo.
--   * Si el destino es mantenimiento, basta con INSERT en mantenimiento: el
--     trigger fn_mantenimiento_envio propaga el estado 'en_mantenimiento' al
--     vehiculo via catalogo. La secuencia produce dos transiciones en historial
--     (alquilado -> disponible -> en_mantenimiento), correctas para auditoria.
--   * Valida estado destino contra el catalogo (no hardcoded VARCHAR).
--
-- IMPORTANTE — firma vs. GRANTs: cambiar OUT parameters altera la identidad
-- del procedure en pg_proc. Por eso primero hacemos DROP PROCEDURE de la
-- firma vieja explicita (que solo tenia IN params) antes del CREATE OR
-- REPLACE. Si no se hiciera, el CREATE fallaria con "cannot change name of
-- input parameter" o quedarian dos procedures con el mismo nombre y
-- distinta firma. Cualquier GRANT EXECUTE explicito sobre la firma vieja
-- queda invalidado; el bloque DO al final de 04_rls_policies.sql vuelve a
-- otorgar EXECUTE a todos los procedures.

DROP FUNCTION IF EXISTS pa_finalizar_alquiler(
    BIGINT, INTEGER, BIGINT, VARCHAR, BIGINT, TEXT
) CASCADE;

-- Los 3 ultimos IN parameters van con DEFAULT NULL para que el caller mas
-- frecuente (cierre con destino "disponible", flujo normal sin envio a
-- taller) pueda invocar la function solo con los 3 args obligatorios via
-- PostgREST RPC.
--
-- Regla de Postgres: los IN con DEFAULT deben ir AL FINAL de la lista de
-- IN params; los OUT son separados y pueden ir despues. Esta firma es
-- valida.
--
-- Llamadas validas desde PostgREST:
--   * { p_id_alquiler, p_km_fin, p_id_sucursal_devolucion }
--       -> destino "disponible" (default), sin mantenimiento
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
    -- Inicializacion defensiva por si alguna rama no asigna explicitamente.
    p_estado     := 'ERROR';
    p_mensaje    := NULL;
    p_id_factura := NULL;

    -- Si el caller no especifica estado destino, asumimos 'disponible' (default
     -- de negocio). Antes era un DEFAULT del IN; se movio aca para respetar la
     -- regla de Postgres "no DEFAULT antes de OUT".
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

    -- 2. Cierre del alquiler. Triggers asociados:
    --      trg_alquiler_set_cerrado (BEFORE UPDATE): NEW.estado := 'cerrado'
    --      trg_alquiler_close       (AFTER UPDATE):  cierra historial + ubicacion,
    --                                                abre ubicacion nueva en p_id_sucursal_devolucion,
    --                                                mirrorea vehiculo.id_estado = 'disponible',
    --                                                actualiza vehiculo.km_actuales
    UPDATE alquiler
    SET fecha_devolucion_real = NOW(),
        km_fin                = p_km_fin,
        id_sucursal_devolucion = p_id_sucursal_devolucion
    WHERE id_alquiler = p_id_alquiler;

    -- 3. Si va a taller, registrar mantenimiento. Trigger fn_mantenimiento_envio
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
