-- Tabla tarifa (R10).
--
-- Define el precio por dia y el porcentaje de recargo aplicable por hora
-- excedida, parametrizado por sucursal y tipo de vehiculo. El procedure
-- fn_calcular_factura consulta esta tabla al cerrar un alquiler para
-- emitir la factura con valores vigentes. La constraint UNIQUE compuesta
-- (id_sucursal, id_tipo) definida en 02_constraints asegura una sola
-- tarifa por combinacion.
CREATE TABLE IF NOT EXISTS tarifa (
    id_tarifa            BIGSERIAL      PRIMARY KEY,
    id_sucursal          BIGINT         NOT NULL,
    id_tipo              BIGINT         NOT NULL,
    precio_por_dia       NUMERIC(12, 2) NOT NULL,
    porcentaje_recargo   NUMERIC(5, 2)  NOT NULL,
    CONSTRAINT chk_tarifa_precio  CHECK (precio_por_dia > 0),
    CONSTRAINT chk_tarifa_recargo CHECK (porcentaje_recargo >= 0)
);
