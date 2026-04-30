CREATE TABLE IF NOT EXISTS mantenimiento (
    id_mantenimiento     BIGSERIAL  PRIMARY KEY,
    id_vehiculo          BIGINT     NOT NULL,
    id_taller            BIGINT     NOT NULL,
    fecha_envio          TIMESTAMP  NOT NULL,
    fecha_devolucion     TIMESTAMP,
    observaciones        TEXT,
    CONSTRAINT chk_mantenimiento_fechas CHECK (fecha_devolucion IS NULL OR fecha_devolucion >= fecha_envio)
);
