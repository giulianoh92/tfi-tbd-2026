CREATE TABLE IF NOT EXISTS tarifa (
    id_tarifa            BIGSERIAL      PRIMARY KEY,
    id_sucursal          BIGINT         NOT NULL,
    id_tipo              BIGINT         NOT NULL,
    precio_por_dia       NUMERIC(12, 2) NOT NULL,
    porcentaje_recargo   NUMERIC(5, 2)  NOT NULL,
    CONSTRAINT chk_tarifa_precio  CHECK (precio_por_dia > 0),
    CONSTRAINT chk_tarifa_recargo CHECK (porcentaje_recargo >= 0)
);
