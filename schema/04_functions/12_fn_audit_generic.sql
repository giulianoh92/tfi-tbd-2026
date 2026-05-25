-- Funcion trigger generica de auditoria (R1).
--
-- Diseno: un unico trigger function reusable por todas las tablas auditadas.
-- Se adjunta via CREATE TRIGGER ... EXECUTE FUNCTION fn_audit_generic() en
-- schema/07_triggers/. Usa TG_OP y TG_TABLE_NAME para discriminar y
-- to_jsonb(OLD/NEW) para serializar el row completo sin acoplarse a las
-- columnas de cada tabla.
--
-- SECURITY DEFINER + search_path explicito: la funcion corre con privilegios
-- de su owner (postgres) para poder insertar en audit_log incluso cuando
-- el caller es authenticated y la policy bloquea INSERT manuales. Es la
-- forma idiomatica en Postgres de tener una unica via de escritura (el
-- trigger) y bloquear el resto.
--
-- Sprint 6 (B7.3) — SECURITY DEFINER intencional: el trigger inserta en
-- audit_log saltandose RLS. RLS sobre audit_log esta en USING(FALSE) para
-- escritura desde authenticated/anon, asi que la unica via valida es esta
-- function corriendo con privilegios del owner. Combinado con search_path
-- = public (evita function hijacking) y el trigger append-only de B2
-- (07_triggers/08_*), el log no es manipulable end-to-end.
--
-- Identidad del usuario logico: se lee `request.jwt.claims.sub` con fallback
-- a NULL via bloque EXCEPTION (postgres puro sin Supabase no tiene la GUC
-- seteada y current_setting lanzaria si missing_ok=false). El cast a UUID
-- tambien se protege.
--
-- id_registro: se resuelve consultando pg_index para obtener el primer
-- atributo de la PK de la tabla auditada y se extrae de OLD/NEW como TEXT.
-- Esto evita acoplarse a la convencion de nombres ("id_*") y soporta PKs
-- compuestas devolviendo solo la primera columna (suficiente para indexar
-- la fila en la UI).
CREATE OR REPLACE FUNCTION fn_audit_generic()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_usuario_app   UUID;
    v_pk_col        TEXT;
    v_id_registro   TEXT;
    v_old_jsonb     JSONB;
    v_new_jsonb     JSONB;
    v_tipo_op       CHAR(1);
    v_row_jsonb     JSONB;
BEGIN
    -- Capturar usuario logico desde el JWT con fallback seguro.
    BEGIN
        v_usuario_app := (current_setting('request.jwt.claims', true)::jsonb ->> 'sub')::UUID;
    EXCEPTION WHEN OTHERS THEN
        v_usuario_app := NULL;
    END;

    -- Mapear TG_OP y serializar OLD/NEW.
    IF TG_OP = 'INSERT' THEN
        v_tipo_op   := 'I';
        v_new_jsonb := to_jsonb(NEW);
        v_old_jsonb := NULL;
        v_row_jsonb := v_new_jsonb;
    ELSIF TG_OP = 'UPDATE' THEN
        v_tipo_op   := 'U';
        v_old_jsonb := to_jsonb(OLD);
        v_new_jsonb := to_jsonb(NEW);
        v_row_jsonb := v_new_jsonb;
    ELSIF TG_OP = 'DELETE' THEN
        v_tipo_op   := 'D';
        v_old_jsonb := to_jsonb(OLD);
        v_new_jsonb := NULL;
        v_row_jsonb := v_old_jsonb;
    END IF;

    -- Resolver primer atributo de la PK de la tabla auditada.
    SELECT a.attname
      INTO v_pk_col
      FROM pg_index i
      JOIN pg_attribute a ON a.attrelid = i.indrelid AND a.attnum = ANY (i.indkey)
     WHERE i.indrelid = (TG_TABLE_SCHEMA || '.' || TG_TABLE_NAME)::regclass
       AND i.indisprimary
     ORDER BY array_position(i.indkey::int[], a.attnum)
     LIMIT 1;

    IF v_pk_col IS NOT NULL THEN
        v_id_registro := v_row_jsonb ->> v_pk_col;
    END IF;

    -- usuario_db: rol Postgres que ejecuto la operacion, con preferencia
    -- por el JWT role claim sobre el session_user crudo.
    --
    -- Por que NO usamos solamente session_user:
    --   Supabase abre todas las conexiones del pool PostgREST con el rol
    --   `authenticator` y luego hace `SET ROLE <jwt.role>` por cada request
    --   (authenticated/anon/service_role). `session_user` siempre devuelve
    --   el rol original de la conexion = `authenticator`, perdiendo la
    --   info del rol efectivo asignado segun el JWT.
    --
    -- Por que NO usamos solamente current_user:
    --   Esta function corre con SECURITY DEFINER, por lo que `current_user`
    --   queda fijado al owner = `postgres`. Eso rompia la doble identidad.
    --
    -- Solucion: leer la GUC `request.jwt.claim.role` que PostgREST setea
    -- por request. Es request-scope, no role-scope, asi que sobrevive
    -- el SECURITY DEFINER. Si no hay JWT (apply.sh, pg_cron, psql directo
    -- del profesor como quique), caemos a session_user que captura el
    -- rol real.
    --
    -- Doble identidad documentada en TFI:
    --   usuario_db  = rol Postgres aplicado (authenticated/anon/quique/postgres)
    --   usuario_app = sub del JWT = UUID del usuario logico en auth.users
    -- TRIPLE IDENTIDAD (ver header de schema/01_tables/18_audit_log.sql):
    --
    --   usuario_db -> rol Postgres EFECTIVO (manipulable, lleva semantica
    --                 de RLS/GRANTs aplicada). Lo derivamos del JWT.role
    --                 con fallback a session_user para sesiones sin JWT.
    --
    --   rol_sesion -> session_user crudo, NO falsificable salvo re-login.
    --                 En Supabase via PostgREST es siempre 'authenticator'
    --                 (porque el pool abre la conexion con ese rol antes
    --                 de hacer SET ROLE por request). En psql directo del
    --                 profesor o cron job: quique / postgres / etc.
    --                 Inmune a SET ROLE y a manipulacion de GUCs del JWT.
    --
    --   usuario_app -> JWT.sub = identidad humana, ya capturada arriba.
    --
    -- La combinacion (rol_sesion, usuario_db) permite detectar
    -- inconsistencias: ej. rol_sesion='quique' + usuario_db='authenticated'
    -- delata un SET ROLE manual sospechoso. Sin la columna rol_sesion esta
    -- deteccion seria imposible.
    INSERT INTO audit_log (
        tabla,
        id_registro,
        tipo_op,
        usuario_db,
        rol_sesion,
        usuario_app,
        valores_anteriores,
        valores_nuevos
    )
    VALUES (
        TG_TABLE_NAME,
        v_id_registro,
        v_tipo_op,
        COALESCE(
            NULLIF(current_setting('request.jwt.claim.role', true), ''),
            NULLIF(
                (NULLIF(current_setting('request.jwt.claims', true), '')::jsonb ->> 'role'),
                ''
            ),
            session_user
        ),
        session_user,
        v_usuario_app,
        v_old_jsonb,
        v_new_jsonb
    );

    -- Trigger AFTER -> el valor de retorno se ignora, pero por convencion
    -- devolvemos NEW (o OLD en DELETE) para no romper triggers en cadena.
    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    END IF;
    RETURN NEW;
END;
$$;
