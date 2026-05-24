-- Scheduling de jobs con pg_cron (Sprint 4 - R9).
--
-- Estructura defensiva:
--   1) Solo intenta agendar si la extension pg_cron esta presente
--      (chequea pg_extension). En entornos donde no se habilito
--      shared_preload_libraries, el bloque pasa sin ruido y el resto del
--      schema se aplica normal.
--   2) Si pg_cron esta, verifica que el job no exista todavia (chequea
--      cron.job por jobname) y recien ahi llama cron.schedule(). Esto
--      hace al script idempotente frente a re-aplies de apply.sh.
--
-- Cron expression: '0 */6 * * *' -> en el minuto 0 de cada hora multiplo
-- de 6 (00:00, 06:00, 12:00, 18:00). Cuatro corridas por dia es suficiente
-- para detectar devoluciones vencidas con granularidad razonable sin
-- saturar la DB.
--
-- Comando a ejecutar: CALL pa_detectar_devoluciones_vencidas(). pg_cron
-- ejecuta el comando como el usuario que creo el job (en local: postgres,
-- en Supabase managed: postgres tambien). El procedure es plpgsql sin
-- SECURITY DEFINER -> corre con los privilegios del job runner, que tiene
-- INSERT/UPDATE sobre devolucion_vencida (rol postgres es owner).

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_cron') THEN
        RAISE NOTICE 'pg_cron no esta instalado; se omite el scheduling.';
        RETURN;
    END IF;

    IF EXISTS (
        SELECT 1 FROM cron.job WHERE jobname = 'detectar-devoluciones-vencidas'
    ) THEN
        RAISE NOTICE 'Job detectar-devoluciones-vencidas ya existe; se omite.';
        RETURN;
    END IF;

    PERFORM cron.schedule(
        'detectar-devoluciones-vencidas',
        '0 */6 * * *',
        $job$CALL pa_detectar_devoluciones_vencidas();$job$
    );
    RAISE NOTICE 'Job detectar-devoluciones-vencidas schedulado cada 6 horas.';

EXCEPTION WHEN OTHERS THEN
    -- Captura permission errors (algunos managed providers exigen rol
    -- especial para cron.schedule) o database mismatch (pg_cron solo
    -- corre jobs sobre cron.database_name por default = postgres).
    RAISE NOTICE
        'No se pudo schedulear pa_detectar_devoluciones_vencidas: % '
        '(SQLSTATE: %). Puede correrse manualmente con CALL.',
        SQLERRM, SQLSTATE;
END
$$;
