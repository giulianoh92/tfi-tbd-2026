-- pa_registrar_cliente_con_usuario(...) — Alta atomica de credenciales
-- (tabla usuario) + perfil de cliente (tabla cliente). Reusa
-- fn_validar_credenciales para reglas de formato (username, email,
-- password_hash).
--
-- Sprint 5 (R2) — refactor:
--   * Cuerpo envuelto en BEGIN ... EXCEPTION WHEN ... THEN ... END.
--   * Agregados OUT p_estado / p_mensaje y OUT p_id_generado (id_usuario
--     creado). Contrato estandar JUSTIFICACION.md §R4.
--
-- Cambio de firma -> DROP PROCEDURE previo con la firma vieja explicita.

DROP PROCEDURE IF EXISTS pa_registrar_cliente_con_usuario(
    VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR
) CASCADE;

CREATE OR REPLACE PROCEDURE pa_registrar_cliente_con_usuario(
    IN  p_username      VARCHAR,
    IN  p_password_hash VARCHAR,
    IN  p_email         VARCHAR,
    IN  p_nombre        VARCHAR,
    IN  p_apellido      VARCHAR,
    IN  p_dni           VARCHAR,
    IN  p_telefono      VARCHAR,
    IN  p_direccion     VARCHAR,
    OUT p_estado        TEXT,
    OUT p_mensaje       TEXT,
    OUT p_id_generado   BIGINT
)
LANGUAGE plpgsql AS $$
DECLARE
    v_username_limpio     VARCHAR(50);
    v_email_limpio        VARCHAR(150);
    v_dni_limpio          VARCHAR(20);
BEGIN
    p_estado      := 'ERROR';
    p_mensaje     := NULL;
    p_id_generado := NULL;

    -- 1. ESTANDARIZACION Y LIMPIEZA DE DATOS CRITICOS
    v_username_limpio := lower(trim(p_username));
    v_email_limpio    := lower(trim(p_email));
    v_dni_limpio      := trim(p_dni);

    -- 2. REUTILIZACION DE CODIGO: VALIDACION DE FORMATOS (Capa de Software)
    -- fn_validar_credenciales lanza EXCEPTION si algun formato es invalido;
    -- la captura en el bloque EXCEPTION OTHERS la mapea a ERROR_VALIDACION
    -- via SQLERRM (no expone SQLSTATE especifico).
    PERFORM fn_validar_credenciales(v_username_limpio, v_email_limpio, p_password_hash);

    -- Validaciones de strings vacios obligatorios para la tabla cliente
    IF length(trim(p_nombre)) = 0 OR length(trim(p_apellido)) = 0 OR length(v_dni_limpio) = 0 THEN
        p_estado  := 'ERROR_VALIDACION';
        p_mensaje := 'El nombre, apellido y DNI son campos obligatorios y no pueden estar vacios.';
        RETURN;
    END IF;

    -- 3. CONTROL DE PRECONDICIONES (INTEGRIDAD CONTRA REGISTROS EXISTENTES)
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

    -- 4. INSERCION OPERATIVA (ATOMICIDAD DE TRANSACCION)
    -- Paso A: Crear las credenciales de acceso en la tabla usuario
    INSERT INTO usuario (username, password_hash, email, created_at)
    VALUES (v_username_limpio, p_password_hash, v_email_limpio, CURRENT_TIMESTAMP)
    RETURNING id_usuario INTO p_id_generado;

    -- Paso B: Crear el perfil del cliente vinculandolo al usuario mediante la relacion 1-1 (id_usuario UNIQUE)
    INSERT INTO cliente (id_usuario, nombre, apellido, dni, telefono, direccion)
    VALUES (p_id_generado, trim(p_nombre), trim(p_apellido), v_dni_limpio, trim(p_telefono), trim(p_direccion));

    p_estado  := 'OK';
    p_mensaje := format(
        'Cuenta de cliente creada para %s %s (usuario %s, DNI %s).',
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
        -- fn_validar_credenciales lanza RAISE EXCEPTION sin SQLSTATE
        -- especifico; cae aqui. Las reglas de formato son de validacion,
        -- asi que mapeamos su mensaje a ERROR_VALIDACION para que el
        -- frontend lo trate como error de negocio.
        IF SQLERRM ILIKE '%FORMATO%' OR SQLERRM ILIKE '%formato%' THEN
            p_estado := 'ERROR_VALIDACION';
        ELSE
            p_estado := 'ERROR';
        END IF;
        p_mensaje     := SQLERRM;
        p_id_generado := NULL;
END;
$$;
