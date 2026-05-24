CREATE TABLE IF NOT EXISTS estado_vehiculo (
    id_estado    BIGSERIAL PRIMARY KEY,
    -- Sprint 6 (B5.4): CHECK (nombre = lower(nombre)) cierra la puerta a
    -- nivel constraint a que entre 'Disponible' o 'DISPONIBLE' en el
    -- catalogo. Los triggers de FSM (fn_alquiler_start, fn_alquiler_close,
    -- fn_mantenimiento_*) buscan por nombre literal en minusculas; mezclar
    -- mayusculas en el catalogo rompia silenciosamente la transicion de
    -- estado, dejando vehiculos "fantasma". Cerramos la garantia en DDL.
    nombre       VARCHAR(50)  NOT NULL UNIQUE
                 CHECK (nombre = lower(nombre)),
    descripcion  VARCHAR(255)
);
