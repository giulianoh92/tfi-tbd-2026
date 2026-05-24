-- Procedure: pa_registrar_alquiler
-- Sprint 3 (R3, R4, R5, R6). Orquestador unico para alta de alquiler.
--
-- Soporta dos modalidades (R6):
--   1) Con reserva previa: p_id_reserva != NULL. La reserva debe existir,
--      estar 'pendiente', pertenecer al mismo cliente y vehiculo, y las
--      fechas deben coincidir con las de la reserva.
--   2) Walk-in (sin reserva): p_id_reserva = NULL. Se validan vehiculo
--      operativo, cliente activo y periodo. La superposicion la valida el
--      trigger trg_alquiler_no_overlap (BEFORE INSERT sobre alquiler).
--
-- Triggers asociados (NO se duplican aqui):
--   * fn_check_vehiculo_overlap (BEFORE INSERT)  -> superposicion.
--   * fn_alquiler_start         (AFTER  INSERT)  -> marca reserva como
--                                                   'concretada' y vehiculo
--                                                   como 'alquilado'.
--
-- Contrato de retorno (R4):
--   p_estado      : 'OK' | 'ERROR_VALIDACION' | 'ERROR_DUPLICADO' |
--                   'ERROR_REFERENCIAL' | 'ERROR_ESTADO' | 'ERROR'.
--   p_mensaje     : descripcion legible (SQLERRM en errores).
--   p_id_generado : id_alquiler creado (NULL si error).
--
-- Sprint 6 (B4.3) — fn_validar_periodo soporta tolerancia: en walk-in se
-- invoca con INTERVAL '5 minutes' para que el flujo sea robusto a la
-- latencia HTTP entre el NOW() del frontend y el NOW() del servidor. En
-- pa_registrar_reserva sigue llamandose sin parametro (default 0). La
-- responsabilidad de "fecha futura" queda asi siempre en la DB, no en el
-- frontend.
--
-- Sprint 6 (B4.1) — validacion de tarifa coherente: la tarifa elegida
-- debe pertenecer a la sucursal de origen del vehiculo Y al tipo del
-- vehiculo. La FK aislada (alquiler.id_tarifa -> tarifa) no lo asegura
-- porque tarifa.id_sucursal y tarifa.id_tipo son independientes de
-- vehiculo. Sin esta validacion un cliente podia aplicar la tarifa mas
-- barata de cualquier sucursal/tipo a su alquiler.

-- R11: declarada como FUNCTION (no PROCEDURE) para que PostgREST la exponga
-- via /rest/v1/rpc. Ver JUSTIFICACION.md §R11.
CREATE OR REPLACE FUNCTION pa_registrar_alquiler(
    p_id_reserva   BIGINT,
    p_id_cliente   BIGINT,
    p_id_vehiculo  BIGINT,
    p_id_tarifa    BIGINT,
    p_fecha_inicio TIMESTAMP,
    p_fecha_fin    TIMESTAMP,
    p_km_inicio    INTEGER,
    OUT p_estado   TEXT,
    OUT p_mensaje  TEXT,
    OUT p_id_generado BIGINT
)
RETURNS RECORD
LANGUAGE plpgsql
AS $$
DECLARE
    v_reserva_estado     TEXT;
    v_reserva_cliente    BIGINT;
    v_reserva_vehiculo   BIGINT;
    v_reserva_inicio     TIMESTAMP;
    v_reserva_fin        TIMESTAMP;
    v_km_actuales        INTEGER;
