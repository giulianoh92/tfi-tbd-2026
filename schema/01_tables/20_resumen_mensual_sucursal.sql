-- Tabla resumen_mensual_sucursal (R13 - cierre contable mensual).
--
-- Snapshot agregado, una fila por (periodo, sucursal), que materializa el
-- cierre de facturacion de cada mes. Lo puebla la tarea programada
-- pa_cerrar_facturacion_mensual (pg_cron, una vez por mes), que recorre TODAS
-- las facturas del mes cerrado y consolida los totales por sucursal en esta
-- tabla.
--
-- Por que materializar (y no consultar siempre vw_facturacion_mensual):
--   * La vista recalcula el agregado en cada consulta recorriendo factura +
--     alquiler + vehiculo. Util para el mes en curso, pero costoso e
--     innecesario para meses ya cerrados, cuyos numeros no cambian.
--   * Esta tabla congela el resultado del mes una sola vez -> las consultas
--     gerenciales historicas (tableros, comparativas interanuales) leen filas
--     pre-calculadas en O(filas) sin re-agregar la facturacion completa.
--   * Funciona como "cierre de caja" contable: deja un registro estable e
--     idempotente del periodo, con fecha_cierre como metadato de cuando se
--     consolido.
--
-- Atribucion de sucursal: se usa la sucursal de ORIGEN del vehiculo
-- (vehiculo.id_sucursal_origen), el MISMO criterio que vw_facturacion_mensual,
-- para que el cierre materializado y la vista en vivo nunca se contradigan.
--
-- periodo se almacena como DATE = primer dia del mes (DATE_TRUNC('month',
-- ...)::DATE), igual que el campo `mes` de vw_facturacion_mensual, para
-- ordenar y filtrar sin manipular cadenas.
--
-- Unicidad (periodo, id_sucursal): definida en 02_constraints/01_uq_compuestos
-- .sql. Habilita el UPSERT idempotente (ON CONFLICT) del procedure: re-correr
-- el cierre de un mes refresca la fila en lugar de duplicarla.
CREATE TABLE IF NOT EXISTS resumen_mensual_sucursal (
    id_resumen          BIGSERIAL      PRIMARY KEY,
    periodo             DATE           NOT NULL,
    id_sucursal         BIGINT         NOT NULL,
    facturas_emitidas   INTEGER        NOT NULL DEFAULT 0,
    total_costo_base    NUMERIC(14, 2) NOT NULL DEFAULT 0,
    total_recargos      NUMERIC(14, 2) NOT NULL DEFAULT 0,
    total_facturado     NUMERIC(14, 2) NOT NULL DEFAULT 0,
    km_recorridos       BIGINT         NOT NULL DEFAULT 0,
    fecha_cierre        TIMESTAMPTZ    NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_resumen_periodo_dia1
        CHECK (periodo = DATE_TRUNC('month', periodo)::DATE),
    CONSTRAINT chk_resumen_facturas   CHECK (facturas_emitidas >= 0),
    CONSTRAINT chk_resumen_costo_base CHECK (total_costo_base   >= 0),
    CONSTRAINT chk_resumen_recargos   CHECK (total_recargos     >= 0),
    CONSTRAINT chk_resumen_total      CHECK (total_facturado    >= 0),
    CONSTRAINT chk_resumen_km         CHECK (km_recorridos      >= 0)
);
