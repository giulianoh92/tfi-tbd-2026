CREATE TABLE IF NOT EXISTS imagen_vehiculo (
    id_imagen    BIGSERIAL PRIMARY KEY,
    id_vehiculo  BIGINT       NOT NULL,
    url_imagen   VARCHAR(500) NOT NULL,
    orden        SMALLINT     NOT NULL,
    CONSTRAINT chk_imagen_orden CHECK (orden BETWEEN 1 AND 5)
);
