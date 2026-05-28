-- Procedure: pa_registrar_reserva (R7)
-- Orquestador unico para alta de reserva.
--
-- Diseno modular: la validacion de superposicion de fechas la sigue
-- haciendo el disparador BEFORE INSERT fn_check_vehiculo_overlap sobre la
-- tabla reserva (schema/04_functions/02_*.sql). Este procedimiento NO la
-- replica: confia en el disparador y captura la excepcion que pueda lanzar
-- en su bloque EXCEPTION OTHERS (mapeada a ERROR_VALIDACION).
--
-- Contrato de retorno estandarizado (R4):
--   p_estado      : 'OK' | 'ERROR_VALIDACION' | 'ERROR_DUPLICADO' |
--                   'ERROR_REFERENCIAL' | 'ERROR'
--   p_mensaje     : descripcion legible del resultado (en error: SQLERRM)
--   p_id_generado : id_reserva creado (NULL si error)
--
-- Validaciones reutilizables invocadas (R7 - modularizacion):
--   fn_validar_periodo, fn_validar_cliente_activo, fn_validar_vehiculo_operativo.
--   Las tres lanzan RAISE EXCEPTION; se capturan en el bloque EXCEPTION WHEN
--   OTHERS y se clasifican por SQLSTATE.

-- Garantia con tarjeta: si el tipo de reserva tiene requiere_garantia=TRUE
-- (caso "estandar"), la regla del negocio exige que el cliente cargue una
-- tarjeta de credito como garantia al momento de reservar. El procedimiento
-- recibe los 4 datos sensibles como parametros opcionales, los valida y los
-- persiste en garantia_reserva dentro de la misma transaccion. El numero
-- de tarjeta se almacena con resumen criptografico (hash) bcrypt via pgcrypto
-- para no guardar el numero en texto legible. La aplicacion cliente nunca debe
-- ver el resumen; solo envia el numero en texto plano por HTTPS y se descarta
-- del lado del servidor.

-- R11: declarada como FUNCTION (no PROCEDURE) para que PostgREST la exponga
-- via /rest/v1/rpc.
CREATE OR REPLACE FUNCTION pa_registrar_reserva(
    p_id_cliente      BIGINT,
    p_id_vehiculo     BIGINT,
    p_id_tipo_reserva BIGINT,
    p_fecha_inicio    TIMESTAMP,
    p_fecha_fin       TIMESTAMP,
    p_garantia_tipo            VARCHAR(30)  DEFAULT NULL,
    p_garantia_titular         VARCHAR(100) DEFAULT NULL,
    p_garantia_numero_tarjeta  TEXT         DEFAULT NULL,
    p_garantia_vencimiento     DATE         DEFAULT NULL,
    OUT p_estado      TEXT,
    OUT p_mensaje     TEXT,
    OUT p_id_generado BIGINT
)
RETURNS RECORD
LANGUAGE plpgsql
AS $$
DECLARE
    v_requiere_garantia BOOLEAN;
    v_numero_hash       TEXT;
