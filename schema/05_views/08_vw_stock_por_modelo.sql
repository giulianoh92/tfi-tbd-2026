-- vw_stock_por_modelo -- cuenta unidades DISPONIBLES agrupadas por (marca, modelo, anio).
-- Permite que el catalogo muestre "N disponibles de este modelo" sin que el usuario
-- tenga que contar patentes. Se apoya en vw_vehiculos_disponibles (solo unidades
-- con estado disponible y sucursal vigente).
CREATE OR REPLACE VIEW vw_stock_por_modelo
    WITH (security_invoker = true) AS
SELECT
    marca,
    modelo,
    anio,
    COUNT(*)::int AS unidades_disponibles
FROM vw_vehiculos_disponibles
GROUP BY marca, modelo, anio;

COMMENT ON VIEW vw_stock_por_modelo IS
'Catalogo: unidades disponibles por modelo (marca+modelo+anio). Lectura publica.';
