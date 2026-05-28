-- Tabla imagen_vehiculo.
--
-- Galeria fotografica de cada vehiculo (hasta 5 imagenes, regla de negocio
-- garantizada por el disparador trg_check_max_imagenes y por la CHECK
-- constraint sobre `orden`). El campo `orden` determina el ordenamiento
-- visible en la aplicacion cliente (1 = imagen principal). Solo se guarda
-- la URL: los archivos binarios viven en almacenamiento externo (bucket de
-- Supabase Storage).
CREATE TABLE IF NOT EXISTS imagen_vehiculo (
    id_imagen    BIGSERIAL PRIMARY KEY,
    id_vehiculo  BIGINT       NOT NULL,
    url_imagen   VARCHAR(500) NOT NULL,
    orden        INTEGER      NOT NULL,
    CONSTRAINT chk_imagen_orden CHECK (orden BETWEEN 1 AND 5)
);
