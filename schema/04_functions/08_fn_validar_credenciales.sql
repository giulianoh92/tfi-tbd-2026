-- FUNCIÓN: fn_validar_credenciales
-- OBJETIVO: Encapsular y reutilizar las reglas de formato de usuario, email
--           y contraseñas en procesos de Alta, Modificación y Autenticación.

CREATE OR REPLACE FUNCTION fn_validar_credenciales(
    p_username VARCHAR,
    p_email VARCHAR,
    p_password_hash VARCHAR
)
RETURNS BOOLEAN AS $$
BEGIN
    -- 1. Validar formato del Nombre de Usuario (si se proporciona)
    IF p_username IS NOT NULL THEN
        -- Controlar longitud mínima y que no sea solo espacios
        IF length(trim(p_username)) < 4 OR trim(p_username) = '' THEN
            RAISE EXCEPTION 'REGLA DE FORMATO: El nombre de usuario debe tener al menos 4 caracteres y no puede estar vacío.';
        END IF;
    END IF;

    -- 2. Validar formato del Correo Electrónico usando expresiones regulares (si se proporciona)
    IF p_email IS NOT NULL THEN
        -- Patrón estándar para correos electrónicos (ejemplo@dominio.com)
        IF p_email !~* '^[A-Za-z0-9._%-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$' THEN
            RAISE EXCEPTION 'REGLA DE FORMATO: El correo electrónico "%" no cuenta con un formato válido.', p_email;
        END IF;
    END IF;

    -- 3. Validar consistencia de la Contraseña / Hash (si se proporciona)
    IF p_password_hash IS NOT NULL THEN
        IF length(trim(p_password_hash)) = 0 THEN
            RAISE EXCEPTION 'REGLA DE FORMATO: La contraseña o su firma hash no pueden ser una cadena vacía.';
        END IF;
    END IF;

    -- Si pasó todos los filtros de formato, retorna verdadero
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;
