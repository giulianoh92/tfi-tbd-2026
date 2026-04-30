CREATE TABLE IF NOT EXISTS sucursal (
    id_sucursal  BIGSERIAL PRIMARY KEY,
    nombre       VARCHAR(100) NOT NULL,
    direccion    VARCHAR(200) NOT NULL,
    ciudad       VARCHAR(100) NOT NULL,
    telefono     VARCHAR(30)
);
