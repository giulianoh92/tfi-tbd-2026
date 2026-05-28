-- Tabla historial_estado_vehiculo (R10).
--
-- Bitacora temporal de las transiciones de estado de un vehiculo (maquina
-- de estados: disponible -> alquilado -> disponible, o disponible ->
-- en_mantenimiento -> disponible). La fila vigente tiene fecha_fin NULL;
-- cuando ocurre una transicion, los disparadores del ciclo de vida
-- (fn_alquiler_lifecycle y fn_mantenimiento_lifecycle) cierran la fila
-- anterior con fecha_fin = NOW() e insertan una nueva. Soporta consultas
-- historicas y rastreo de por que un vehiculo no estuvo disponible en un
-- periodo dado.
CREATE TABLE IF NOT EXISTS historial_estado_vehiculo (
    id_historial  BIGSERIAL PRIMARY KEY,
    id_vehiculo   BIGINT       NOT NULL,
    id_estado     BIGINT       NOT NULL,
    fecha_inicio  TIMESTAMP    NOT NULL,
    fecha_fin     TIMESTAMP    NULL,
    motivo        VARCHAR(255),
    CONSTRAINT chk_historial_fechas CHECK (fecha_fin IS NULL OR fecha_fin > fecha_inicio)
);
