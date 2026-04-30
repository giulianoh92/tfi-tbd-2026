CREATE TABLE IF NOT EXISTS tipo_vehiculo (
    id_tipo      BIGSERIAL PRIMARY KEY,
    nombre       VARCHAR(50)  NOT NULL UNIQUE,
    descripcion  VARCHAR(255)
);
