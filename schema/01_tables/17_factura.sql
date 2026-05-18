CREATE TABLE IF NOT EXISTS factura (
    id_factura                     BIGSERIAL      PRIMARY KEY,
    id_alquiler                    BIGINT         NOT NULL UNIQUE,
    id_cliente                     BIGINT         NOT NULL,
    numero_factura                 VARCHAR(30)    NOT NULL UNIQUE,
    fecha_emision                  DATE           NOT NULL DEFAULT CURRENT_DATE,
    precio_por_dia_aplicado        NUMERIC(12, 2) NOT NULL,
    porcentaje_recargo_aplicado    NUMERIC(5, 2)  NOT NULL,
    costo_base                     NUMERIC(12, 2) NOT NULL,
    horas_excedidas                NUMERIC(6, 2)  NOT NULL DEFAULT 0,
    recargo_excedente              NUMERIC(12, 2) NOT NULL DEFAULT 0,
    total                          NUMERIC(12, 2) NOT NULL,
    CONSTRAINT chk_factura_precio_dia    CHECK (precio_por_dia_aplicado >= 0),
    CONSTRAINT chk_factura_recargo_pct   CHECK (porcentaje_recargo_aplicado >= 0),
    CONSTRAINT chk_factura_costo_base    CHECK (costo_base >= 0),
    CONSTRAINT chk_factura_horas         CHECK (horas_excedidas >= 0),
    CONSTRAINT chk_factura_recargo_exc   CHECK (recargo_excedente >= 0),
    CONSTRAINT chk_factura_total         CHECK (total >= 0)
);
