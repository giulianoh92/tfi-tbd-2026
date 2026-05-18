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

DO $$
DECLARE
    v_email      TEXT := 'staff@tbd-tfi.local';
    v_password   TEXT := 'tbd-staff-2026';
    v_user_id    UUID;
    v_app_meta   JSONB := '{"provider":"email","providers":["email"],"role":"staff"}'::jsonb;
    v_user_meta  JSONB := '{"nombre":"Staff","apellido":"TBD"}'::jsonb;
BEGIN
    -- Gate: schema auth (Supabase / GoTrue) presente.
    IF NOT EXISTS (SELECT 1 FROM pg_namespace WHERE nspname = 'auth') THEN
        RAISE NOTICE 'Schema auth no presente, salteando 05_staff_user.sql';
        RETURN;
    END IF;

    -- pgcrypto requerido para crypt() + gen_salt(). En Supabase viene preinstalado;
    -- en docker local lo crea apply.sh / 00_extensions.sql.
    IF NOT EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pgcrypto') THEN
        RAISE NOTICE 'pgcrypto no instalado, salteando 05_staff_user.sql';
        RETURN;
    END IF;

    SELECT id INTO v_user_id FROM auth.users WHERE email = v_email LIMIT 1;

    IF v_user_id IS NULL THEN
        v_user_id := gen_random_uuid();

        INSERT INTO auth.users (
            instance_id,
            id,
            aud,
            role,
            email,
            encrypted_password,
            email_confirmed_at,
            raw_app_meta_data,
            raw_user_meta_data,
            created_at,
            updated_at,
            confirmation_token,
            email_change,
            email_change_token_new,
            recovery_token
        ) VALUES (
            '00000000-0000-0000-0000-000000000000',
            v_user_id,
            'authenticated',
            'authenticated',
            v_email,
            crypt(v_password, gen_salt('bf')),
            NOW(),
            v_app_meta,
            v_user_meta,
            NOW(),
            NOW(),
            '',
            '',
            '',
            ''
        );

        INSERT INTO auth.identities (
            id,
            user_id,
            identity_data,
            provider,
            provider_id,
            last_sign_in_at,
            created_at,
            updated_at
        ) VALUES (
            gen_random_uuid(),
            v_user_id,
            jsonb_build_object('sub', v_user_id::text, 'email', v_email, 'email_verified', true),
            'email',
            v_user_id::text,
            NOW(),
            NOW(),
            NOW()
        );

        RAISE NOTICE 'Staff user creado: % (uid=%)', v_email, v_user_id;
    ELSE
        UPDATE auth.users
        SET encrypted_password = crypt(v_password, gen_salt('bf')),
            raw_app_meta_data  = COALESCE(raw_app_meta_data, '{}'::jsonb) || v_app_meta,
            raw_user_meta_data = COALESCE(raw_user_meta_data, '{}'::jsonb) || v_user_meta,
            email_confirmed_at = COALESCE(email_confirmed_at, NOW()),
            updated_at         = NOW()
        WHERE id = v_user_id;

        RAISE NOTICE 'Staff user actualizado: % (uid=%)', v_email, v_user_id;
    END IF;
END
$$;
