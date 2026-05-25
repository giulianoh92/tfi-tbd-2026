-- Procedure: pa_cancelar_reserva (R8)
-- Cancela una reserva validando transicion de estado.
--
-- Uso de modos de parametro (R5):
--   IN    p_id_reserva : id de la reserva a cancelar.
--   INOUT p_motivo     : entra el motivo del cliente; sale enriquecido con
--                        prefijo "[timestamp | usuario uuid]" para dejar
--                        rastro auditable de quien/cuando cancelo.
--   OUT   p_estado     : codigo estandarizado.
--   OUT   p_mensaje    : descripcion legible.
--
-- Reglas de transicion (R8):
--   pendiente  -> cancelada       (permitido)
--   concretada -> *               (rechazado: hay que finalizar el alquiler)
--   cancelada  -> cancelada       (rechazado idempotente: ya esta cancelada)
--
-- Regla adicional: si existe un alquiler con id_reserva = p_id_reserva, la
-- reserva no puede cancelarse desde aqui aunque su estado siga 'pendiente'
-- (caso degenerado, pero defensa en profundidad).
--
-- Manejo transaccional (R2): no usamos COMMIT/ROLLBACK literales: el bloque
-- EXCEPTION hace rollback al savepoint implicito y el caller (PostgREST)
-- commitea al cerrar la transaccion HTTP si no se relanza.

-- R11: declarada como FUNCTION (no PROCEDURE) para que PostgREST la
-- exponga via /rest/v1/rpc.
CREATE OR REPLACE FUNCTION pa_cancelar_reserva(
    p_id_reserva    BIGINT,
    INOUT p_motivo  TEXT,
    OUT p_estado    TEXT,
    OUT p_mensaje   TEXT
)
RETURNS RECORD
LANGUAGE plpgsql
AS $$
DECLARE
    v_estado_actual TEXT;
    v_motivo_limpio TEXT;
    v_uuid_app      UUID;
    v_existe_alq    BOOLEAN;
BEGIN
    p_estado  := 'ERROR';
    p_mensaje := NULL;

    -- 0) Normalizacion del motivo (INOUT: lo modificamos para retornarlo).
    v_motivo_limpio := COALESCE(NULLIF(trim(p_motivo), ''), '(sin motivo informado)');

    -- Capturar usuario logico desde el JWT con fallback seguro.
    BEGIN
        v_uuid_app := (current_setting('request.jwt.claims', true)::jsonb ->> 'sub')::UUID;
    EXCEPTION WHEN OTHERS THEN
        v_uuid_app := NULL;
    END;

    -- Enriquecer p_motivo (forma del retorno INOUT) con metadata audit.
    p_motivo := format(
        '[%s | usuario %s] %s',
        to_char(NOW(), 'YYYY-MM-DD"T"HH24:MI:SSOF'),
        COALESCE(v_uuid_app::TEXT, 'anonimo'),
        v_motivo_limpio
    );

    -- 1) Localizar reserva y bloquear la fila para evitar carrera.
    SELECT estado
      INTO v_estado_actual
      FROM reserva
     WHERE id_reserva = p_id_reserva
     FOR UPDATE;

    IF NOT FOUND THEN
        p_estado  := 'ERROR_REFERENCIAL';
        p_mensaje := format('La reserva %s no existe.', p_id_reserva);
        RETURN;
    END IF;

    -- 2) Validar transicion de estado.
    IF v_estado_actual = 'cancelada' THEN
        p_estado  := 'ERROR_ESTADO';
        p_mensaje := 'La reserva ya esta cancelada.';
        RETURN;
    END IF;

    IF v_estado_actual = 'concretada' THEN
        p_estado  := 'ERROR_ESTADO';
        p_mensaje := 'La reserva ya fue concretada; debe finalizarse el alquiler asociado.';
        RETURN;
    END IF;

    IF v_estado_actual <> 'pendiente' THEN
        p_estado  := 'ERROR_ESTADO';
        p_mensaje := format('Estado actual "%s" no admite cancelacion.', v_estado_actual);
        RETURN;
    END IF;

    -- 3) Defensa adicional: no permitir cancelar si ya hay un alquiler creado
    --    referenciando esta reserva (caso degenerado: trigger no la marco
    --    como concretada todavia).
    SELECT EXISTS (
        SELECT 1 FROM alquiler WHERE id_reserva = p_id_reserva
    ) INTO v_existe_alq;

    IF v_existe_alq THEN
        p_estado  := 'ERROR_ESTADO';
        p_mensaje := 'Existe un alquiler asociado a esta reserva; no puede cancelarse.';
        RETURN;
    END IF;

    -- 4) Aplicar la transicion.
    UPDATE reserva
       SET estado = 'cancelada'
     WHERE id_reserva = p_id_reserva;

    p_estado  := 'OK';
    p_mensaje := format('Reserva %s cancelada exitosamente.', p_id_reserva);

EXCEPTION
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
