CREATE TABLE IF NOT EXISTS cliente (
    id_cliente   BIGSERIAL PRIMARY KEY,
    id_usuario   BIGINT       UNIQUE,
    nombre       VARCHAR(100) NOT NULL,
    apellido     VARCHAR(100) NOT NULL,
    dni          VARCHAR(20)  NOT NULL UNIQUE,
    telefono     VARCHAR(30),
    direccion    VARCHAR(200)
);
