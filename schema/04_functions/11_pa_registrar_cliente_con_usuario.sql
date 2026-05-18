
CREATE OR REPLACE PROCEDURE pa_registrar_cliente_con_usuario(
    p_username VARCHAR,
    p_password_hash VARCHAR,
    p_email VARCHAR,
    p_nombre VARCHAR,
    p_apellido VARCHAR,
    p_dni VARCHAR,
    p_telefono VARCHAR,
    p_direccion VARCHAR
)
LANGUAGE plpgsql AS $$
DECLARE
    v_username_limpio VARCHAR(50);
    v_email_limpio VARCHAR(150);
    v_dni_limpio VARCHAR(20);
    v_id_usuario_generado BIGINT;
BEGIN

    -- 1. ESTANDARIZACIÓN Y LIMPIEZA DE DATOS CRÍTICOS
    v_username_limpio := lower(trim(p_username));
    v_email_limpio    := lower(trim(p_email));
    v_dni_limpio      := trim(p_dni);


    -- 2. REUTILIZACIÓN DE CÓDIGO: VALIDACIÓN DE FORMATOS (Capa de Software)
    -- Invocamos la función que ya creaste. Si algo falla, lanza EXCEPTION y corta acá.
    PERFORM fn_validar_credenciales(v_username_limpio, v_email_limpio, p_password_hash);

    -- Validaciones de strings vacíos obligatorios para la tabla cliente
    IF length(trim(p_nombre)) = 0 OR length(trim(p_apellido)) = 0 OR length(v_dni_limpio) = 0 THEN
        RAISE EXCEPTION 'CONTROL DE INTEGRIDAD: El nombre, apellido y DNI son campos obligatorios y no pueden estar vacíos.';
    END IF;

 
    -- 3. CONTROL DE PRECONDICIONES (INTEGRIDAD CONTRA REGISTROS EXISTENTES)    
    -- Verificar duplicados en la tabla USUARIO
    IF EXISTS (SELECT 1 FROM usuario WHERE username = v_username_limpio) THEN
        RAISE EXCEPTION 'ERROR DE DUPLICADO: El nombre de usuario "%" ya se encuentra registrado.', v_username_limpio;
    END IF;

    IF EXISTS (SELECT 1 FROM usuario WHERE email = v_email_limpio) THEN
        RAISE EXCEPTION 'ERROR DE DUPLICADO: El correo electrónico "%" ya está asociado a otra cuenta.', v_email_limpio;
    END IF;

    -- Verificar duplicados en la tabla CLIENTE
    IF EXISTS (SELECT 1 FROM cliente WHERE dni = v_dni_limpio) THEN
        RAISE EXCEPTION 'ERROR DE DUPLICADO: El DNI % ya pertenece a un cliente registrado en el sistema.', v_dni_limpio;
    END IF;

 
    -- 4. INSERCIÓN OPERATIVA (ATOMICIDAD DE TRANSACCIÓN)  
    -- Paso A: Crear las credenciales de acceso en la tabla usuario
    INSERT INTO usuario (username, password_hash, email, created_at)
    VALUES (v_username_limpio, p_password_hash, v_email_limpio, CURRENT_TIMESTAMP)
    RETURNING id_usuario INTO v_id_usuario_generado;

    -- Paso B: Crear el perfil del cliente vinculándolo al usuario mediante la relación 1-1 (id_usuario UNIQUE)
    INSERT INTO cliente (id_usuario, nombre, apellido, dni, telefono, direccion)
    VALUES (v_id_usuario_generado, trim(p_nombre), trim(p_apellido), v_dni_limpio, trim(p_telefono), trim(p_direccion));

    -- Mensaje de confirmación en la consola de PostgreSQL
    RAISE NOTICE 'PROCESO EXITOSO: Cuenta de cliente creada para % % (Usuario: %, DNI: %).', 
                 trim(p_nombre), trim(p_apellido), v_username_limpio, v_dni_limpio;
END;
$$;