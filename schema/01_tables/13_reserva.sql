-- Tabla reserva (R6, R7, R8).
--
-- Registra cada solicitud de reserva de un vehiculo por parte de un cliente
-- para un periodo determinado. Eje de tres requisitos:
--   * R6: el alquiler puede originarse en una reserva previa (alquiler
--     .id_reserva apunta aca) o ser presencial (sin reserva).
--   * R7: pa_registrar_reserva valida disponibilidad, superposicion
--     temporal y limites del tipo_reserva antes de insertar aca.
--   * R8: pa_cancelar_reserva valida estado y pasa la fila de 'pendiente'
--     a 'cancelada' segun reglas de negocio.
-- La superposicion temporal entre reservas y alquileres del mismo vehiculo
-- la garantiza una constraint EXCLUDE definida en 02_constraints (no en
-- esta tabla, porque cruza reserva + alquiler).
CREATE TABLE IF NOT EXISTS reserva (
    id_reserva          BIGSERIAL PRIMARY KEY,
    id_cliente          BIGINT    NOT NULL,
    id_vehiculo         BIGINT    NOT NULL,
    id_tipo_reserva     BIGINT    NOT NULL,
    fecha_inicio        TIMESTAMP NOT NULL,
    fecha_fin_prevista  TIMESTAMP NOT NULL,
    estado              VARCHAR(20) NOT NULL DEFAULT 'pendiente',
    fecha_creacion      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    motivo_cancelacion  TEXT,
    CONSTRAINT chk_reserva_estado  CHECK (estado IN ('pendiente', 'concretada', 'cancelada')),
    CONSTRAINT chk_reserva_fechas  CHECK (fecha_fin_prevista > fecha_inicio)
);

-- Idempotente: agrega la columna en bases ya existentes (R8 motivo de cancelacion).
ALTER TABLE reserva ADD COLUMN IF NOT EXISTS motivo_cancelacion TEXT;
