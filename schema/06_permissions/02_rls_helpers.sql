-- Funciones helper para evaluacion de Row Level Security.
--
-- Estrategia: leer el JWT directamente desde la GUC `request.jwt.claims` que
-- PostgREST setea en cada request via SET LOCAL. current_setting(name, true)
-- con missing_ok=true retorna NULL si la GUC no esta seteada, lo que nos
-- permite ejecutar el schema en postgres PURO (CI, docker compose sin
-- Supabase) sin referencias a `auth.uid()` ni al schema auth.
--
-- En postgres puro las funciones devuelven NULL/FALSE -> las policies de
-- cliente final filtran todas las filas, pero el rol postgres (apply.sh)
-- tiene BYPASSRLS implicito y sigue pudiendo seedear y operar libremente.
--
-- En Supabase Cloud: PostgREST setea la GUC con el JWT decodificado del
-- header Authorization -> estas funciones leen sub y app_metadata.role
-- tal como lo harian auth.uid() y auth.jwt().

-- Devuelve el UUID del usuario autenticado (claim 'sub' del JWT), o NULL.
CREATE OR REPLACE FUNCTION fn_auth_uid()
RETURNS UUID
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
    v_sub UUID;
BEGIN
    BEGIN
        v_sub := (current_setting('request.jwt.claims', true)::jsonb ->> 'sub')::UUID;
    EXCEPTION WHEN OTHERS THEN
        RETURN NULL;
    END;
    RETURN v_sub;
END;
$$;

-- Devuelve el id_cliente del usuario autenticado, o NULL si no hay sesion.
CREATE OR REPLACE FUNCTION fn_cliente_del_usuario()
RETURNS BIGINT
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_uid UUID := fn_auth_uid();
    v_id  BIGINT;
BEGIN
    IF v_uid IS NULL THEN
        RETURN NULL;
    END IF;
    SELECT id_cliente INTO v_id FROM public.cliente WHERE auth_user_id = v_uid LIMIT 1;
    RETURN v_id;
END;
$$;

-- Devuelve true si el JWT del request tiene claim role='staff' bajo
-- app_metadata. app_metadata no es modificable desde el frontend (solo
-- desde service_role) -> garantiza que el usuario no pueda elevarse via
-- signUp / updateUser.
CREATE OR REPLACE FUNCTION fn_es_staff()
RETURNS BOOLEAN
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
    v_claims jsonb;
BEGIN
    BEGIN
        v_claims := current_setting('request.jwt.claims', true)::jsonb;
    EXCEPTION WHEN OTHERS THEN
        RETURN FALSE;
    END;

    IF v_claims IS NULL THEN
        RETURN FALSE;
    END IF;

    RETURN COALESCE(v_claims -> 'app_metadata' ->> 'role' = 'staff', FALSE);
END;
$$;
