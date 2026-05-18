-- One tarifa per (sucursal, tipo) combination covering vehicles in the seed.
-- UNIQUE(id_sucursal, id_tipo) prevents duplicates.
-- porcentaje_recargo se almacena como fraccion decimal (0.10 = 10%) segun doc Etapa 1.
INSERT INTO tarifa (id_sucursal, id_tipo, precio_por_dia, porcentaje_recargo) VALUES
    (1, 1, 25000.00, 0.10),  -- Centro     - Sedan
    (1, 2, 35000.00, 0.12),  -- Centro     - SUV
    (2, 1, 26000.00, 0.10),  -- Palermo    - Sedan
    (2, 3, 32000.00, 0.15),  -- Palermo    - Cupe
    (3, 2, 36000.00, 0.12),  -- San Isidro - SUV
    (3, 4, 40000.00, 0.15),  -- San Isidro - Pickup
    (4, 1, 24000.00, 0.10),  -- Rosario    - Sedan
    (4, 5, 21000.00, 0.10),  -- Rosario    - Compacto
    (5, 2, 34000.00, 0.12),  -- Cordoba    - SUV
    (5, 1, 23000.00, 0.10);  -- Cordoba    - Sedan (extra tarifa for completeness)
