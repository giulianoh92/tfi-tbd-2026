-- Una factura por cada alquiler finalizado (alquileres 1, 2 y 3).
-- Calculos:
--   factura 1: 5 dias x 25000 = 125000, sin recargo
--   factura 2: 8 dias x 24000 = 192000, 24 hs de retraso (10% de recargo) = 26400 -> total 218400
--   factura 3: 5 dias x 22000 = 110000, sin recargo
INSERT INTO factura (id_alquiler, id_cliente, numero_factura, fecha_emision, costo_base, horas_excedidas, recargo_excedente, total) VALUES
    (1, 1, 'A-0001-00000001', '2026-01-20 10:30', 125000.00,  0.00,     0.00, 125000.00),
    (2, 3, 'A-0001-00000002', '2026-03-01 13:00', 192000.00, 24.00, 26400.00, 218400.00),
    (3, 6, 'A-0001-00000003', '2026-03-15 11:30', 110000.00,  0.00,     0.00, 110000.00);
