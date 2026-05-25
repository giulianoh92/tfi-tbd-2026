-- Tabla taller.
--
-- Catalogo de talleres mecanicos externos donde se envia un vehiculo a
-- mantenimiento. Cada fila de la tabla mantenimiento referencia un taller
-- via FK id_taller. No se modela como sucursal: un taller no opera
-- alquileres ni recibe devoluciones, es un proveedor de servicio externo.
CREATE TABLE IF NOT EXISTS taller (
    id_taller    BIGSERIAL PRIMARY KEY,
    nombre       VARCHAR(100) NOT NULL,
    direccion    VARCHAR(200) NOT NULL,
    telefono     VARCHAR(30)
);