BEGIN
    p_estado      := 'ERROR';
    p_mensaje     := NULL;
    p_id_generado := NULL;

    -- 1) Validaciones comunes a ambas ramas.
    IF p_km_inicio IS NULL OR p_km_inicio < 0 THEN
        p_estado  := 'ERROR_VALIDACION';
        p_mensaje := 'El kilometraje inicial es obligatorio y no negativo.';
        RETURN;
    END IF;

    -- Cargar km_actuales del vehiculo. Si el vehiculo no existe, mas adelante
    -- la fn_validar_vehiculo_operativo o el FK lanzan el error apropiado.
    SELECT km_actuales
      INTO v_km_actuales
      FROM vehiculo
     WHERE id_vehiculo = p_id_vehiculo;

    IF NOT FOUND THEN
        p_estado  := 'ERROR_REFERENCIAL';
        p_mensaje := format('El vehiculo %s no existe.', p_id_vehiculo);
        RETURN;
    END IF;

    IF p_km_inicio < v_km_actuales THEN
        p_estado  := 'ERROR_VALIDACION';
        p_mensaje := format(
            'El km_inicio (%s) es menor al km_actuales del vehiculo (%s).',
            p_km_inicio, v_km_actuales
        );
        RETURN;
    END IF;

    -- Sprint 6 (B4.1) — Coherencia tarifa <-> vehiculo.
    -- La FK alquiler.id_tarifa -> tarifa garantiza que la tarifa existe,
    -- pero NO que corresponda al tipo y sucursal de origen del vehiculo
    -- elegido. Sin este check, un cliente podia consumir la tarifa mas
    -- barata de cualquier sucursal/tipo del catalogo. Cerramos esa fuga
    -- a nivel procedure (la unica via legitima de creacion de alquiler).
    IF NOT EXISTS (
        SELECT 1
        FROM tarifa t
        JOIN vehiculo v
          ON v.id_tipo            = t.id_tipo
         AND v.id_sucursal_origen = t.id_sucursal
        WHERE t.id_tarifa   = p_id_tarifa
          AND v.id_vehiculo = p_id_vehiculo
    ) THEN
        p_estado  := 'ERROR_VALIDACION';
        p_mensaje := 'La tarifa no corresponde al tipo/sucursal del vehiculo elegido.';
        RETURN;
    END IF;

    -- 2) Ramificacion por modalidad.
    IF p_id_reserva IS NOT NULL THEN
        ------------------------------------------------------------------
        -- Rama "con reserva previa".
        ------------------------------------------------------------------
        -- Bloquear la fila de la reserva para evitar carrera con un cancel
        -- en paralelo. Si dos requests intentan concretar la misma reserva,
        -- la segunda espera y luego ve estado != 'pendiente'.
        SELECT estado, id_cliente, id_vehiculo, fecha_inicio, fecha_fin_prevista
          INTO v_reserva_estado, v_reserva_cliente, v_reserva_vehiculo,
               v_reserva_inicio, v_reserva_fin
          FROM reserva
         WHERE id_reserva = p_id_reserva
         FOR UPDATE;

        IF NOT FOUND THEN
            p_estado  := 'ERROR_REFERENCIAL';
            p_mensaje := format('La reserva %s no existe.', p_id_reserva);
            RETURN;
        END IF;

        IF v_reserva_estado <> 'pendiente' THEN
            p_estado  := 'ERROR_ESTADO';
            p_mensaje := format(
                'La reserva %s no esta pendiente (estado actual: %s).',
                p_id_reserva, v_reserva_estado
            );
            RETURN;
        END IF;

        IF v_reserva_cliente IS DISTINCT FROM p_id_cliente THEN
            p_estado  := 'ERROR_VALIDACION';
            p_mensaje := format(
                'La reserva %s pertenece al cliente %s, no al %s.',
                p_id_reserva, v_reserva_cliente, p_id_cliente
            );
            RETURN;
        END IF;

        IF v_reserva_vehiculo IS DISTINCT FROM p_id_vehiculo THEN
            p_estado  := 'ERROR_VALIDACION';
            p_mensaje := format(
                'La reserva %s es del vehiculo %s, no del %s.',
                p_id_reserva, v_reserva_vehiculo, p_id_vehiculo
            );
            RETURN;
        END IF;

        IF v_reserva_inicio IS DISTINCT FROM p_fecha_inicio
           OR v_reserva_fin IS DISTINCT FROM p_fecha_fin THEN
            p_estado  := 'ERROR_VALIDACION';
            p_mensaje := format(
                'Las fechas no coinciden con la reserva %s (%s a %s).',
                p_id_reserva, v_reserva_inicio, v_reserva_fin
            );
            RETURN;
        END IF;

        -- No invocamos fn_validar_vehiculo_operativo aqui: cuando la reserva
        -- esta 'pendiente', el vehiculo puede estar en 'disponible' o
        -- incluso ya marcado por otro flujo. La superposicion la cuida el
        -- trigger; la coherencia clienta/vehiculo/fechas ya se valido.

    ELSE
        ------------------------------------------------------------------
        -- Rama "walk-in" (sin reserva previa).
        ------------------------------------------------------------------
        -- Sprint 6 (B4.3): tolerancia de 5 minutos sobre NOW(). En walk-in
        -- el staff completa la fecha de inicio en el frontend y la envia
        -- al backend; entre uno y otro pueden pasar varios segundos. Sin
        -- tolerancia, un click lento generaba un check_violation espureo
        -- ("la fecha de inicio debe ser futura"). 5 minutos cubre latencia
        -- razonable sin abrir la puerta a registrar alquileres del pasado.
        PERFORM fn_validar_periodo(p_fecha_inicio, p_fecha_fin, INTERVAL '5 minutes');
        PERFORM fn_validar_cliente_activo(p_id_cliente);
        PERFORM fn_validar_vehiculo_operativo(p_id_vehiculo);
    END IF;

    -- 3) INSERT. El trigger fn_alquiler_start (AFTER INSERT) marca la
    --    reserva como 'concretada' y el vehiculo como 'alquilado'. El
    --    trigger fn_check_vehiculo_overlap (BEFORE INSERT) valida
    --    superposicion contra otros alquileres / reservas.
    INSERT INTO alquiler (
        id_reserva,
        id_cliente,
        id_vehiculo,
        id_tarifa,
        fecha_inicio,
        fecha_fin_prevista,
        km_inicio
    )
    VALUES (
        p_id_reserva,
        p_id_cliente,
        p_id_vehiculo,
        p_id_tarifa,
        p_fecha_inicio,
        p_fecha_fin,
        p_km_inicio
    )
    RETURNING id_alquiler INTO p_id_generado;

    p_estado  := 'OK';
    p_mensaje := format('Alquiler %s registrado exitosamente.', p_id_generado);

