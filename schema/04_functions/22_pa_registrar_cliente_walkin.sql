-- pa_registrar_cliente_walkin(...) -- registro de cliente presencial sin
-- cuenta en linea (R6 alta presencial: "los clientes presenciales no requieren
-- cuenta en linea").
--
-- Inserta solamente en public.cliente. NO toca auth.users: los clientes
-- presenciales operan sin inicio de sesion. El campo auth_user_id queda NULL.
-- Si despues el cliente decide crear cuenta en linea, se vincula via el
-- disparador fn_handle_new_auth_user que busca por DNI.
--
-- Trazabilidad de triple identidad: la insercion activa fn_audit_generic
-- que registra (rol_sesion, usuario_db, usuario_app); el personal queda como
-- responsable de la operacion via su JWT.
--
-- R11: FUNCTION para exposicion via PostgREST RPC.
CREATE OR REPLACE FUNCTION pa_registrar_cliente_walkin(
    p_dni        VARCHAR,
    p_nombre     VARCHAR,
    p_apellido   VARCHAR,
    p_telefono   VARCHAR DEFAULT NULL,
    p_direccion  TEXT    DEFAULT NULL,
    OUT p_estado       TEXT,
    OUT p_mensaje      TEXT,
    OUT p_id_generado  BIGINT
)
RETURNS RECORD
LANGUAGE plpgsql
AS $$
BEGIN
    p_estado      := 'ERROR';
    p_mensaje     := NULL;
    p_id_generado := NULL;

    -- Solo el personal puede crear clientes presenciales (defensa en profundidad).
    IF NOT fn_es_staff() THEN
        p_estado  := 'ERROR_ESTADO';
        p_mensaje := 'Operacion permitida solo a usuarios staff.';
        RETURN;
    END IF;

    -- Validaciones minimas.
    IF p_dni IS NULL OR length(trim(p_dni)) = 0 THEN
        p_estado  := 'ERROR_VALIDACION';
        p_mensaje := 'DNI obligatorio.';
        RETURN;
    END IF;
    IF p_nombre IS NULL OR length(trim(p_nombre)) = 0 THEN
        p_estado  := 'ERROR_VALIDACION';
        p_mensaje := 'Nombre obligatorio.';
        RETURN;
    END IF;
    IF p_apellido IS NULL OR length(trim(p_apellido)) = 0 THEN
        p_estado  := 'ERROR_VALIDACION';
        p_mensaje := 'Apellido obligatorio.';
        RETURN;
    END IF;

    INSERT INTO cliente (dni, nombre, apellido, telefono, direccion, id_usuario, auth_user_id)
    VALUES (trim(p_dni), trim(p_nombre), trim(p_apellido), p_telefono, p_direccion, NULL, NULL)
    RETURNING id_cliente INTO p_id_generado;

    p_estado  := 'OK';
    p_mensaje := format('Cliente presencial creado (id=%s, dni=%s).', p_id_generado, p_dni);

EXCEPTION
    WHEN unique_violation THEN
        p_estado     := 'ERROR_DUPLICADO';
        p_mensaje    := format('Ya existe un cliente con DNI %s.', p_dni);
        p_id_generado := NULL;
    WHEN check_violation THEN
        p_estado     := 'ERROR_VALIDACION';
        p_mensaje    := SQLERRM;
        p_id_generado := NULL;
    WHEN OTHERS THEN
        p_estado     := 'ERROR';
        p_mensaje    := SQLERRM;
        p_id_generado := NULL;
END;
$$;
