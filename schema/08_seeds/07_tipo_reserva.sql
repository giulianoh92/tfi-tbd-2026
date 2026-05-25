-- Datos demo del catalogo tipo_reserva (R7).
-- Tres modalidades que ejercitan las dos politicas declarativas del tipo:
--   * estandar:    requiere garantia, antelacion maxima de 30 dias.
--   * express:     sin garantia, antelacion corta (2 dias) para retiros rapidos.
--   * corporativa: sin garantia (voucher empresa), antelacion amplia (90 dias).
-- pa_registrar_reserva valida ambas politicas contra estos valores antes
-- de insertar en reserva.
INSERT INTO tipo_reserva (nombre, descripcion, requiere_garantia, antelacion_max_dias) VALUES
    ('estandar',    'Reserva estandar con garantia',                    TRUE,  30),
    ('express',     'Retiro inmediato sin garantia',                    FALSE,  2),
    ('corporativa', 'Reserva de cuenta corporativa con voucher',        FALSE, 90);
