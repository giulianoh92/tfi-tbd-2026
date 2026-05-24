CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Sprint 4 (R9): pg_cron para jobs programados (deteccion de devoluciones
-- vencidas). La extension viene precargada en supabase/postgres y en
-- Supabase Cloud (managed), pero requiere `shared_preload_libraries =
-- 'pg_cron'` en el postgresql.conf del cluster.
--
-- Por defecto pg_cron se instala solo en la database `postgres`. Si la DB
-- del proyecto se llama distinto (ej: tbd_tfi en docker local), el CREATE
-- EXTENSION puede fallar con "pg_cron can only be loaded via
-- shared_preload_libraries" o con un error de permisos. Envolvemos en un
-- bloque DO con EXCEPTION para que `apply.sh` no falle cuando la extension
-- no esta disponible (entornos donde el sysadmin no la habilito); en ese
-- caso el job de Sprint 4 no se schedulea pero el resto del schema se
-- aplica normalmente.
DO $$
BEGIN
    CREATE EXTENSION IF NOT EXISTS pg_cron;
    RAISE NOTICE 'Extension pg_cron instalada correctamente.';
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'No se pudo instalar pg_cron (%). El job de deteccion de '
                 'devoluciones vencidas no se schedulea automaticamente. '
                 'En produccion (Supabase managed) la extension esta '
                 'precargada y este bloque pasa sin error.', SQLERRM;
END
$$;
