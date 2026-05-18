CREATE TABLE IF NOT EXISTS tipo_reserva (
    id_tipo_reserva      BIGSERIAL PRIMARY KEY,
    nombre               VARCHAR(50)  NOT NULL UNIQUE,
    descripcion          VARCHAR(255),
    requiere_garantia    BOOLEAN      NOT NULL DEFAULT FALSE,
    antelacion_max_dias  INTEGER      NOT NULL DEFAULT 30,
    CONSTRAINT chk_tipo_reserva_antelacion CHECK (antelacion_max_dias > 0)
);
