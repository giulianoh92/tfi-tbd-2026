-- pgcrypto provee gen_random_uuid() (RFC 4122 v4). No se usa uuid-ossp:
-- duplicaba funcionalidad y sumaba superficie de ataque sin uso real en
-- el proyecto (no hay un solo call a uuid_generate_* en el schema).
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- btree_gist habilita combinar tipos de igualdad (BIGINT) con rangos
-- (tsrange) en una misma EXCLUDE constraint via indice GiST. Es la unica
-- forma idiomatica en Postgres de garantizar no-superposicion temporal a
-- nivel de indice (no de trigger). Postgres-only: en Oracle el equivalente
-- se hace con triggers + locking explicito, mucho mas pesado y propenso a
-- race conditions entre el SELECT y el INSERT.
CREATE EXTENSION IF NOT EXISTS btree_gist;

-- pg_cron para tareas programadas (deteccion de devoluciones vencidas, R9).
-- La extension viene precargada en supabase/postgres y en Supabase Cloud
-- (managed), pero requiere `shared_preload_libraries = 'pg_cron'` en el
-- postgresql.conf del cluster.
--
-- Por defecto pg_cron se instala solo en la base de datos `postgres`. Si la
-- base del proyecto se llama distinto (ej: tbd_tfi en docker local), el
-- CREATE EXTENSION puede fallar con "pg_cron can only be loaded via
-- shared_preload_libraries" o con un error de permisos. Envolvemos en un
-- bloque DO con EXCEPTION para que la aplicacion del esquema no falle cuando
-- la extension no esta disponible (entornos donde el administrador no la
-- habilito); en ese caso el trabajo de deteccion de devoluciones vencidas no
-- se registra automaticamente, pero el resto del esquema se aplica con
-- normalidad.
DO $$
BEGIN
    CREATE EXTENSION IF NOT EXISTS pg_cron;
    RAISE NOTICE 'Extension pg_cron instalada correctamente.';
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'No se pudo instalar pg_cron (%). La tarea de deteccion de '
                 'devoluciones vencidas no se registra automaticamente. '
                 'En produccion (Supabase gestionado) la extension esta '
                 'precargada y este bloque se ejecuta sin error.', SQLERRM;
END
$$;
