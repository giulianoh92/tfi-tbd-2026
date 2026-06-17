-- Procedure: pa_cerrar_facturacion_mensual (R13 - procesamiento masivo)
-- Tarea programada de cierre contable: consolida en lote la facturacion del
-- mes recien terminado en la tabla resumen_mensual_sucursal, una fila por
-- sucursal.
--
-- Procesamiento MASIVO: una sola sentencia INSERT ... SELECT ... GROUP BY
-- recorre TODAS las facturas del periodo, las une con alquiler y vehiculo,
-- agrega por sucursal de origen y materializa los totales. Cuantas mas
-- facturas tenga el mes, mas filas procesa el agregado en una corrida.
--
-- Periodo cerrado: el mes calendario ANTERIOR al de la fecha de ejecucion.
--   v_periodo = DATE_TRUNC('month', CURRENT_DATE - INTERVAL '1 month')::DATE.
-- Pensado para correr el dia 1 de cada mes: cierra el mes que acaba de
-- terminar, ya completo e inmutable.
--
-- Atribucion de sucursal: vehiculo.id_sucursal_origen, el MISMO criterio que
-- vw_facturacion_mensual, para que el cierre materializado coincida con la
-- vista en vivo.
--
-- Metricas consolidadas por (periodo, sucursal):
--   * facturas_emitidas = COUNT(*) de facturas del mes.
--   * total_costo_base  = SUM(factura.costo_base).
--   * total_recargos    = SUM(factura.recargo_excedente).
--   * total_facturado   = SUM(factura.total).
--   * km_recorridos     = SUM(alquiler.km_fin - alquiler.km_inicio) de los
--                         alquileres facturados (COALESCE defensivo).
--
-- Idempotencia: UPSERT por (periodo, id_sucursal) (uq_resumen_periodo
-- _sucursal). Re-correr el cierre de un mes recalcula y refresca la fila,
-- nunca la duplica; fecha_cierre se actualiza a la ultima consolidacion.
--
-- Programada via pg_cron (ver 04_functions/21_schedule_jobs.sql) una vez por
-- mes. Tarea automatica sin peticion HTTP: no retorna p_estado/p_mensaje. Los
-- errores se capturan con EXCEPTION OTHERS + RAISE NOTICE para no abortar la
-- proxima ejecucion.
--
-- SECURITY DEFINER + SET search_path = public: mismo criterio que las demas
-- tareas programadas -> corre como propietario (postgres) cuando la invoca
-- pg_cron, con INSERT/UPDATE sobre resumen_mensual_sucursal garantizado sin
-- depender de RLS, y blindada contra suplantacion de funciones.
CREATE OR REPLACE PROCEDURE pa_cerrar_facturacion_mensual()
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_periodo DATE := DATE_TRUNC('month', CURRENT_DATE - INTERVAL '1 month')::DATE;
    v_filas   INTEGER := 0;
BEGIN
    INSERT INTO resumen_mensual_sucursal AS r (
        periodo,
        id_sucursal,
        facturas_emitidas,
        total_costo_base,
        total_recargos,
        total_facturado,
        km_recorridos,
        fecha_cierre
    )
    SELECT
        v_periodo,
        v.id_sucursal_origen,
        COUNT(*),
        SUM(f.costo_base),
        SUM(f.recargo_excedente),
        SUM(f.total),
        SUM(COALESCE(a.km_fin, a.km_inicio) - a.km_inicio),
        NOW()
      FROM factura f
      JOIN alquiler a ON a.id_alquiler = f.id_alquiler
      JOIN vehiculo v ON v.id_vehiculo = a.id_vehiculo
     WHERE DATE_TRUNC('month', f.fecha_emision)::DATE = v_periodo
     GROUP BY v.id_sucursal_origen
    ON CONFLICT (periodo, id_sucursal) DO UPDATE
        SET facturas_emitidas = EXCLUDED.facturas_emitidas,
            total_costo_base  = EXCLUDED.total_costo_base,
            total_recargos    = EXCLUDED.total_recargos,
            total_facturado   = EXCLUDED.total_facturado,
            km_recorridos     = EXCLUDED.km_recorridos,
            fecha_cierre      = EXCLUDED.fecha_cierre;

    GET DIAGNOSTICS v_filas = ROW_COUNT;

    RAISE NOTICE
        'pa_cerrar_facturacion_mensual: periodo % consolidado, % sucursales con facturacion.',
        v_periodo, v_filas;

EXCEPTION WHEN OTHERS THEN
    -- Nunca dejamos que un error de la tarea interrumpa el cron. La siguiente
    -- ejecucion lo reintentara automaticamente.
    RAISE NOTICE
        'pa_cerrar_facturacion_mensual fallo: % (SQLSTATE: %).',
        SQLERRM, SQLSTATE;
END;
$$;
