CREATE TABLE IF NOT EXISTS taller (
    id_taller    BIGSERIAL PRIMARY KEY,
    nombre       VARCHAR(100) NOT NULL,
    direccion    VARCHAR(200) NOT NULL,
    telefono     VARCHAR(30)
);
