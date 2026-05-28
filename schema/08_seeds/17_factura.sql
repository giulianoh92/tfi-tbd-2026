-- Facturas para los 3 alquileres cerrados de la carga inicial (id 1, 2, 3).
-- Valores literales precalculados para que coincidan exactamente con lo que
-- produciria fn_calcular_factura(id_alquiler) si se invocara luego de la carga:
--   horas_excedidas redondeadas hacia arriba (CEIL), como hace la funcion.
--   porcentaje_recargo_aplicado en formato fraccion (0.10 = 10%).
-- Formulas de facturacion (las mismas que aplica fn_calcular_factura):
--   costo_base        = dias_pactados * precio_por_dia_aplicado
--   recargo_excedente = horas_excedidas * (precio_por_dia_aplicado / 24) * porcentaje_recargo_aplicado
--   total             = costo_base + recargo_excedente
-- Numero correlativo via seq_numero_factura (aporte original Marcia Viera).

-- Factura 1: alquiler 1 (Fiat Cronos, tarifa Posadas-Sedan: 29000 / 0.10)
-- 5 dias, devolucion 2h30m tarde (CEIL -> 3h)
-- costo_base = 5 * 29000 = 145000
-- recargo    = 3 * (29000/24) * 0.10 = 362.50
INSERT INTO factura (id_alquiler, id_cliente, numero_factura, fecha_emision,
    precio_por_dia_aplicado, porcentaje_recargo_aplicado,
    costo_base, horas_excedidas, recargo_excedente, total)
VALUES (1, 1, 'FAC-' || LPAD(NEXTVAL('seq_numero_factura')::TEXT, 6, '0'), '2026-01-15',
    29000.00, 0.10,
    145000.00, 3.00, 362.50, 145362.50);

-- Factura 2: alquiler 2 (Toyota Corolla, tarifa Posadas-Sedan: 29000 / 0.10)
-- 7 dias, devolucion 22h tarde
-- costo_base = 7 * 29000 = 203000
-- recargo    = 22 * (29000/24) * 0.10 = 2658.33
INSERT INTO factura (id_alquiler, id_cliente, numero_factura, fecha_emision,
    precio_por_dia_aplicado, porcentaje_recargo_aplicado,
    costo_base, horas_excedidas, recargo_excedente, total)
VALUES (2, 2, 'FAC-' || LPAD(NEXTVAL('seq_numero_factura')::TEXT, 6, '0'), '2026-01-28',
    29000.00, 0.10,
    203000.00, 22.00, 2658.33, 205658.33);

-- Factura 3: alquiler 3 (Jeep Renegade, tarifa Iguazu-SUV: 48000 / 0.12)
-- 4 dias, devolucion 1h tarde
-- costo_base = 4 * 48000 = 192000
-- recargo    = 1 * (48000/24) * 0.12 = 240.00
INSERT INTO factura (id_alquiler, id_cliente, numero_factura, fecha_emision,
    precio_por_dia_aplicado, porcentaje_recargo_aplicado,
    costo_base, horas_excedidas, recargo_excedente, total)
VALUES (3, 5, 'FAC-' || LPAD(NEXTVAL('seq_numero_factura')::TEXT, 6, '0'), '2026-02-05',
    48000.00, 0.12,
    192000.00, 1.00, 240.00, 192240.00);
