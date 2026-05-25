-- Tabla tipo_vehiculo.
--
-- Catalogo de categorias comerciales de vehiculo (sedan, suv, camioneta,
-- furgon, etc). Determina, junto con la sucursal, la tarifa diaria
-- aplicable (ver tabla tarifa). UNIQUE sobre nombre asegura que el catalogo
-- no contenga duplicados con tipografia distinta.
CREATE TABLE IF NOT EXISTS tipo_vehiculo (
    id_tipo      BIGSERIAL PRIMARY KEY,
    nombre       VARCHAR(50)  NOT NULL UNIQUE,
    descripcion  VARCHAR(255)
);
