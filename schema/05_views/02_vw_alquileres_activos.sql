-- vw_alquileres_activos -- alquileres con estado='activo' enriquecidos con cliente, vehiculo, sucursal y tarifa
--
-- Etapa 2 (R3): vista para el panel /admin/alquileres y la operativa de cierre.
-- Resuelve en una sola consulta lo que la aplicacion cliente realizaba con
-- varias peticiones en cascada (cliente + vehiculo + sucursal_origen del
-- vehiculo + tarifa aplicada).
--
-- Columnas calculadas:
--   duracion_actual   = NOW() - fecha_inicio
--   tiempo_restante   = fecha_fin_prevista - NOW()  (negativo si esta vencido)
--
-- "Sucursal origen" aqui refiere a la sucursal de alta del vehiculo. No
-- se modela una sucursal "de retiro" del alquiler porque el dominio no la
-- guarda como columna propia (la devolucion si tiene id_sucursal_devolucion).
--
-- Acceso: SELECT a staff, authenticated (el cliente final ve solo SUS
-- alquileres via la RLS de la tabla alquiler), service_role y quique.

CREATE OR REPLACE VIEW vw_alquileres_activos
    WITH (security_invoker = true) AS
SELECT
    a.id_alquiler,
    a.fecha_inicio,
    a.fecha_fin_prevista,
    a.fecha_devolucion_real,
    a.km_inicio,
    a.km_fin,
    a.estado,
    -- Cliente
    c.id_cliente,
    c.nombre        AS cliente_nombre,
    c.apellido      AS cliente_apellido,
    c.dni           AS cliente_dni,
    -- Vehiculo
    v.id_vehiculo,
    v.patente,
    v.marca,
    v.modelo,
    -- Sucursal origen del vehiculo
    s.id_sucursal   AS id_sucursal_origen,
    s.nombre        AS sucursal_origen,
    s.ciudad        AS sucursal_ciudad,
    -- Tarifa aplicada al alquiler
    t.id_tarifa,
    t.precio_por_dia,
    t.porcentaje_recargo,
    -- Calculados
    (NOW() - a.fecha_inicio)            AS duracion_actual,
    (a.fecha_fin_prevista - NOW())      AS tiempo_restante
FROM alquiler a
JOIN cliente   c ON c.id_cliente   = a.id_cliente
JOIN vehiculo  v ON v.id_vehiculo  = a.id_vehiculo
JOIN sucursal  s ON s.id_sucursal  = v.id_sucursal_origen
JOIN tarifa    t ON t.id_tarifa    = a.id_tarifa
WHERE a.estado = 'activo';

COMMENT ON VIEW vw_alquileres_activos IS
'R3 Etapa 2: alquileres activos con combinacion cliente + vehiculo + sucursal_origen del vehiculo + tarifa aplicada. duracion_actual y tiempo_restante calculados contra NOW().';
