-- Programacion de tareas con pg_cron (R9).
--
-- Estructura defensiva:
--   1) Solo intenta programar si la extension pg_cron esta presente
--      (verifica pg_extension). En entornos donde no se habilito
--      shared_preload_libraries, el bloque pasa sin ruido y el resto del
--      esquema se aplica con normalidad.
--   2) Si pg_cron esta disponible, verifica que la tarea no exista todavia
--      (consulta cron.job por jobname) y recien ahi llama cron.schedule().
--      Esto hace al script idempotente frente a re-aplicaciones.
--   3) Todo el bloque va en DO + EXCEPTION OTHERS para que un cluster sin
--      pg_cron habilitado o sin permisos para programar tareas NO rompa el
--      despliegue completo (Postgres puro de CI, o proveedores gestionados que
--      restringen cron a roles especiales). Mantiene el despliegue funcional
--      aun cuando pg_cron no esta disponible.
--
-- Refs Supabase: https://supabase.com/docs/guides/database/extensions/pg_cron
--
-- Expresion cron: '0 */6 * * *' -> en el minuto 0 de cada hora multiplo
-- de 6 (00:00, 06:00, 12:00, 18:00). Cuatro ejecuciones por dia son
-- suficientes para detectar devoluciones vencidas con granularidad razonable
-- sin saturar la base.
--
-- Comando a ejecutar: CALL pa_detectar_devoluciones_vencidas(). pg_cron
-- ejecuta el comando como el usuario que creo la tarea (en local: postgres,
-- en Supabase gestionado: tambien postgres). El procedimiento es plpgsql sin
-- SECURITY DEFINER -> corre con los privilegios del ejecutor de tareas, que
-- tiene INSERT/UPDATE sobre devolucion_vencida (rol postgres es propietario).

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_cron') THEN
        RAISE NOTICE 'pg_cron no esta instalado; se omite la programacion.';
        RETURN;
    END IF;

    IF EXISTS (
        SELECT 1 FROM cron.job WHERE jobname = 'detectar-devoluciones-vencidas'
    ) THEN
        RAISE NOTICE 'La tarea detectar-devoluciones-vencidas ya existe; se omite.';
        RETURN;
    END IF;

    PERFORM cron.schedule(
        'detectar-devoluciones-vencidas',
        '0 */6 * * *',
        $job$CALL pa_detectar_devoluciones_vencidas();$job$
    );
    RAISE NOTICE 'Tarea detectar-devoluciones-vencidas programada cada 6 horas.';

EXCEPTION WHEN OTHERS THEN
    -- Captura errores de permisos (algunos proveedores gestionados exigen un
    -- rol especial para cron.schedule) o incompatibilidad de base (pg_cron
    -- solo ejecuta tareas sobre cron.database_name, por defecto = postgres).
    RAISE NOTICE
        'No se pudo programar pa_detectar_devoluciones_vencidas: % '
        '(SQLSTATE: %). Puede correrse manualmente con CALL.',
        SQLERRM, SQLSTATE;
END
$$;
