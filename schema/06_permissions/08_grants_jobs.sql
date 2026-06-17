-- Permisos restringidos para procedures de tareas internas.
--
-- pa_detectar_devoluciones_vencidas() NO es una API publica: solo la invoca
-- pg_cron como rol postgres. El permiso general de 04_rls_policies.sql
-- (`GRANT EXECUTE ON ALL PROCEDURES IN SCHEMA public TO authenticated`)
-- abriria la posibilidad de que un cliente con JWT autenticado pudiera
-- lanzar la tarea manualmente desde PostgREST y, dado que el procedure es
-- SECURITY DEFINER, ejecutarlo con privilegios elevados sobre
-- devolucion_vencida y consumir recursos de la tarea programada.
--
-- Se revoca explicitamente y se otorga solo a postgres y service_role (rol
-- interno de Supabase sin RLS que usan las Edge Functions y scripts de
-- administracion). authenticated/anon NO pueden llamarlo.
--
-- Bloque DO para que no falle si los roles de Supabase no existen
-- (entornos Postgres puros sin la infraestructura Supabase).

DO $$
BEGIN
    -- Revocacion generica sobre authenticated y PUBLIC.
    EXECUTE 'REVOKE EXECUTE ON PROCEDURE pa_detectar_devoluciones_vencidas() FROM PUBLIC';
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'authenticated') THEN
        EXECUTE 'REVOKE EXECUTE ON PROCEDURE pa_detectar_devoluciones_vencidas() FROM authenticated';
    END IF;
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'anon') THEN
        EXECUTE 'REVOKE EXECUTE ON PROCEDURE pa_detectar_devoluciones_vencidas() FROM anon';
    END IF;

    -- Permisos minimos: postgres (propietario, lo tiene por defecto pero se
    -- declara explicitamente para legibilidad en \dp) y service_role.
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'service_role') THEN
        EXECUTE 'GRANT EXECUTE ON PROCEDURE pa_detectar_devoluciones_vencidas() TO service_role';
    END IF;

    -- Identico tratamiento para pa_expirar_reservas_vencidas (R12): tarea
    -- interna invocada solo por pg_cron. Es SECURITY DEFINER y modifica en
    -- lote reserva + garantia_reserva, por lo que NO debe quedar expuesta a
    -- authenticated/anon via PostgREST.
    EXECUTE 'REVOKE EXECUTE ON PROCEDURE pa_expirar_reservas_vencidas() FROM PUBLIC';
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'authenticated') THEN
        EXECUTE 'REVOKE EXECUTE ON PROCEDURE pa_expirar_reservas_vencidas() FROM authenticated';
    END IF;
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'anon') THEN
        EXECUTE 'REVOKE EXECUTE ON PROCEDURE pa_expirar_reservas_vencidas() FROM anon';
    END IF;
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'service_role') THEN
        EXECUTE 'GRANT EXECUTE ON PROCEDURE pa_expirar_reservas_vencidas() TO service_role';
    END IF;

    -- Identico tratamiento para pa_cerrar_facturacion_mensual (R13): tarea
    -- interna de cierre contable invocada solo por pg_cron. SECURITY DEFINER y
    -- escribe en resumen_mensual_sucursal, por lo que NO debe quedar expuesta a
    -- authenticated/anon via PostgREST.
    EXECUTE 'REVOKE EXECUTE ON PROCEDURE pa_cerrar_facturacion_mensual() FROM PUBLIC';
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'authenticated') THEN
        EXECUTE 'REVOKE EXECUTE ON PROCEDURE pa_cerrar_facturacion_mensual() FROM authenticated';
    END IF;
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'anon') THEN
        EXECUTE 'REVOKE EXECUTE ON PROCEDURE pa_cerrar_facturacion_mensual() FROM anon';
    END IF;
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'service_role') THEN
        EXECUTE 'GRANT EXECUTE ON PROCEDURE pa_cerrar_facturacion_mensual() TO service_role';
    END IF;
END
$$;
