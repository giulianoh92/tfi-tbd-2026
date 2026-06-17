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

    -- Cada tarea se programa con su propia guarda de idempotencia (sin RETURN
    -- temprano): los registros de pg_cron viven en el schema `cron`, que
    -- `DROP SCHEMA public CASCADE` del apply NO borra, de modo que en una
    -- re-aplicacion una tarea ya existente debe omitirse sin impedir que las
    -- demas se evaluen.

    -- Tarea 1 (R9): deteccion de devoluciones vencidas, cada 6 horas.
    IF EXISTS (
        SELECT 1 FROM cron.job WHERE jobname = 'detectar-devoluciones-vencidas'
    ) THEN
        RAISE NOTICE 'La tarea detectar-devoluciones-vencidas ya existe; se omite.';
    ELSE
        PERFORM cron.schedule(
            'detectar-devoluciones-vencidas',
            '0 */6 * * *',
            $job$CALL pa_detectar_devoluciones_vencidas();$job$
        );
        RAISE NOTICE 'Tarea detectar-devoluciones-vencidas programada cada 6 horas.';
    END IF;

    -- Tarea 2 (R12, procesamiento masivo): expiracion de reservas pendientes
    -- no concretadas, una vez por dia a las 03:00 (hora de baja actividad). El
    -- procedure pa_expirar_reservas_vencidas se define en 04_functions/24_*.sql;
    -- pg_cron solo almacena el texto del comando y lo resuelve recien al
    -- ejecutarlo, por lo que no importa que ese archivo se aplique despues.
    IF EXISTS (
        SELECT 1 FROM cron.job WHERE jobname = 'expirar-reservas-vencidas'
    ) THEN
        RAISE NOTICE 'La tarea expirar-reservas-vencidas ya existe; se omite.';
    ELSE
        PERFORM cron.schedule(
            'expirar-reservas-vencidas',
            '0 3 * * *',
            $job$CALL pa_expirar_reservas_vencidas();$job$
        );
        RAISE NOTICE 'Tarea expirar-reservas-vencidas programada todos los dias a las 03:00.';
    END IF;

    -- Tarea 3 (R13, procesamiento masivo): cierre contable mensual. Corre el
    -- dia 1 de cada mes a las 04:00 (despues de la expiracion diaria) y
    -- consolida la facturacion del mes recien terminado en
    -- resumen_mensual_sucursal. El procedure pa_cerrar_facturacion_mensual se
    -- define en 04_functions/25_*.sql.
    IF EXISTS (
        SELECT 1 FROM cron.job WHERE jobname = 'cerrar-facturacion-mensual'
    ) THEN
        RAISE NOTICE 'La tarea cerrar-facturacion-mensual ya existe; se omite.';
    ELSE
        PERFORM cron.schedule(
            'cerrar-facturacion-mensual',
            '0 4 1 * *',
            $job$CALL pa_cerrar_facturacion_mensual();$job$
        );
        RAISE NOTICE 'Tarea cerrar-facturacion-mensual programada el dia 1 de cada mes a las 04:00.';
    END IF;

EXCEPTION WHEN OTHERS THEN
    -- Captura errores de permisos (algunos proveedores gestionados exigen un
    -- rol especial para cron.schedule) o incompatibilidad de base (pg_cron
    -- solo ejecuta tareas sobre cron.database_name, por defecto = postgres).
    RAISE NOTICE
        'No se pudieron programar las tareas de pg_cron: % '
        '(SQLSTATE: %). Pueden correrse manualmente con CALL.',
        SQLERRM, SQLSTATE;
END
$$;
