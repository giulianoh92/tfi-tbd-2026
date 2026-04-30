-- Una tarifa por cada combinacion (sucursal, tipo) que aparece en vehiculos.
-- UNIQUE(id_sucursal, id_tipo) impide duplicados.
INSERT INTO tarifa (id_sucursal, id_tipo, precio_por_dia, porcentaje_recargo) VALUES
    (1, 1, 25000.00, 10.00),  -- Centro     - Sedan
    (1, 2, 35000.00, 12.00),  -- Centro     - SUV
    (2, 1, 26000.00, 10.00),  -- Palermo    - Sedan
    (2, 3, 32000.00, 15.00),  -- Palermo    - Cupe
    (2, 4, 22000.00, 10.00),  -- Palermo    - Hatchback
    (3, 2, 36000.00, 12.00),  -- San Isidro - SUV
    (3, 5, 40000.00, 15.00),  -- San Isidro - Pickup
    (4, 1, 24000.00, 10.00),  -- Rosario    - Sedan
    (4, 4, 21000.00, 10.00),  -- Rosario    - Hatchback
    (5, 2, 34000.00, 12.00);  -- Cordoba    - SUV
