CREATE TABLE IF NOT EXISTS estado_vehiculo (
    id_estado    BIGSERIAL PRIMARY KEY,
    nombre       VARCHAR(50)  NOT NULL UNIQUE,
    descripcion  VARCHAR(255)
);
