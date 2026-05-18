CREATE TABLE IF NOT EXISTS vehiculo (
    id_vehiculo        BIGSERIAL PRIMARY KEY,
    id_sucursal_origen BIGINT       NOT NULL,
    id_tipo            BIGINT       NOT NULL,
    id_estado          BIGINT       NOT NULL,
    marca              VARCHAR(50)  NOT NULL,
    modelo             VARCHAR(50)  NOT NULL,
    anio               INTEGER      NOT NULL,
    patente            VARCHAR(15)  NOT NULL UNIQUE,
    km_actuales        INTEGER      NOT NULL DEFAULT 0,
    detalle_confort    TEXT,
    CONSTRAINT chk_vehiculo_km   CHECK (km_actuales >= 0),
    CONSTRAINT chk_vehiculo_anio CHECK (anio BETWEEN 1900 AND EXTRACT(YEAR FROM CURRENT_DATE)::INTEGER + 1)
);
