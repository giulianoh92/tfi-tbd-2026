-- Indices para devolucion_vencida (R9).
--
-- Casos de uso:
--   1) Panel /admin/devoluciones-vencidas: lista cronologica descendente
--      ("las ultimas detecciones primero"). idx_devolucion_vencida_fecha.
--   2) Vista "pendientes de notificar" (notificado = FALSE) con orden por
--      fecha: idx_devolucion_vencida_pendientes. Indice parcial sobre las
--      filas no notificadas (suelen ser pocas) para acelerar el filtro.
CREATE INDEX idx_devolucion_vencida_fecha
    ON devolucion_vencida (fecha_deteccion DESC);

CREATE INDEX idx_devolucion_vencida_pendientes
    ON devolucion_vencida (notificado, fecha_deteccion DESC);
