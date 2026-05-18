-- 10 tarifas por (id_sucursal, id_tipo). UNIQUE(id_sucursal, id_tipo) impide
-- duplicados. Valores 2026 representativos del mercado argentino NEA, en pesos.
-- porcentaje_recargo en formato fraccion (0.10 = 10%) segun doc Etapa 1.
--
-- Estrategia de precios:
--   * Pickups en Iguazu/Resistencia: premium (turismo aventura + uso rural)
--   * SUVs: gama media-alta
--   * Compactos/Utilitarios: gama baja, rotacion alta
--   * Recargos mas altos en categorias donde el costo de oportunidad
--     por entrega tardia es mayor (pickups y SUVs).
--
-- Tarifas requeridas por el seed actual (vehiculos + alquileres):
--   id=1 -> Posadas    + Sedan       (vehiculos 1, 2; alquileres 1, 2)
--   id=2 -> Posadas    + SUV
--   id=3 -> Obera      + Compacto    (vehiculos 3, 4; alquiler 4)
--   id=4 -> Obera      + Pickup      (vehiculo 5)
--   id=5 -> Iguazu     + SUV         (vehiculos 6, 7; alquiler 3)
--   id=6 -> Iguazu     + Pickup
--   id=7 -> Corrientes + Pickup      (vehiculo 9; alquiler 5)
--   id=8 -> Corrientes + Utilitario  (vehiculo 8)
--   id=9 -> Resistencia+ Compacto
--   id=10 -> Resistencia+ SUV        (vehiculo 10)
INSERT INTO tarifa (id_sucursal, id_tipo, precio_por_dia, porcentaje_recargo) VALUES
    (1, 2, 29000.00, 0.10),  -- Posadas    - Sedan
    (1, 3, 42000.00, 0.12),  -- Posadas    - SUV
    (2, 1, 22000.00, 0.08),  -- Obera      - Compacto
    (2, 4, 45000.00, 0.15),  -- Obera      - Pickup
    (3, 3, 48000.00, 0.12),  -- Iguazu     - SUV
    (3, 4, 55000.00, 0.15),  -- Iguazu     - Pickup (premium turismo aventura)
    (4, 4, 46000.00, 0.15),  -- Corrientes - Pickup
    (4, 5, 24000.00, 0.08),  -- Corrientes - Utilitario
    (5, 1, 23000.00, 0.08),  -- Resistencia- Compacto
    (5, 3, 40000.00, 0.12);  -- Resistencia- SUV
