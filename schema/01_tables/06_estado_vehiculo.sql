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
