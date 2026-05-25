-- Tabla sucursal.
--
-- Representa cada agencia fisica de la empresa de alquiler. Es entidad
-- maestra del dominio: los vehiculos pertenecen a una sucursal de origen,
-- las tarifas se definen por sucursal y tipo de vehiculo, y los alquileres
-- pueden devolverse en una sucursal distinta de la de origen (campo
-- id_sucursal_devolucion en alquiler). Sirve de soporte a los CRUD por
-- programacion en BD (R3) y a las consultas de disponibilidad y facturacion.
CREATE TABLE IF NOT EXISTS sucursal (
    id_sucursal  BIGSERIAL PRIMARY KEY,
    nombre       VARCHAR(100) NOT NULL,
    direccion    VARCHAR(200) NOT NULL,
    ciudad       VARCHAR(100) NOT NULL,
    telefono     VARCHAR(30)
);
