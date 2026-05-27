-- Grants de SELECT sobre las vistas de Etapa 2 (schema/05_views/*).
--
-- Roles destino:
--   * quique         -- profesor / evaluador (rol LOGIN propio)
--   * authenticated  -- usuarios con sesion Supabase (incluye staff y clientes;
--                       la RLS de las tablas subyacentes filtra por id_cliente
--                       cuando aplica). Sobre alquiler/reserva el cliente final
--                       ve solo sus propias filas; el staff ve todas via la
--                       policy que chequea fn_es_staff().
--   * anon           -- requests sin sesion (catalogo publico de vehiculos).
--                       Para vistas no publicas (facturacion, audit) la
--                       sensibilidad NO esta en la vista sino en la RLS de las
--                       tablas: anon sigue sin poder leer factura ni audit_log.
--   * service_role   -- rol interno de Supabase / Edge Functions (BYPASSRLS).
--
-- No otorgamos a roles "staff" ni "cliente" como roles Postgres porque NO
-- existen como tales en este schema: staff/cliente son claims del JWT, no
-- roles del cluster. El gating fino lo hace la RLS via fn_es_staff() /
-- fn_cliente_del_usuario() sobre las tablas base.
--
-- Idempotente: GRANT SELECT es seguro de reaplicar. El bloque DO envuelve los
-- grants en EXCEPTION WHEN OTHERS para que el apply siga aun si alguno de los
-- roles Supabase no existe en el entorno actual (ej: postgres puro sin
-- Supabase, donde igual existen porque 00_supabase_roles.sql los crea).

DO $$
BEGIN
    -- vw_vehiculos_disponibles -- catalogo (lectura publica)
    GRANT SELECT ON vw_vehiculos_disponibles
        TO quique, authenticated, anon, service_role;

    -- vw_alquileres_activos -- gated por RLS de alquiler para cliente final
    GRANT SELECT ON vw_alquileres_activos
        TO quique, authenticated, service_role;

    -- vw_reservas_pendientes -- gated por RLS de reserva para cliente final
    GRANT SELECT ON vw_reservas_pendientes
        TO quique, authenticated, service_role;

    -- vw_facturacion_mensual -- reporte gerencial (staff via RLS sobre factura)
    GRANT SELECT ON vw_facturacion_mensual
        TO quique, authenticated, service_role;

    -- vw_devoluciones_vencidas -- panel staff
    GRANT SELECT ON vw_devoluciones_vencidas
        TO quique, authenticated, service_role;

    -- vw_audit_log_legible -- panel auditoria staff
    GRANT SELECT ON vw_audit_log_legible
        TO quique, authenticated, service_role;

    -- vw_usuario_legible -- su GRANT vive en 10_vw_usuario_legible.sql, dentro del
    -- mismo bloque condicional que crea la vista (depende de auth.users / Supabase).

    -- vw_stock_por_modelo -- conteo publico de unidades disponibles por modelo
    GRANT SELECT ON vw_stock_por_modelo
        TO quique, authenticated, anon, service_role;
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Grants sobre vistas omitidos: %', SQLERRM;
END
$$;
