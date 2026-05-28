-- Tabla vehiculo (R3, R10).
--
-- Entidad central del dominio: cada fila representa una unidad fisica de la
-- flota. Referencia a su sucursal de origen, a su tipo comercial y a su
-- estado operativo vigente (valor denormalizado que refleja el ultimo estado
-- de la maquina de estados; el historial completo vive en
-- historial_estado_vehiculo). Soporta CRUD por programacion en BD mediante
-- pa_crud_vehiculo (R3, R4) y participa en la validacion de superposicion
-- temporal de alquileres y reservas (fn_check_vehiculo_overlap, R7) y en la
-- maquina de estados del ciclo de vida del alquiler (R10).
CREATE TABLE IF NOT EXISTS vehiculo (
    id_vehiculo        BIGSERIAL PRIMARY KEY,
    id_sucursal_origen BIGINT       NOT NULL,
    id_tipo            BIGINT       NOT NULL,
    id_estado          BIGINT       NOT NULL,
    marca              VARCHAR(50)  NOT NULL,
    modelo             VARCHAR(50)  NOT NULL,
    anio               INTEGER      NOT NULL,
    patente            VARCHAR(15)  NOT NULL UNIQUE,
    km_actuales        INTEGER      NOT NULL DEFAULT 0,
    detalle_confort    TEXT,
    CONSTRAINT chk_vehiculo_km   CHECK (km_actuales >= 0),
    CONSTRAINT chk_vehiculo_anio CHECK (anio BETWEEN 1900 AND EXTRACT(YEAR FROM CURRENT_DATE)::INTEGER + 1)
);
