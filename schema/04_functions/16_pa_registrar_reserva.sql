-- Procedure: pa_registrar_reserva
-- Sprint 2 (R7). Orquestador unico para alta de reserva.
--
-- Diseno modular: la validacion de superposicion de fechas la sigue
-- haciendo el trigger BEFORE INSERT fn_check_vehiculo_overlap sobre la
-- tabla reserva (schema/04_functions/02_*.sql). Este procedure NO la
-- replica: confia en el trigger y captura la excepcion que pueda lanzar
-- en su bloque EXCEPTION OTHERS (mapeada a ERROR_VALIDACION).
--
-- Contrato de retorno estandarizado (JUSTIFICACION.md §R4):
--   p_estado      : 'OK' | 'ERROR_VALIDACION' | 'ERROR_DUPLICADO' |
--                   'ERROR_REFERENCIAL' | 'ERROR'
--   p_mensaje     : descripcion legible del resultado (en error: SQLERRM)
--   p_id_generado : id_reserva creado (NULL si error)
--
-- Validaciones reusables invocadas (R7 - modularizacion):
--   fn_validar_periodo, fn_validar_cliente_activo, fn_validar_vehiculo_operativo.
--   Las tres lanzan RAISE EXCEPTION; se capturan transparentemente en el
--   bloque EXCEPTION WHEN OTHERS y mapean por SQLSTATE.

CREATE OR REPLACE PROCEDURE pa_registrar_reserva(
    IN  p_id_cliente      BIGINT,
    IN  p_id_vehiculo     BIGINT,
    IN  p_id_tipo_reserva BIGINT,
    IN  p_fecha_inicio    TIMESTAMP,
    IN  p_fecha_fin       TIMESTAMP,
    OUT p_estado          TEXT,
    OUT p_mensaje         TEXT,
    OUT p_id_generado     BIGINT
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Inicializacion defensiva por si alguna rama no asigna.
    p_estado      := 'ERROR';
    p_mensaje     := NULL;
    p_id_generado := NULL;

    -- 1) Validaciones modulares (lanzan EXCEPTION ante fallo).
    PERFORM fn_validar_periodo(p_fecha_inicio, p_fecha_fin);
    PERFORM fn_validar_cliente_activo(p_id_cliente);
    PERFORM fn_validar_vehiculo_operativo(p_id_vehiculo);

    -- 2) INSERT en reserva. El trigger trg_reserva_no_overlap valida
    --    superposicion contra otras reservas y alquileres activos.
    INSERT INTO reserva (
        id_cliente,
        id_vehiculo,
        id_tipo_reserva,
        fecha_inicio,
        fecha_fin_prevista
    )
    VALUES (
        p_id_cliente,
        p_id_vehiculo,
        p_id_tipo_reserva,
        p_fecha_inicio,
        p_fecha_fin
    )
    RETURNING id_reserva INTO p_id_generado;

    p_estado  := 'OK';
    p_mensaje := format('Reserva %s creada exitosamente.', p_id_generado);

EXCEPTION
    WHEN unique_violation THEN
        p_estado      := 'ERROR_DUPLICADO';
        p_mensaje     := SQLERRM;
        p_id_generado := NULL;
    WHEN foreign_key_violation THEN
        p_estado      := 'ERROR_REFERENCIAL';
        p_mensaje     := SQLERRM;
        p_id_generado := NULL;
    WHEN check_violation THEN
        -- Disparado por fn_validar_periodo, fn_validar_vehiculo_operativo
        -- (cuando estado != disponible) y por chk_reserva_fechas /
        -- chk_reserva_estado.
        p_estado      := 'ERROR_VALIDACION';
        p_mensaje     := SQLERRM;
        p_id_generado := NULL;
    WHEN OTHERS THEN
        -- Captura tambien el RAISE del trigger fn_check_vehiculo_overlap
        -- (sin SQLSTATE especifico). Mapeamos a ERROR_VALIDACION cuando el
        -- mensaje refiere superposicion para que el frontend lo trate como
        -- error de negocio, no como 500.
        IF SQLERRM ILIKE '%superpone%' OR SQLERRM ILIKE '%overlap%' THEN
            p_estado := 'ERROR_VALIDACION';
        ELSE
            p_estado := 'ERROR';
        END IF;
        p_mensaje     := SQLERRM;
        p_id_generado := NULL;
END;
$$;
