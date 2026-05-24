-- pa_registrar_devolucion_mantenimiento(...) — Cierra la orden de
-- mantenimiento abierta para un vehiculo. El trigger
-- trg_mantenimiento_devolucion (sobre mantenimiento) mirrorea el estado
-- 'disponible' al vehiculo via catalogo.
--
-- Sprint 5 (R2) — refactor:
--   * Cuerpo envuelto en BEGIN ... EXCEPTION WHEN ... THEN ... END.
--   * Agregados OUT p_estado / p_mensaje (contrato estandar JUSTIFICACION.md
--     §R4).
--
-- Cambio de firma -> DROP PROCEDURE previo con la firma vieja explicita.

DROP PROCEDURE IF EXISTS pa_registrar_devolucion_mantenimiento(
    BIGINT, INTEGER
) CASCADE;

-- Nota deploy fix: el caller debe pasar NULL explicito en p_km_salida_taller
-- cuando no aplique (Postgres no admite OUT despues de IN con DEFAULT).
CREATE OR REPLACE PROCEDURE pa_registrar_devolucion_mantenimiento(
    IN  p_id_vehiculo      BIGINT,
    IN  p_km_salida_taller INTEGER, -- NULL si no se reportan km al salir del taller
    OUT p_estado           TEXT,
    OUT p_mensaje          TEXT
)
LANGUAGE plpgsql AS $$
DECLARE
    v_id_estado_mantenimiento  BIGINT;
    v_id_estado_actual         BIGINT;
    v_id_mantenimiento_abierto BIGINT;
    v_km_actuales              INTEGER;
BEGIN
    p_estado  := 'ERROR';
    p_mensaje := NULL;

    -- 1. OBTENER ID DEL ESTADO MANTENIMIENTO DESDE EL CATALOGO
    SELECT id_estado INTO v_id_estado_mantenimiento
    FROM estado_vehiculo
    WHERE lower(nombre) = 'en_mantenimiento';
    -- Bugfix deploy: alineado al catalogo (antes buscaba 'mantenimiento' y
    -- siempre retornaba NULL).

    -- 2. CONTROL DE PRECONDICIONES (VALIDACION DE FLOTA Y ORDEN)
    -- Bloqueamos la fila del vehiculo para la transaccion.
    SELECT id_estado, km_actuales INTO v_id_estado_actual, v_km_actuales
    FROM vehiculo
    WHERE id_vehiculo = p_id_vehiculo
    FOR UPDATE;

    IF NOT FOUND THEN
        p_estado  := 'ERROR_REFERENCIAL';
        p_mensaje := format('El vehiculo con ID %s no existe.', p_id_vehiculo);
        RETURN;
    END IF;

    -- Validar que el vehiculo este operativamente en mantenimiento.
    IF v_id_estado_actual IS DISTINCT FROM v_id_estado_mantenimiento THEN
        p_estado  := 'ERROR_ESTADO';
        p_mensaje := 'REGLA DE NEGOCIO: El vehiculo no puede registrar devolucion porque su estado actual no es "mantenimiento".';
        RETURN;
    END IF;

    -- Verificar que exista una orden abierta en la tabla mantenimiento para este vehiculo.
    SELECT id_mantenimiento INTO v_id_mantenimiento_abierto
    FROM mantenimiento
    WHERE id_vehiculo = p_id_vehiculo
      AND fecha_devolucion IS NULL;

    IF v_id_mantenimiento_abierto IS NULL THEN
        p_estado  := 'ERROR_ESTADO';
        p_mensaje := format(
            'No se encontro ninguna orden de trabajo abierta para el vehiculo ID %s.',
            p_id_vehiculo
        );
        RETURN;
    END IF;

    -- 3. ACTUALIZACION OPERATIVA (CIERRE DE ORDEN Y KILOMETRAJE)
    IF p_km_salida_taller IS NOT NULL THEN
        IF p_km_salida_taller < v_km_actuales THEN
            p_estado  := 'ERROR_VALIDACION';
            p_mensaje := format(
                'Los kilometros informados al salir del taller (%s) no pueden ser menores a los actuales (%s).',
                p_km_salida_taller, v_km_actuales
            );
            RETURN;
        END IF;

        UPDATE vehiculo
        SET km_actuales = p_km_salida_taller
        WHERE id_vehiculo = p_id_vehiculo;
    END IF;

    -- Cerramos la orden de mantenimiento asignando la fecha de hoy.
    -- NOTA: Esto dispara de forma automatica el trigger trg_mantenimiento_devolucion.
    UPDATE mantenimiento
    SET fecha_devolucion = CURRENT_DATE
    WHERE id_mantenimiento = v_id_mantenimiento_abierto;

    p_estado  := 'OK';
    p_mensaje := format(
        'Devolucion del vehiculo %s registrada. Estado restablecido a "disponible".',
        p_id_vehiculo
    );

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
