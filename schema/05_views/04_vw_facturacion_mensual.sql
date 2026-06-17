-- vw_facturacion_mensual -- agregado mensual de factura agrupado por sucursal_origen del vehiculo
--
-- Etapa 2 (R3): vista para reportes gerenciales. Por cada mes y sucursal
-- (resuelta como sucursal_origen del vehiculo del alquiler facturado), suma:
--   * facturas_emitidas    = cantidad de facturas en el mes
--   * total_costo_base     = SUM(factura.costo_base)
--   * total_recargos       = SUM(factura.recargo_excedente)
--   * total_facturado      = SUM(factura.total)
--   * ticket_promedio      = AVG(factura.total)
--
-- mes se devuelve como DATE_TRUNC('month', fecha_emision)::DATE (el primer
-- dia del mes), lo que permite ordenar y filtrar facilmente desde la
-- aplicacion sin manipular formatos de cadena.
--
-- La sucursal usada para agrupar es la sucursal de alta del vehiculo
-- alquilado (v.id_sucursal_origen). Si en el futuro se decide imputar la
-- facturacion a la sucursal de retiro o de devolucion, la regla cambia aqui
-- en un solo punto.
--
-- Acceso: SELECT a staff, authenticated (gerencia/personal), service_role y quique.
-- El cliente final no debe ver el agregado completo: se restringe via GRANT.

CREATE OR REPLACE VIEW vw_facturacion_mensual
    WITH (security_invoker = true) AS
SELECT
    DATE_TRUNC('month', f.fecha_emision)::DATE  AS mes,
    s.id_sucursal,
    s.nombre                                    AS sucursal,
    COUNT(*)                                    AS facturas_emitidas,
    SUM(f.costo_base)                           AS total_costo_base,
    SUM(f.recargo_excedente)                    AS total_recargos,
    SUM(f.total)                                AS total_facturado,
    AVG(f.total)                                AS ticket_promedio
FROM factura f
JOIN alquiler a ON a.id_alquiler  = f.id_alquiler
JOIN vehiculo v ON v.id_vehiculo  = a.id_vehiculo
JOIN sucursal s ON s.id_sucursal  = v.id_sucursal_origen
GROUP BY DATE_TRUNC('month', f.fecha_emision), s.id_sucursal, s.nombre;

COMMENT ON VIEW vw_facturacion_mensual IS
'R3 Etapa 2: facturacion agregada por mes (DATE_TRUNC) y sucursal_origen del vehiculo. Retorna facturas_emitidas, total_costo_base, total_recargos, total_facturado y ticket_promedio.';
