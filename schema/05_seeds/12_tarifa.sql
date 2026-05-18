-- One tarifa per (sucursal, tipo) combination covering vehicles in the seed.
-- UNIQUE(id_sucursal, id_tipo) prevents duplicates.
INSERT INTO tarifa (id_sucursal, id_tipo, precio_por_dia, porcentaje_recargo) VALUES
    (1, 1, 25000.00, 10.00),  -- Centro     - Sedan
    (1, 2, 35000.00, 12.00),  -- Centro     - SUV
    (2, 1, 26000.00, 10.00),  -- Palermo    - Sedan
    (2, 3, 32000.00, 15.00),  -- Palermo    - Cupe
    (3, 2, 36000.00, 12.00),  -- San Isidro - SUV
    (3, 4, 40000.00, 15.00),  -- San Isidro - Pickup
    (4, 1, 24000.00, 10.00),  -- Rosario    - Sedan
    (4, 5, 21000.00, 10.00),  -- Rosario    - Compacto
    (5, 2, 34000.00, 12.00),  -- Cordoba    - SUV
    (5, 1, 23000.00, 10.00);  -- Cordoba    - Sedan (extra tarifa for completeness)
