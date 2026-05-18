CREATE TABLE IF NOT EXISTS garantia_reserva (
    id_garantia          BIGSERIAL    PRIMARY KEY,
    id_reserva           BIGINT       NOT NULL,
    tipo                 VARCHAR(30)  NOT NULL,
    titular              VARCHAR(100) NOT NULL,
    numero_tarjeta_hash  VARCHAR(255) NOT NULL,
    vencimiento          DATE         NOT NULL,
    fecha_registro       TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    activa               BOOLEAN      NOT NULL DEFAULT TRUE
);
