-- Tabla mantenimiento.
--
-- Registra cada envio de un vehiculo a un taller externo y su devolucion.
-- pa_enviar_mantenimiento_programado abre la fila con fecha_devolucion
-- NULL y activa el disparador fn_mantenimiento_lifecycle que transiciona
-- al vehiculo a estado 'en_mantenimiento'; pa_registrar_devolucion
-- _mantenimiento completa fecha_devolucion y el disparador devuelve al
-- vehiculo a 'disponible'. La fila con fecha_devolucion NULL representa el
-- mantenimiento en curso.
CREATE TABLE IF NOT EXISTS mantenimiento (
    id_mantenimiento  BIGSERIAL PRIMARY KEY,
    id_vehiculo       BIGINT    NOT NULL,
    id_taller         BIGINT    NOT NULL,
    fecha_envio       DATE      NOT NULL,
    fecha_devolucion  DATE      NULL,
    observaciones     TEXT,
    CONSTRAINT chk_mantenimiento_fechas CHECK (fecha_devolucion IS NULL OR fecha_devolucion >= fecha_envio)
);
