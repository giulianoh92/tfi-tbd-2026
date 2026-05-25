-- Grants restringidos para procedures de jobs internos.
--
-- pa_detectar_devoluciones_vencidas() NO es API publica: solo lo invoca
-- pg_cron como rol postgres. El GRANT EXECUTE wildcard de 04_rls_policies.sql
-- (`GRANT EXECUTE ON ALL PROCEDURES IN SCHEMA public TO authenticated`)
-- abriria una puerta para que un cliente con JWT autenticado pudiera
-- lanzar el job manualmente desde PostgREST y, dado que el procedure es
-- SECURITY DEFINER, ejecutarlo con privilegios escalados sobre
-- devolucion_vencida y consumir recursos del cron.
--
-- Aca lo revocamos explicitamente y lo concedemos solo a postgres y
-- service_role (rol interno de Supabase sin RLS que usan los Edge
-- Functions y scripts admin). authenticated/anon NO pueden llamarlo.
--
-- DO block para que no falle si los roles de Supabase no existen
-- (entornos postgres puros sin la infra Supabase).

DO $$
BEGIN
    -- Revoke generico sobre authenticated y PUBLIC.
    EXECUTE 'REVOKE EXECUTE ON PROCEDURE pa_detectar_devoluciones_vencidas() FROM PUBLIC';
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'authenticated') THEN
        EXECUTE 'REVOKE EXECUTE ON PROCEDURE pa_detectar_devoluciones_vencidas() FROM authenticated';
    END IF;
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'anon') THEN
        EXECUTE 'REVOKE EXECUTE ON PROCEDURE pa_detectar_devoluciones_vencidas() FROM anon';
    END IF;

    -- Grants minimos: postgres (owner, lo tiene por default pero lo
    -- declaramos explicitamente para legibilidad en \dp) y service_role.
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'service_role') THEN
        EXECUTE 'GRANT EXECUTE ON PROCEDURE pa_detectar_devoluciones_vencidas() TO service_role';
    END IF;
END
$$;
