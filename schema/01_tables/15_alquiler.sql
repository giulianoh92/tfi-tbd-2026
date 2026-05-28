-- Tabla alquiler (R6, R10).
--
-- Representa cada contrato de alquiler efectivamente concretado. Diseno:
--   * id_reserva es NULL UNIQUE: cubre R6 (alquileres con o sin reserva
--     previa). Si proviene de una reserva, apunta a la fila correspondiente
--     en reserva; si es presencial, queda NULL. El UNIQUE evita que una
--     misma reserva genere mas de un alquiler.
--   * id_sucursal_devolucion NULL: se completa al cerrar el alquiler; si
--     difiere de la sucursal de origen del vehiculo, el disparador de cierre
--     actualiza la ubicacion en ubicacion_vehiculo.
--   * estado actua como maquina de estados ('activo' -> 'cerrado'). La
--     transicion la dispara pa_finalizar_alquiler y el disparador
--     fn_alquiler_lifecycle se encarga de actualizar el estado del vehiculo,
--     registrar en el historial y emitir la factura (R10).
CREATE TABLE IF NOT EXISTS alquiler (
    id_alquiler              BIGSERIAL PRIMARY KEY,
    id_reserva               BIGINT    NULL UNIQUE,
    id_cliente               BIGINT    NOT NULL,
    id_vehiculo              BIGINT    NOT NULL,
    id_tarifa                BIGINT    NOT NULL,
    id_sucursal_devolucion   BIGINT    NULL,
    fecha_inicio             TIMESTAMP NOT NULL,
    fecha_fin_prevista       TIMESTAMP NOT NULL,
    fecha_devolucion_real    TIMESTAMP NULL,
    km_inicio                INTEGER   NOT NULL,
    km_fin                   INTEGER   NULL,
    estado                   VARCHAR(20) NOT NULL DEFAULT 'activo',
    CONSTRAINT chk_alquiler_estado  CHECK (estado IN ('activo', 'cerrado')),
    CONSTRAINT chk_alquiler_fechas  CHECK (fecha_fin_prevista > fecha_inicio),
    CONSTRAINT chk_alquiler_km      CHECK (km_inicio >= 0 AND (km_fin IS NULL OR km_fin >= km_inicio))
);
