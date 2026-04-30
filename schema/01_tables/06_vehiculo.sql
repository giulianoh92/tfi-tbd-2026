CREATE TABLE IF NOT EXISTS vehiculo (
    id_vehiculo      BIGSERIAL PRIMARY KEY,
    id_sucursal      BIGINT       NOT NULL,
    id_tipo          BIGINT       NOT NULL,
    marca            VARCHAR(50)  NOT NULL,
    modelo           VARCHAR(50)  NOT NULL,
    anio             INTEGER      NOT NULL,
    patente          VARCHAR(15)  NOT NULL UNIQUE,
    km_actuales      INTEGER      NOT NULL DEFAULT 0,
    detalle_confort  TEXT,
    estado           VARCHAR(20)  NOT NULL DEFAULT 'disponible',
    CONSTRAINT chk_vehiculo_estado CHECK (estado IN ('disponible', 'alquilado', 'mantenimiento')),
    CONSTRAINT chk_vehiculo_km     CHECK (km_actuales >= 0),
    CONSTRAINT chk_vehiculo_anio   CHECK (anio BETWEEN 1900 AND EXTRACT(YEAR FROM CURRENT_DATE)::INT + 1)
);
