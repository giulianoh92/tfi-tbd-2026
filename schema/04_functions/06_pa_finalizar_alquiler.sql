-- pa_finalizar_alquiler(...) - Orquestador transaccional del CU-06.
--
-- Cierra un alquiler activo, dispara los triggers de ciclo de vida del vehiculo
-- (ubicacion + historial + estado en el catalogo), emite la factura y opcionalmente
-- envia el vehiculo a mantenimiento.
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
CREATE OR REPLACE PROCEDURE pa_finalizar_alquiler(
    p_id_alquiler            BIGINT,
    p_km_fin                 INTEGER,
    p_id_sucursal_devolucion BIGINT,
    p_estado_final_vehiculo  VARCHAR DEFAULT 'disponible',
    p_id_taller              BIGINT  DEFAULT NULL,
    p_observaciones          TEXT    DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_id_vehiculo      BIGINT;
    v_km_inicio        INTEGER;
    v_id_factura       BIGINT;
    v_estado_limpio    VARCHAR(50);
    v_motivo_mantto    VARCHAR(255);
    v_estado_existe    BOOLEAN;
BEGIN
    v_estado_limpio := lower(p_estado_final_vehiculo);

    -- 1. Precondiciones
    SELECT id_vehiculo, km_inicio INTO v_id_vehiculo, v_km_inicio
    FROM alquiler
    WHERE id_alquiler = p_id_alquiler AND estado = 'activo';

    IF NOT FOUND THEN
        RAISE EXCEPTION 'pa_finalizar_alquiler: alquiler % no existe o ya esta cerrado', p_id_alquiler;
    END IF;

    IF p_km_fin < v_km_inicio THEN
        RAISE EXCEPTION 'pa_finalizar_alquiler: km_fin (%) menor a km_inicio (%)', p_km_fin, v_km_inicio;
    END IF;

    IF p_id_sucursal_devolucion IS NULL THEN
        RAISE EXCEPTION 'pa_finalizar_alquiler: id_sucursal_devolucion es obligatorio';
    END IF;

    IF v_estado_limpio NOT IN ('disponible', 'en_mantenimiento') THEN
        RAISE EXCEPTION 'pa_finalizar_alquiler: estado destino "%" invalido (use disponible o en_mantenimiento)',
            p_estado_final_vehiculo;
    END IF;

    SELECT EXISTS(SELECT 1 FROM estado_vehiculo WHERE nombre = v_estado_limpio) INTO v_estado_existe;
    IF NOT v_estado_existe THEN
        RAISE EXCEPTION 'pa_finalizar_alquiler: estado "%" no existe en catalogo estado_vehiculo', v_estado_limpio;
    END IF;

    IF v_estado_limpio = 'en_mantenimiento' AND p_id_taller IS NULL THEN
        RAISE EXCEPTION 'pa_finalizar_alquiler: si el destino es en_mantenimiento, p_id_taller es obligatorio';
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
    v_id_factura := fn_calcular_factura(p_id_alquiler);

    RAISE NOTICE 'pa_finalizar_alquiler: alquiler % cerrado, vehiculo % en estado "%", factura % emitida',
                 p_id_alquiler, v_id_vehiculo, v_estado_limpio, v_id_factura;
END;
$$;
