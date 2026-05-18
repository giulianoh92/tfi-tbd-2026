CREATE TABLE IF NOT EXISTS historial_estado_vehiculo (
    id_historial  BIGSERIAL PRIMARY KEY,
    id_vehiculo   BIGINT       NOT NULL,
    id_estado     BIGINT       NOT NULL,
    fecha_inicio  TIMESTAMP    NOT NULL,
    fecha_fin     TIMESTAMP    NULL,
    motivo        VARCHAR(255),
    CONSTRAINT chk_historial_fechas CHECK (fecha_fin IS NULL OR fecha_fin > fecha_inicio)
);
