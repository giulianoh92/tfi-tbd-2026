CREATE TABLE IF NOT EXISTS ubicacion_vehiculo (
    id_ubicacion  BIGSERIAL PRIMARY KEY,
    id_vehiculo   BIGINT    NOT NULL,
    id_sucursal   BIGINT    NOT NULL,
    fecha_desde   TIMESTAMP NOT NULL,
    fecha_hasta   TIMESTAMP NULL,
    CONSTRAINT chk_ubicacion_fechas CHECK (fecha_hasta IS NULL OR fecha_hasta > fecha_desde)
);
