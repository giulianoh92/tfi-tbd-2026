-- fn_calcular_factura(id_alquiler) -> id_factura
--
-- Liquida un alquiler cerrado: calcula costo base, recargo por horas excedidas
-- e inserta la factura tomando una instantanea del precio_por_dia y porcentaje_recargo
-- vigentes en tarifa al momento de la emision.
--
-- fn_calcular_factura cubre la pieza de R10 que liquida el alquiler:
-- toma la instantanea de tarifa, calcula los recargos correspondientes y
-- emite la factura con numero correlativo.
--
-- Aporte original: Marcia Viera (commit 257d86f del 2026-05-16,
-- "funcionalidad finalizar alquiler"). Adaptaciones al esquema reescrito:
--   * porcentaje_recargo asumido como fraccion (0.20 = 20%); convencion
--     uniforme con la columna tarifa.porcentaje_recargo y con los datos iniciales.
--   * fecha_emision se inserta como DATE (CURRENT_DATE) coherente con el cambio
--     de tipo en la tabla factura.
--   * Numerador de factura via seq_numero_factura (creada en 17_factura.sql).
CREATE OR REPLACE FUNCTION fn_calcular_factura(
    p_id_alquiler BIGINT
)
RETURNS BIGINT AS $$
DECLARE
    v_id_cliente            BIGINT;
    v_id_tarifa             BIGINT;
    v_fecha_inicio          TIMESTAMP;
    v_fecha_fin_prevista    TIMESTAMP;
    v_fecha_devolucion_real TIMESTAMP;
    v_precio_por_dia        NUMERIC(12,2);
    v_porcentaje_recargo    NUMERIC(5,2);

    v_dias_pactados         INTEGER;
    v_horas_excedidas       NUMERIC(6,2) := 0;
    v_costo_base            NUMERIC(12,2);
    v_recargo_excedente     NUMERIC(12,2) := 0;
    v_total                 NUMERIC(12,2);
    v_numero_factura        VARCHAR(30);
    v_id_factura            BIGINT;
BEGIN
    -- 1. Instantanea de tarifa y datos del alquiler
    SELECT
        a.id_cliente,
        a.id_tarifa,
        a.fecha_inicio,
        a.fecha_fin_prevista,
        COALESCE(a.fecha_devolucion_real, NOW()),
        t.precio_por_dia,
        t.porcentaje_recargo
    INTO
        v_id_cliente,
        v_id_tarifa,
        v_fecha_inicio,
        v_fecha_fin_prevista,
        v_fecha_devolucion_real,
        v_precio_por_dia,
        v_porcentaje_recargo
    FROM alquiler a
    JOIN tarifa t ON a.id_tarifa = t.id_tarifa
    WHERE a.id_alquiler = p_id_alquiler;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'fn_calcular_factura: no se encontraron datos para el alquiler %', p_id_alquiler;
    END IF;

    -- 2. Costo base: dias pactados (no la devolucion real). Politica estandar
    --    de alquiler: el cliente paga los dias acordados aunque devuelva antes.
    v_dias_pactados := CEIL(EXTRACT(EPOCH FROM (v_fecha_fin_prevista - v_fecha_inicio)) / 86400);
    IF v_dias_pactados <= 0 THEN
        v_dias_pactados := 1;
    END IF;
    v_costo_base := v_dias_pactados * v_precio_por_dia;

    -- 3. Recargo por horas excedidas (formula de negocio del enunciado):
    --    horas * (precio_por_dia / 24) * porcentaje_recargo
    --    Convierte el costo diario a horario y aplica el % de recargo.
    IF v_fecha_devolucion_real > v_fecha_fin_prevista THEN
        v_horas_excedidas   := CEIL(EXTRACT(EPOCH FROM (v_fecha_devolucion_real - v_fecha_fin_prevista)) / 3600);
        v_recargo_excedente := v_horas_excedidas * (v_precio_por_dia / 24.0) * v_porcentaje_recargo;
    END IF;

    v_total := v_costo_base + v_recargo_excedente;

    -- 4. Emision con numero correlativo e instantanea historica.
    --
    -- numero_factura puede tener huecos. Si una transaccion se revierte
    -- (ej. el INSERT siguiente captura una excepcion), Postgres NO retrocede
    -- la secuencia: el comportamiento estandar de NEXTVAL es mantener
    -- consistencia entre sesiones concurrentes sin bloqueo global, por diseno.
    -- Para un correlativo fiscal estricto sin huecos haria falta una tabla
    -- contadora con actualizacion bajo bloqueo (SELECT ... FOR UPDATE + UPDATE ...
    -- SET valor = valor + 1), patron mucho mas lento y que serializa todas
    -- las facturaciones. Como el TFI no requiere correlativo fiscal
    -- de nivel AFIP (R10), mantenemos la secuencia y aceptamos la limitacion.
    v_numero_factura := 'FAC-' || LPAD(NEXTVAL('seq_numero_factura')::TEXT, 6, '0');

    INSERT INTO factura (
        id_alquiler,
        id_cliente,
        numero_factura,
        fecha_emision,
        precio_por_dia_aplicado,
        porcentaje_recargo_aplicado,
        costo_base,
        horas_excedidas,
        recargo_excedente,
        total
    ) VALUES (
        p_id_alquiler,
        v_id_cliente,
        v_numero_factura,
        CURRENT_DATE,
        v_precio_por_dia,
        v_porcentaje_recargo,
        v_costo_base,
        v_horas_excedidas,
        v_recargo_excedente,
        v_total
    ) RETURNING id_factura INTO v_id_factura;

    RETURN v_id_factura;
END;
$$ LANGUAGE plpgsql;
