-- Facturas for the 3 closed alquileres (1, 2, 3).
-- Formulas (porcentaje stored as e.g. 10.00 meaning 10%, factor = /100):
--   costo_base = dias * precio_por_dia_aplicado
--   recargo_excedente = horas_excedidas * (precio_por_dia_aplicado / 24) * (porcentaje_recargo_aplicado / 100)
--   total = costo_base + recargo_excedente

-- Alquiler 1: vehiculo 1, 5 dias (2026-01-10 a 2026-01-15), devolucion 2h30m tarde
-- costo_base = 5 * 25000 = 125000
-- recargo = 2.5 * (25000/24) * (10/100) = 260.42
INSERT INTO factura (id_alquiler, id_cliente, numero_factura, fecha_emision,
    precio_por_dia_aplicado, porcentaje_recargo_aplicado,
    costo_base, horas_excedidas, recargo_excedente, total)
VALUES (1, 1, 'F-2026-00001', '2026-01-15',
    25000.00, 10.00,
    125000.00, 2.50, 260.42, 125260.42);

-- Alquiler 2: vehiculo 2, 7 dias (2026-01-20 a 2026-01-27), devolucion 22h tarde
-- costo_base = 7 * 35000 = 245000
-- recargo = 22 * (35000/24) * (12/100) = 3850.00
INSERT INTO factura (id_alquiler, id_cliente, numero_factura, fecha_emision,
    precio_por_dia_aplicado, porcentaje_recargo_aplicado,
    costo_base, horas_excedidas, recargo_excedente, total)
VALUES (2, 2, 'F-2026-00002', '2026-01-28',
    35000.00, 12.00,
    245000.00, 22.00, 3850.00, 248850.00);

-- Alquiler 3: vehiculo 6, 4 dias (2026-02-01 a 2026-02-05), devolucion 1h tarde
-- costo_base = 4 * 36000 = 144000
-- recargo = 1 * (36000/24) * (12/100) = 180.00
INSERT INTO factura (id_alquiler, id_cliente, numero_factura, fecha_emision,
    precio_por_dia_aplicado, porcentaje_recargo_aplicado,
    costo_base, horas_excedidas, recargo_excedente, total)
VALUES (3, 5, 'F-2026-00003', '2026-02-05',
    36000.00, 12.00,
    144000.00, 1.00, 180.00, 144180.00);