EXCEPTION
    WHEN unique_violation THEN
        -- alquiler.id_reserva es UNIQUE; si alguien intenta crear un segundo
        -- alquiler sobre la misma reserva, cae aca.
        p_estado      := 'ERROR_DUPLICADO';
        p_mensaje     := SQLERRM;
        p_id_generado := NULL;
    WHEN exclusion_violation THEN
        -- Sprint 6 (B1): 23P01 = exclusion_violation. Lo dispara la EXCLUDE
        -- constraint excl_alquiler_overlap cuando otra transaccion ya ocupo
        -- el rango con un id_vehiculo + tsrange solapado. Es el "lock
        -- optimista" idiomatico: el indice GiST valida atomicamente, sin
        -- ventana de carrera entre SELECT y INSERT como tenia el trigger.
        p_estado      := 'ERROR_SUPERPOSICION';
        p_mensaje     := 'El vehiculo ya esta reservado/alquilado en ese periodo.';
        p_id_generado := NULL;
    WHEN foreign_key_violation THEN
        p_estado      := 'ERROR_REFERENCIAL';
        p_mensaje     := SQLERRM;
        p_id_generado := NULL;
    WHEN check_violation THEN
        -- Lanzan check_violation:
        --   * chk_alquiler_fechas / chk_alquiler_km de la tabla.
        --   * fn_validar_periodo, fn_validar_cliente_activo (caso
        --     p_id_cliente NULL), fn_validar_vehiculo_operativo (cuando el
        --     estado <> 'disponible').
        p_estado      := 'ERROR_VALIDACION';
        p_mensaje     := SQLERRM;
        p_id_generado := NULL;
    WHEN OTHERS THEN
        -- Captura el RAISE del trigger best-effort fn_check_vehiculo_overlap
        -- (mensaje legible antes de llegar al EXCLUDE). La garantia dura es
        -- la EXCLUDE (rama exclusion_violation arriba); esta rama solo
        -- existe para mensajes mas claros en el camino feliz.
        IF SQLERRM ILIKE '%superpone%' OR SQLERRM ILIKE '%overlap%' THEN
            p_estado := 'ERROR_SUPERPOSICION';
        ELSE
            p_estado := 'ERROR';
        END IF;
        p_mensaje     := SQLERRM;
        p_id_generado := NULL;
END;
$$;
