-- vw_vehiculos_disponibles -- catalogo de vehiculos en estado 'disponible' con sucursal y tarifa vigente
--
-- Etapa 2 (R3): vista de consulta para el panel del personal y el catalogo
-- de la aplicacion cliente. Consolida la combinacion entre vehiculo +
-- estado_vehiculo + ubicacion_vehiculo (vigente, fecha_hasta IS NULL) +
-- sucursal + tipo_vehiculo + tarifa. Evita consultas multiples desde el
-- cliente y centraliza la regla "disponible y vigente" en un unico punto.
--
-- Resolucion de "sucursal actual":
--   Se prefiere la fila vigente de ubicacion_vehiculo (fecha_hasta IS NULL).
--   Si no hay fila de ubicacion vigente, se usa vehiculo.id_sucursal_origen
--   (sucursal de alta original del vehiculo). Esto cubre el periodo entre el
--   alta del vehiculo y la primera relocacion fisica.
--
-- Resolucion de tarifa:
--   La tarifa se selecciona por (id_sucursal_actual, id_tipo). Si la sucursal
--   donde reside hoy el vehiculo no tiene tarifa cargada para ese tipo, las
--   columnas precio_por_dia y porcentaje_recargo quedan NULL.
--
-- Acceso: SELECT permitido a roles staff, authenticated, anon (catalogo publico)
-- y al rol del profesor quique. La tabla vehiculo no tiene RLS porque el
-- catalogo es de acceso publico; las tablas combinadas tampoco filtran por usuario.

CREATE OR REPLACE VIEW vw_vehiculos_disponibles
    WITH (security_invoker = true) AS
SELECT
    v.id_vehiculo,
    v.marca,
    v.modelo,
    v.anio,
    v.patente,
    v.km_actuales,
    v.detalle_confort,
    tv.nombre        AS tipo,
    s.id_sucursal    AS id_sucursal_actual,
    s.nombre         AS sucursal_actual,
    s.ciudad         AS sucursal_ciudad,
    t.precio_por_dia,
    t.porcentaje_recargo
FROM vehiculo v
JOIN estado_vehiculo ev
  ON ev.id_estado = v.id_estado
JOIN tipo_vehiculo tv
  ON tv.id_tipo = v.id_tipo
LEFT JOIN LATERAL (
    SELECT uv.id_sucursal
    FROM ubicacion_vehiculo uv
    WHERE uv.id_vehiculo = v.id_vehiculo
      AND uv.fecha_hasta IS NULL
    ORDER BY uv.fecha_desde DESC
    LIMIT 1
) uv_vigente ON TRUE
JOIN sucursal s
  ON s.id_sucursal = COALESCE(uv_vigente.id_sucursal, v.id_sucursal_origen)
LEFT JOIN tarifa t
  ON t.id_sucursal = s.id_sucursal
 AND t.id_tipo     = v.id_tipo
WHERE ev.nombre = 'disponible';

COMMENT ON VIEW vw_vehiculos_disponibles IS
'R3 Etapa 2: vehiculos en estado disponible con su sucursal vigente (ubicacion_vehiculo.fecha_hasta IS NULL, con valor de respaldo en id_sucursal_origen) y la tarifa actual segun (sucursal, tipo).';
