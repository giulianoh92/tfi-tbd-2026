-- Funciones helper para evaluacion de Row Level Security.
--
-- auth.uid() y auth.jwt() son provistas por Supabase GoTrue cuando PostgREST
-- ejecuta el SET LOCAL request.jwt.claims por request. Estas funciones
-- existen en el schema auth solo cuando se corre dentro del stack Supabase
-- (CLI local o cloud). Para entornos sin Supabase, las policies devuelven
-- false (auth.uid() retorna NULL) y la fila queda invisible/no-modificable
-- desde clientes web; el rol postgres y service_role siguen pudiendo todo.
--
-- Marcadas STABLE: el resultado depende del JWT pero no cambia dentro de
-- una misma transaccion -> el planner puede cachear.

-- Devuelve el id_cliente del usuario autenticado, o NULL si no hay sesion.
CREATE OR REPLACE FUNCTION fn_cliente_del_usuario()
RETURNS BIGINT
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT id_cliente
    FROM   public.cliente
    WHERE  auth_user_id = (SELECT auth.uid())
    LIMIT  1;
$$;

-- Devuelve true si el JWT del request tiene claim role='staff'.
-- El claim se setea desde Supabase Studio -> Authentication -> Users -> Edit
-- (raw_app_meta_data: {"role": "staff"}). app_metadata no es modificable
-- desde el frontend, solo desde service_role: garantiza que el usuario no
-- pueda elevarse el rol via signUp.
CREATE OR REPLACE FUNCTION fn_es_staff()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
AS $$
    SELECT COALESCE(
        (auth.jwt() -> 'app_metadata' ->> 'role') = 'staff',
        FALSE
    );
$$;