BEGIN
    -- Inicializacion preventiva por si alguna rama no asigna valor.
    p_estado      := 'ERROR';
    p_mensaje     := NULL;
    p_id_generado := NULL;

    -- 1) Validaciones modulares (lanzan EXCEPTION ante fallo).
    --    NULL en p_tolerancia_pasado activa el modo "granularidad dia": el
    --    formulario de reserva en linea envia marca de tiempo con hora 00:00:00,
    --    y la regla de negocio real es "la reserva debe ser para hoy o un dia
    --    futuro", no "para una marca de tiempo futura".
    PERFORM fn_validar_periodo(p_fecha_inicio, p_fecha_fin, NULL);
    PERFORM fn_validar_cliente_activo(p_id_cliente);
    PERFORM fn_validar_vehiculo_operativo(p_id_vehiculo);

    -- 2) Lookup del tipo de reserva para saber si exige garantia.
    SELECT requiere_garantia INTO v_requiere_garantia
    FROM tipo_reserva
    WHERE id_tipo_reserva = p_id_tipo_reserva;

    IF NOT FOUND THEN
        p_estado  := 'ERROR_REFERENCIAL';
        p_mensaje := format('El tipo de reserva con ID %s no existe.', p_id_tipo_reserva);
        RETURN;
    END IF;

    IF v_requiere_garantia THEN
        IF p_garantia_tipo IS NULL
           OR p_garantia_titular IS NULL
           OR p_garantia_numero_tarjeta IS NULL
           OR p_garantia_vencimiento IS NULL THEN
            p_estado  := 'ERROR_VALIDACION';
            p_mensaje := 'REGLA DE NEGOCIO: este tipo de reserva exige cargar los datos de la tarjeta como garantia (tipo, titular, numero y vencimiento).';
            RETURN;
        END IF;

        IF p_garantia_vencimiento < CURRENT_DATE THEN
            p_estado  := 'ERROR_VALIDACION';
            p_mensaje := format(
                'REGLA DE NEGOCIO: la tarjeta de garantia esta vencida (vencimiento %s).',
                p_garantia_vencimiento
            );
            RETURN;
        END IF;
    END IF;

    -- 3) INSERT en reserva. El disparador trg_reserva_no_overlap valida
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

    -- 4) Si el tipo exige garantia, persistirla con el numero con resumen
    --    criptografico (bcrypt via pgcrypto). El INSERT esta dentro de la misma
    --    transaccion del procedimiento: si falla, la reserva del paso 3
    --    tambien se revierte.
    IF v_requiere_garantia THEN
        v_numero_hash := crypt(p_garantia_numero_tarjeta, gen_salt('bf'));
        INSERT INTO garantia_reserva (
            id_reserva,
            tipo,
            titular,
            numero_tarjeta_hash,
            vencimiento,
            activa
        )
        VALUES (
            p_id_generado,
            p_garantia_tipo,
            p_garantia_titular,
            v_numero_hash,
            p_garantia_vencimiento,
            TRUE
        );
    END IF;

    p_estado  := 'OK';
    p_mensaje := format('Reserva %s creada exitosamente.', p_id_generado);

EXCEPTION
    WHEN unique_violation THEN
        p_estado      := 'ERROR_DUPLICADO';
        p_mensaje     := SQLERRM;
        p_id_generado := NULL;
    WHEN exclusion_violation THEN
        -- 23P01 = exclusion_violation. Lo dispara la EXCLUDE constraint
        -- excl_reserva_overlap cuando otra transaccion ya ocupo el rango
        -- con un id_vehiculo + tsrange solapado. Es el mecanismo idiomatico
        -- de exclusion optimista: el indice GiST valida atomicamente, sin
        -- ventana de condicion de carrera entre SELECT e INSERT como tenia
        -- el disparador.
        p_estado      := 'ERROR_SUPERPOSICION';
        p_mensaje     := 'El vehiculo ya esta reservado/alquilado en ese periodo.';
        p_id_generado := NULL;
    WHEN foreign_key_violation THEN
        p_estado      := 'ERROR_REFERENCIAL';
        p_mensaje     := SQLERRM;
        p_id_generado := NULL;
    WHEN check_violation THEN
        -- Activado por fn_validar_periodo, fn_validar_vehiculo_operativo
        -- (cuando estado != disponible) y por chk_reserva_fechas /
        -- chk_reserva_estado.
        p_estado      := 'ERROR_VALIDACION';
        p_mensaje     := SQLERRM;
        p_id_generado := NULL;
    WHEN OTHERS THEN
        -- Captura el RAISE del disparador fn_check_vehiculo_overlap, que actua
        -- como validacion preventiva (mensaje claro antes de llegar al EXCLUDE).
        -- La garantia formal es la EXCLUDE (rama exclusion_violation arriba);
        -- esta rama existe solo para mensajes mas claros en el flujo habitual.
        IF SQLERRM ILIKE '%superpone%' OR SQLERRM ILIKE '%overlap%' THEN
            p_estado  := 'ERROR_SUPERPOSICION';
            p_mensaje := 'El vehiculo ya esta reservado en ese periodo. Proba con otras fechas.';
        ELSE
            p_estado  := 'ERROR';
            p_mensaje := SQLERRM;
        END IF;
        p_id_generado := NULL;
END;
$$;
