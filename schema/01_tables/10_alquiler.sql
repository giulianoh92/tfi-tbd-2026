CREATE TABLE IF NOT EXISTS alquiler (
    id_alquiler              BIGSERIAL    PRIMARY KEY,
    id_reserva               BIGINT       UNIQUE,
    id_cliente               BIGINT       NOT NULL,
    id_vehiculo              BIGINT       NOT NULL,
    id_tarifa                BIGINT       NOT NULL,
    fecha_inicio             TIMESTAMP    NOT NULL,
    fecha_fin_prevista       TIMESTAMP    NOT NULL,
    fecha_devolucion_real    TIMESTAMP,
    km_inicio                INTEGER      NOT NULL,
    km_fin                   INTEGER,
    estado                   VARCHAR(20)  NOT NULL DEFAULT 'en_curso',
    CONSTRAINT chk_alquiler_estado CHECK (estado IN ('en_curso', 'finalizado', 'cancelado')),
    CONSTRAINT chk_alquiler_fechas CHECK (fecha_fin_prevista > fecha_inicio),
    CONSTRAINT chk_alquiler_km     CHECK (km_inicio >= 0 AND (km_fin IS NULL OR km_fin >= km_inicio))
);
