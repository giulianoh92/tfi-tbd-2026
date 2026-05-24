-- Usuario staff para el panel /admin del frontend.
--
-- Crea un user de Supabase Auth (auth.users) con app_metadata.role='staff'.
-- El claim viaja en el JWT que PostgREST inyecta en request.jwt.claims, y
-- las policies de RLS lo leen via fn_es_staff() (ver 02_rls_helpers.sql).
--
-- Por que app_metadata y no user_metadata:
--   * user_metadata es editable por el propio user (updateUser desde el
--     frontend) -> trivial elevarse a staff.
--   * app_metadata solo es modificable por service_role / desde el server.
--
-- Idempotente:
--   * Se ejecuta solo si existe el schema 'auth' (entorno Supabase). En
--     postgres puro (CI, docker compose sin GoTrue) se saltea silenciosamente.
--   * Si el user ya existe (match por email) actualiza password + metadata;
--     si no existe inserta auth.users + auth.identities.
--   * El trigger fn_handle_new_auth_user encadena la fila en public.cliente.
--
-- Credenciales por defecto (cambiar antes de compartir):
--   email:    staff@tbd-tfi.local
--   password: tbd-staff-2026

-- Deploy fix: la imagen supabase/postgres:15.1.0.147 trae una version vieja
-- de auth.users (sin email_confirmed_at / email_change_token_new). Hacemos el
-- INSERT y UPDATE dinamicos para que el mismo archivo funcione en:
--   * Supabase managed (auth moderno)            -> usa email_confirmed_at
--   * supabase/postgres viejo                    -> usa confirmed_at
--   * Postgres puro / CI sin schema auth         -> skipea
DO $$
DECLARE
    v_email          TEXT := 'staff@tbd-tfi.local';
    v_password       TEXT := 'tbd-staff-2026';
    v_user_id        UUID;
    v_app_meta       JSONB := '{"provider":"email","providers":["email"],"role":"staff"}'::jsonb;
    v_user_meta      JSONB := '{"nombre":"Staff","apellido":"TBD"}'::jsonb;
    v_confirm_col    TEXT;
    v_change_tok_col TEXT;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_namespace WHERE nspname = 'auth') THEN
        RAISE NOTICE 'Schema auth no presente, salteando 05_staff_user.sql';
        RETURN;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pgcrypto') THEN
        RAISE NOTICE 'pgcrypto no instalado, salteando 05_staff_user.sql';
        RETURN;
    END IF;

    -- Resolver nombres de columna segun version de auth.users.
    SELECT CASE
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns
            WHERE table_schema='auth' AND table_name='users' AND column_name='email_confirmed_at'
        ) THEN 'email_confirmed_at'
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns
            WHERE table_schema='auth' AND table_name='users' AND column_name='confirmed_at'
        ) THEN 'confirmed_at'
        ELSE NULL
    END INTO v_confirm_col;

    SELECT CASE
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns
            WHERE table_schema='auth' AND table_name='users' AND column_name='email_change_token_new'
        ) THEN 'email_change_token_new'
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns
            WHERE table_schema='auth' AND table_name='users' AND column_name='email_change_token'
        ) THEN 'email_change_token'
        ELSE NULL
    END INTO v_change_tok_col;

    SELECT id INTO v_user_id FROM auth.users WHERE email = v_email LIMIT 1;

    IF v_user_id IS NULL THEN
        v_user_id := gen_random_uuid();

        -- Columnas obligatorias en TODAS las versiones de auth.users.
        -- Columnas opcionales (timestamp de confirmacion y token de cambio de email)
        -- se inyectan via concatenacion si existen en esta version.
        EXECUTE
            'INSERT INTO auth.users ('
            ||  'instance_id, id, aud, role, email, encrypted_password,'
            ||  ' raw_app_meta_data, raw_user_meta_data, created_at, updated_at,'
            ||  ' confirmation_token, email_change, recovery_token'
            ||  CASE WHEN v_confirm_col    IS NOT NULL THEN ', ' || quote_ident(v_confirm_col)    ELSE '' END
            ||  CASE WHEN v_change_tok_col IS NOT NULL THEN ', ' || quote_ident(v_change_tok_col) ELSE '' END
            || ') VALUES ('
            ||  '$1, $2, $3, $4, $5, $6, $7, $8, $9, $10, '''', '''', '''''
            ||  CASE WHEN v_confirm_col    IS NOT NULL THEN ', NOW()' ELSE '' END
            ||  CASE WHEN v_change_tok_col IS NOT NULL THEN ', '''''  ELSE '' END
            || ')'
        USING
            '00000000-0000-0000-0000-000000000000'::uuid,
            v_user_id,
            'authenticated',
            'authenticated',
            v_email,
            crypt(v_password, gen_salt('bf')),
            v_app_meta,
            v_user_meta,
            NOW(),
            NOW();

        -- auth.identities solo existe en versiones recientes de GoTrue.
        -- En la imagen vieja supabase/postgres:15.1.0.147 no existe; el login
        -- igual funciona porque la sesion se valida contra auth.users.
        IF EXISTS (
            SELECT 1 FROM information_schema.tables
            WHERE table_schema='auth' AND table_name='identities'
        ) THEN
            INSERT INTO auth.identities (
                id, user_id, identity_data, provider, provider_id,
                last_sign_in_at, created_at, updated_at
            ) VALUES (
                gen_random_uuid(),
                v_user_id,
                jsonb_build_object('sub', v_user_id::text, 'email', v_email, 'email_verified', true),
                'email',
                v_user_id::text,
                NOW(), NOW(), NOW()
            );
        END IF;

        RAISE NOTICE 'Staff user creado: % (uid=%)', v_email, v_user_id;
    ELSE
        EXECUTE format(
            'UPDATE auth.users '
            || 'SET encrypted_password = $1,'
            || '    raw_app_meta_data  = COALESCE(raw_app_meta_data, ''{}''::jsonb) || $2,'
            || '    raw_user_meta_data = COALESCE(raw_user_meta_data, ''{}''::jsonb) || $3,'
            || '    updated_at         = NOW()'
            || CASE WHEN v_confirm_col IS NOT NULL
                    THEN ', ' || quote_ident(v_confirm_col) || ' = COALESCE(' || quote_ident(v_confirm_col) || ', NOW())'
                    ELSE '' END
            || ' WHERE id = $4'
        )
        USING
            crypt(v_password, gen_salt('bf')),
            v_app_meta,
            v_user_meta,
            v_user_id;

        RAISE NOTICE 'Staff user actualizado: % (uid=%)', v_email, v_user_id;
    END IF;
END
$$;
