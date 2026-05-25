-- pa_registrar_cliente_con_usuario(...) — Alta atomica de bridge usuario +
-- perfil de cliente.
--
-- Notas de diseno:
--   * No recibe password_hash. La unica fuente de verdad para credenciales
--     es Supabase Auth (auth.users). El flujo real de signup pasa por
--     GoTrue + el trigger fn_handle_new_auth_user, que crea automaticamente
--     la fila cliente vinculada por auth_user_id.
--   * Este procedure persiste para casos de carga manual / scripting
--     (seeds, tests), donde se necesita crear el bridge usuario + cliente
--     sin pasar por Auth. NO autentica: si se llama desde la API publica
--     el cliente resultante no podra loguearse hasta vincularse a un
--     auth.users via auth_user_id.
--   * Las validaciones de formato basicas viven inline:
--     username/email no vacios, email con '@'.
--

-- R11: declarada como FUNCTION (no PROCEDURE) para que PostgREST la
-- exponga via /rest/v1/rpc.
CREATE OR REPLACE FUNCTION pa_registrar_cliente_con_usuario(
    p_username      VARCHAR,
    p_email         VARCHAR,
    p_nombre        VARCHAR,
    p_apellido      VARCHAR,
    p_dni           VARCHAR,
    p_telefono      VARCHAR,
    p_direccion     VARCHAR,
    OUT p_estado      TEXT,
    OUT p_mensaje     TEXT,
    OUT p_id_generado BIGINT
)
RETURNS RECORD
LANGUAGE plpgsql AS $$
DECLARE
    v_username_limpio  VARCHAR(50);
    v_email_limpio     VARCHAR(150);
    v_dni_limpio       VARCHAR(20);
BEGIN
    p_estado      := 'ERROR';
    p_mensaje     := NULL;
    p_id_generado := NULL;

    -- 1. Limpieza basica.
    v_username_limpio := lower(trim(p_username));
    v_email_limpio    := lower(trim(p_email));
    v_dni_limpio      := trim(p_dni);

    -- 2. Validaciones inline (antes vivian en fn_validar_credenciales).
    IF length(v_username_limpio) < 4 THEN
        p_estado  := 'ERROR_VALIDACION';
        p_mensaje := 'El username debe tener al menos 4 caracteres.';
        RETURN;
    END IF;

    IF v_email_limpio IS NULL OR v_email_limpio NOT LIKE '%@%.%' THEN
        p_estado  := 'ERROR_VALIDACION';
        p_mensaje := 'El email no tiene un formato valido.';
        RETURN;
    END IF;

    IF length(trim(p_nombre)) = 0 OR length(trim(p_apellido)) = 0 OR length(v_dni_limpio) = 0 THEN
        p_estado  := 'ERROR_VALIDACION';
        p_mensaje := 'El nombre, apellido y DNI son campos obligatorios y no pueden estar vacios.';
        RETURN;
    END IF;

    -- 3. Precondiciones de unicidad (mensajes amigables antes que el INSERT).
    IF EXISTS (SELECT 1 FROM usuario WHERE username = v_username_limpio) THEN
        p_estado  := 'ERROR_DUPLICADO';
        p_mensaje := format('El nombre de usuario "%s" ya se encuentra registrado.', v_username_limpio);
        RETURN;
    END IF;

    IF EXISTS (SELECT 1 FROM usuario WHERE email = v_email_limpio) THEN
        p_estado  := 'ERROR_DUPLICADO';
        p_mensaje := format('El correo electronico "%s" ya esta asociado a otra cuenta.', v_email_limpio);
        RETURN;
    END IF;

    IF EXISTS (SELECT 1 FROM cliente WHERE dni = v_dni_limpio) THEN
        p_estado  := 'ERROR_DUPLICADO';
        p_mensaje := format('El DNI %s ya pertenece a un cliente registrado en el sistema.', v_dni_limpio);
        RETURN;
    END IF;

    -- 4. Insercion atomica (BEGIN/EXCEPTION envuelve el procedure entero).
    INSERT INTO usuario (username, email, created_at)
    VALUES (v_username_limpio, v_email_limpio, CURRENT_TIMESTAMP)
    RETURNING id_usuario INTO p_id_generado;

    INSERT INTO cliente (id_usuario, nombre, apellido, dni, telefono, direccion)
    VALUES (p_id_generado, trim(p_nombre), trim(p_apellido), v_dni_limpio, trim(p_telefono), trim(p_direccion));

    p_estado  := 'OK';
    p_mensaje := format(
        'Cuenta de cliente creada para %s %s (usuario %s, DNI %s). '
        'Recordar vincular auth_user_id con la identidad de Supabase Auth.',
        trim(p_nombre), trim(p_apellido), v_username_limpio, v_dni_limpio
    );

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
        p_estado      := 'ERROR_VALIDACION';
        p_mensaje     := SQLERRM;
        p_id_generado := NULL;
    WHEN OTHERS THEN
        p_estado      := 'ERROR';
        p_mensaje     := SQLERRM;
        p_id_generado := NULL;
END;
$$;
