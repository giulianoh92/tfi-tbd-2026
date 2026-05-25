INSERT INTO tipo_reserva (nombre, descripcion, requiere_garantia, antelacion_max_dias) VALUES
    ('estandar',    'Reserva estandar con garantia',                    TRUE,  30),
    ('express',     'Retiro inmediato sin garantia',                    FALSE,  2),
    ('corporativa', 'Reserva de cuenta corporativa con voucher',        FALSE, 90);
