-- Tabla ubicacion_vehiculo.
--
-- Historial de ubicaciones fisicas de un vehiculo a lo largo del tiempo.
-- Cuando un alquiler se cierra con sucursal de devolucion distinta a la
-- de origen, el disparador del ciclo de vida deja registrado el cambio de
-- plaza.
-- La tupla (fecha_desde, fecha_hasta NULL = vigente) permite reconstruir
-- donde estaba un vehiculo en cualquier momento del pasado.
CREATE TABLE IF NOT EXISTS ubicacion_vehiculo (
    id_ubicacion  BIGSERIAL PRIMARY KEY,
    id_vehiculo   BIGINT    NOT NULL,
    id_sucursal   BIGINT    NOT NULL,
    fecha_desde   TIMESTAMP NOT NULL,
    fecha_hasta   TIMESTAMP NULL,
    CONSTRAINT chk_ubicacion_fechas CHECK (fecha_hasta IS NULL OR fecha_hasta > fecha_desde)
);
