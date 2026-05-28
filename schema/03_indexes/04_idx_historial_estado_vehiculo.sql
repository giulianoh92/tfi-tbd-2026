-- Indices de historial_estado_vehiculo (R10).
--
-- Los dos primeros soportan las claves forneas y las combinaciones por
-- vehiculo/estado.
-- El UNIQUE PARCIAL uq_historial_estado_vigente sostiene la invariante de
-- la maquina de estados: un vehiculo tiene EXACTAMENTE una fila con
-- fecha_fin NULL (el estado vigente). Los disparadores fn_alquiler_lifecycle
-- y fn_mantenimiento_lifecycle cierran la fila vigente antes de abrir la
-- siguiente; este indice convierte la regla en garantia de la base de datos.
CREATE INDEX idx_historial_vehiculo ON historial_estado_vehiculo (id_vehiculo);
CREATE INDEX idx_historial_estado   ON historial_estado_vehiculo (id_estado);

CREATE UNIQUE INDEX uq_historial_estado_vigente
    ON historial_estado_vehiculo (id_vehiculo)
    WHERE fecha_fin IS NULL;
