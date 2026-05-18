CREATE INDEX idx_historial_vehiculo ON historial_estado_vehiculo (id_vehiculo);
CREATE INDEX idx_historial_estado   ON historial_estado_vehiculo (id_estado);

CREATE UNIQUE INDEX uq_historial_estado_vigente
    ON historial_estado_vehiculo (id_vehiculo)
    WHERE fecha_fin IS NULL;
