-- Procedure: pa_detectar_devoluciones_vencidas
-- Sprint 4 (R9). Job: detecta alquileres con devolucion vencida y los
-- persiste en la tabla historica `devolucion_vencida`.
--
-- Schedulado via pg_cron (ver schema/04_functions/21_schedule_jobs.sql)
-- cada 6 horas. Al ser un job no hay caller HTTP, asi que no devuelve
-- p_estado/p_mensaje (no habria quien los lea). Los errores se capturan
-- con un bloque EXCEPTION OTHERS + RAISE NOTICE para que queden en el
-- log del cron sin abortar la transaccion del proximo job.
--
-- Idempotencia: se usa INSERT ... ON CONFLICT (id_alquiler) DO UPDATE.
-- Si el alquiler ya estaba detectado, se refresca `horas_excedidas` y
-- `fecha_deteccion` pero NO se toca `notificado` (asi no se "desnotifica"
-- una fila que el staff ya marco como atendida).
--
-- Criterio de seleccion (mismo que el PDF):
--   * estado = 'activo'                  -> no esta cerrado.
--   * fecha_fin_prevista < NOW()         -> deberia haber sido devuelto.
--   * fecha_devolucion_real IS NULL      -> aun no se devolvio.
--
-- horas_excedidas se calcula como EXTRACT(EPOCH FROM (NOW() -
-- fecha_fin_prevista)) / 3600. Es una NUMERIC(8,2) -> precision a la
-- centesima de hora.

-- Sprint 6 (B8.1) — SECURITY DEFINER + search_path = public:
--   * SECURITY DEFINER: el job corre como owner (postgres) cuando lo invoca
--     pg_cron. Lo declaramos explicitamente para que, si en el futuro se
--     llama desde otro rol con privilegios menores (manual debugging, RPC
--     desde service_role), el INSERT en devolucion_vencida siga
--     funcionando sin depender de RLS o GRANT especificos.
--   * SET search_path = public: defensa contra "function hijacking" via
--     schemas en el PATH del invocador (mitigation estandar contra
--     CVE-2007-2138 y la familia de ataques que reemplazan funciones
--     built-in como `format` o `lower` desde un schema temporal del
--     atacante). Best practice oficial de Supabase para toda function
--     SECURITY DEFINER.
CREATE OR REPLACE PROCEDURE pa_detectar_devoluciones_vencidas()
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_filas_afectadas INTEGER;
BEGIN
    INSERT INTO devolucion_vencida (
        id_alquiler,
        id_vehiculo,
        id_cliente,
        fecha_fin_prevista,
        horas_excedidas
    )
    SELECT
        a.id_alquiler,
        a.id_vehiculo,
        a.id_cliente,
        a.fecha_fin_prevista,
        ROUND(
            (EXTRACT(EPOCH FROM (NOW() - a.fecha_fin_prevista)) / 3600.0)::NUMERIC,
            2
        ) AS horas_excedidas
      FROM alquiler a
     WHERE a.estado = 'activo'
       AND a.fecha_fin_prevista < NOW()
       AND a.fecha_devolucion_real IS NULL
    ON CONFLICT (id_alquiler) DO UPDATE
        SET horas_excedidas = EXCLUDED.horas_excedidas,
            fecha_deteccion = NOW();

    GET DIAGNOSTICS v_filas_afectadas = ROW_COUNT;

    RAISE NOTICE
        'pa_detectar_devoluciones_vencidas: % filas afectadas (insert + update).',
        v_filas_afectadas;

EXCEPTION WHEN OTHERS THEN
    -- Nunca dejamos que un error del job tumbe el cron. El siguiente
    -- tick lo reintenta automaticamente.
    RAISE NOTICE
        'pa_detectar_devoluciones_vencidas fallo: % (SQLSTATE: %).',
        SQLERRM, SQLSTATE;
END;
$$;
