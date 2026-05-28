-- Roles que Supabase provee por defecto: anon, authenticated, service_role.
-- En entornos sin Supabase (CI postgres efimero, docker compose puro) no
-- existen y las policies con `TO authenticated` fallarian al crearse.
--
-- Se crean como NOLOGIN/NOINHERIT (PostgREST cambia de rol via SET LOCAL ROLE,
-- no via conexion directa). service_role lleva BYPASSRLS para reflejar el
-- privilegio que ya tiene en Supabase administrado.
--
-- Idempotente: consulta pg_roles antes de CREATE ROLE.

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'anon') THEN
        CREATE ROLE anon NOLOGIN NOINHERIT;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'authenticated') THEN
        CREATE ROLE authenticated NOLOGIN NOINHERIT;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'service_role') THEN
        CREATE ROLE service_role NOLOGIN NOINHERIT BYPASSRLS;
    END IF;
END
$$;
