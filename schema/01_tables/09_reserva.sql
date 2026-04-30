CREATE TABLE IF NOT EXISTS reserva (
    id_reserva           BIGSERIAL    PRIMARY KEY,
    id_cliente           BIGINT       NOT NULL,
    id_vehiculo          BIGINT       NOT NULL,
    fecha_inicio         TIMESTAMP    NOT NULL,
    fecha_fin_prevista   TIMESTAMP    NOT NULL,
    estado               VARCHAR(20)  NOT NULL DEFAULT 'pendiente',
    fecha_creacion       TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_reserva_estado CHECK (estado IN ('pendiente', 'confirmada', 'cancelada', 'expirada')),
    CONSTRAINT chk_reserva_fechas CHECK (fecha_fin_prevista > fecha_inicio)
);
