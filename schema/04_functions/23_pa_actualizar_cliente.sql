-- Procedure: pa_actualizar_cliente (R3, R4, R5)
-- Permite al cliente autenticado actualizar sus propios datos personales
-- (nombre, apellido, dni, telefono, direccion). No recibe p_id_cliente: la
-- fila objetivo se resuelve desde el JWT (auth.uid()) via fn_cliente_del_usuario.
-- Asi se impide que un cliente edite la fila de otro aunque conozca el ID.
--
-- Diseno transaccional (R2): cuerpo envuelto en BEGIN ... EXCEPTION WHEN ...
-- THEN ... END, con OUT parameters estandarizados (p_estado, p_mensaje)
-- segun el contrato R4.
--
-- R11: declarada como FUNCTION (no PROCEDURE) para que PostgREST la exponga
-- via /rest/v1/rpc.
CREATE OR REPLACE FUNCTION pa_actualizar_cliente(
    p_nombre     VARCHAR(100),
    p_apellido   VARCHAR(100),
    p_dni        VARCHAR(20),
    p_telefono   VARCHAR(30) DEFAULT NULL,
    p_direccion  VARCHAR(200) DEFAULT NULL,
    OUT p_estado    TEXT,
    OUT p_mensaje   TEXT
)
RETURNS RECORD
LANGUAGE plpgsql
AS $$
DECLARE
    v_id_cliente BIGINT;
    v_dni_limpio VARCHAR(20);
BEGIN
    p_estado  := 'ERROR';
    p_mensaje := NULL;

    -- 1) Resolver id_cliente desde el JWT. fn_cliente_del_usuario hace el
    --    lookup contra cliente.auth_user_id = auth.uid(). Si no hay sesion
    --    o la fila no existe, devuelve NULL.
    v_id_cliente := fn_cliente_del_usuario();

    IF v_id_cliente IS NULL THEN
        p_estado  := 'ERROR_REFERENCIAL';
        p_mensaje := 'No se encontro un cliente vinculado a la sesion actual.';
        RETURN;
    END IF;

    -- 2) Validaciones de formato. La regla del DNI replica la del signup:
    --    entre 7 y 9 digitos sin separadores. Se aceptan espacios y los
    --    descartamos antes de chequear.
    IF p_nombre IS NULL OR length(trim(p_nombre)) = 0 THEN
        p_estado  := 'ERROR_VALIDACION';
        p_mensaje := 'El nombre es obligatorio.';
        RETURN;
    END IF;

    IF p_apellido IS NULL OR length(trim(p_apellido)) = 0 THEN
        p_estado  := 'ERROR_VALIDACION';
        p_mensaje := 'El apellido es obligatorio.';
        RETURN;
    END IF;

    v_dni_limpio := regexp_replace(COALESCE(p_dni, ''), '\s+', '', 'g');
    IF v_dni_limpio !~ '^\d{7,9}$' THEN
        p_estado  := 'ERROR_VALIDACION';
        p_mensaje := 'El DNI debe tener entre 7 y 9 digitos.';
        RETURN;
    END IF;

    -- 3) UPDATE. El trigger trg_audit_cliente captura los valores anteriores
    --    y nuevos en audit_log automaticamente.
    UPDATE cliente
       SET nombre    = trim(p_nombre),
           apellido  = trim(p_apellido),
           dni       = v_dni_limpio,
           telefono  = NULLIF(trim(COALESCE(p_telefono, '')), ''),
           direccion = NULLIF(trim(COALESCE(p_direccion, '')), '')
     WHERE id_cliente = v_id_cliente;

    p_estado  := 'OK';
    p_mensaje := 'Datos personales actualizados correctamente.';

EXCEPTION
    WHEN unique_violation THEN
        -- DNI tiene UNIQUE constraint: si otro cliente ya tiene ese DNI,
        -- caemos aca.
        p_estado  := 'ERROR_DUPLICADO';
        p_mensaje := 'Ya existe otro cliente registrado con ese DNI.';
    WHEN check_violation THEN
        p_estado  := 'ERROR_VALIDACION';
        p_mensaje := SQLERRM;
    WHEN OTHERS THEN
        p_estado  := 'ERROR';
        p_mensaje := SQLERRM;
END;
$$;
