CREATE TABLE IF NOT EXISTS factura (
    id_factura          BIGSERIAL      PRIMARY KEY,
    id_alquiler         BIGINT         NOT NULL UNIQUE,
    id_cliente          BIGINT         NOT NULL,
    numero_factura      VARCHAR(30)    NOT NULL UNIQUE,
    fecha_emision       TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    costo_base          NUMERIC(12, 2) NOT NULL,
    horas_excedidas     NUMERIC(6, 2)  NOT NULL DEFAULT 0,
    recargo_excedente   NUMERIC(12, 2) NOT NULL DEFAULT 0,
    total               NUMERIC(12, 2) NOT NULL,
    CONSTRAINT chk_factura_montos CHECK (
        costo_base        >= 0
        AND horas_excedidas   >= 0
        AND recargo_excedente >= 0
        AND total             >= 0
    )
);
