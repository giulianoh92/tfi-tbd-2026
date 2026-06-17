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

-- Facturas de mayo 2026 para los alquileres cerrados 6-10. Alimentan el cierre
-- contable mensual (R13): pa_cerrar_facturacion_mensual agrega estas facturas
-- por sucursal de origen del vehiculo. Mezcla deliberada de recargos (algunos
-- > 0 por devolucion tardia, otros = 0 por devolucion en hora) y totales/km
-- variados. Numeracion correlativa via seq_numero_factura.

-- Factura 4: alquiler 6 (v1 Fiat Cronos, tarifa Posadas-Sedan: 29000 / 0.10)
-- 5 dias, devolucion 4h tarde
-- costo_base = 5 * 29000 = 145000
-- recargo    = 4 * (29000/24) * 0.10 = 483.33
INSERT INTO factura (id_alquiler, id_cliente, numero_factura, fecha_emision,
    precio_por_dia_aplicado, porcentaje_recargo_aplicado,
    costo_base, horas_excedidas, recargo_excedente, total)
VALUES (6, 1, 'FAC-' || LPAD(NEXTVAL('seq_numero_factura')::TEXT, 6, '0'), '2026-05-10',
    29000.00, 0.10,
    145000.00, 4.00, 483.33, 145483.33);

-- Factura 5: alquiler 7 (v4 Chevrolet Onix, tarifa Obera-Compacto: 22000 / 0.08)
-- 4 dias, devolucion en hora (sin recargo)
-- costo_base = 4 * 22000 = 88000
INSERT INTO factura (id_alquiler, id_cliente, numero_factura, fecha_emision,
    precio_por_dia_aplicado, porcentaje_recargo_aplicado,
    costo_base, horas_excedidas, recargo_excedente, total)
VALUES (7, 3, 'FAC-' || LPAD(NEXTVAL('seq_numero_factura')::TEXT, 6, '0'), '2026-05-12',
    22000.00, 0.08,
    88000.00, 0.00, 0.00, 88000.00);

-- Factura 6: alquiler 8 (v7 Toyota SW4, tarifa Iguazu-SUV: 48000 / 0.12)
-- 7 dias, devolucion 5h tarde
-- costo_base = 7 * 48000 = 336000
-- recargo    = 5 * (48000/24) * 0.12 = 1200.00
INSERT INTO factura (id_alquiler, id_cliente, numero_factura, fecha_emision,
    precio_por_dia_aplicado, porcentaje_recargo_aplicado,
    costo_base, horas_excedidas, recargo_excedente, total)
VALUES (8, 2, 'FAC-' || LPAD(NEXTVAL('seq_numero_factura')::TEXT, 6, '0'), '2026-05-19',
    48000.00, 0.12,
    336000.00, 5.00, 1200.00, 337200.00);

-- Factura 7: alquiler 9 (v8 Renault Kangoo, tarifa Corrientes-Utilitario: 24000 / 0.08)
-- 3 dias, devolucion en hora (sin recargo)
-- costo_base = 3 * 24000 = 72000
INSERT INTO factura (id_alquiler, id_cliente, numero_factura, fecha_emision,
    precio_por_dia_aplicado, porcentaje_recargo_aplicado,
    costo_base, horas_excedidas, recargo_excedente, total)
VALUES (9, 4, 'FAC-' || LPAD(NEXTVAL('seq_numero_factura')::TEXT, 6, '0'), '2026-05-18',
    24000.00, 0.08,
    72000.00, 0.00, 0.00, 72000.00);

-- Factura 8: alquiler 10 (v10 VW T-Cross, tarifa Resistencia-SUV: 40000 / 0.12)
-- 6 dias, devolucion 10h tarde
-- costo_base = 6 * 40000 = 240000
-- recargo    = 10 * (40000/24) * 0.12 = 2000.00
INSERT INTO factura (id_alquiler, id_cliente, numero_factura, fecha_emision,
    precio_por_dia_aplicado, porcentaje_recargo_aplicado,
    costo_base, horas_excedidas, recargo_excedente, total)
VALUES (10, 5, 'FAC-' || LPAD(NEXTVAL('seq_numero_factura')::TEXT, 6, '0'), '2026-05-26',
    40000.00, 0.12,
    240000.00, 10.00, 2000.00, 242000.00);
