-- Indice de soporte para la FK garantia_reserva -> reserva (R7).
--
-- Acelera la consulta "garantia de esta reserva" que ejecuta el procedure
-- pa_registrar_reserva al validar la presencia de garantia cuando el
-- tipo_reserva.requiere_garantia es TRUE.
CREATE INDEX idx_garantia_reserva_reserva ON garantia_reserva (id_reserva);
