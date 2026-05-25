-- Tabla estado_vehiculo (R10).
--
-- Catalogo de estados operativos de un vehiculo (disponible, alquilado,
-- en_mantenimiento, fuera_de_servicio). Forma una maquina de estados (FSM)
-- consumida por los triggers de ciclo de vida del alquiler (R10) y del
-- mantenimiento. La transicion entre estados se persiste en
-- historial_estado_vehiculo para tener trazabilidad temporal.
CREATE TABLE IF NOT EXISTS estado_vehiculo (
    id_estado    BIGSERIAL PRIMARY KEY,
    -- CHECK (nombre = lower(nombre)) cierra la puerta a nivel constraint a
    -- que entre 'Disponible' o 'DISPONIBLE' en el catalogo. Los triggers de
    -- FSM (fn_alquiler_start, fn_alquiler_close, fn_mantenimiento_*) buscan
    -- por nombre literal en minusculas; mezclar mayusculas en el catalogo
    -- rompe silenciosamente la transicion de estado, dejando vehiculos
    -- "fantasma". La garantia queda cerrada en DDL.
    nombre       VARCHAR(50)  NOT NULL UNIQUE
                 CHECK (nombre = lower(nombre)),
    descripcion  VARCHAR(255)
);
