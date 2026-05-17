-- Auditoría de Estados de Flota
CREATE TABLE IF NOT EXISTS historial_estado_vehiculo (
    id_historial_estado BIGSERIAL      PRIMARY KEY,
    id_vehiculo         BIGINT         NOT NULL,
    estado              VARCHAR(20)    NOT NULL, 
    fecha_inicio        TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_fin           TIMESTAMP,     
    motivo              VARCHAR(255),  
    
    CONSTRAINT chk_historial_estados_validos CHECK (
        estado IN ('disponible', 'alquilado', 'mantenimiento')
    ),
    CONSTRAINT chk_historial_fechas CHECK (
        fecha_fin IS NULL OR fecha_fin >= fecha_inicio
    ),
    CONSTRAINT fk_historial_vehiculo FOREIGN KEY (id_vehiculo) REFERENCES vehiculo(id_vehiculo) ON DELETE CASCADE
);