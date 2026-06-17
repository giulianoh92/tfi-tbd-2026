-- vw_devoluciones_vencidas -- devoluciones vencidas con datos de cliente, vehiculo y sucursal
--
-- Etapa 2 (R3, R9): vista para el panel /admin/devoluciones-vencidas y para
-- recordatorios al cliente. Lee la tabla historica devolucion_vencida (poblada
-- por pa_detectar_devoluciones_vencidas via pg_cron) y la enriquece con
-- combinaciones legibles: cliente (nombre completo, dni, telefono, email del
-- usuario asociado), vehiculo (patente, marca, modelo) y sucursal_origen.
--
-- Filtra alquileres SIN devolucion real (a.fecha_devolucion_real IS NULL):
-- si el cliente ya regulariza la devolucion, el alquiler deja de ser
-- "vencido pendiente" y la fila desaparece de la vista (aunque siga
-- registrada en devolucion_vencida con fines historicos).
--
-- El email proviene de usuario.email via cliente.id_usuario; cliente no tiene
-- columna email propia (la fuente de credencial es el esquema `auth` y el alias
-- humano es `public`.usuario.email).
--
-- Acceso: SELECT a staff, authenticated (el cliente final ve solo SUS filas
-- via RLS sobre devolucion_vencida si esta configurada), service_role y
-- quique.

CREATE OR REPLACE VIEW vw_devoluciones_vencidas
    WITH (security_invoker = true) AS
SELECT
    dv.id_devolucion_vencida,
    dv.fecha_deteccion,
    dv.horas_excedidas              AS horas_vencidas,
    dv.notificado,
    a.id_alquiler,
    a.fecha_fin_prevista,
    -- Cliente
    c.id_cliente,
    (c.nombre || ' ' || c.apellido) AS cliente,
    c.dni,
    c.telefono,
    u.email,
    -- Vehiculo
    v.id_vehiculo,
    v.patente,
    (v.marca || ' ' || v.modelo)    AS vehiculo,
    -- Sucursal origen del vehiculo
    s.id_sucursal                   AS id_sucursal_origen,
    s.nombre                        AS sucursal_origen
FROM devolucion_vencida dv
JOIN alquiler   a ON a.id_alquiler  = dv.id_alquiler
JOIN cliente    c ON c.id_cliente   = dv.id_cliente
LEFT JOIN usuario u ON u.id_usuario = c.id_usuario
JOIN vehiculo   v ON v.id_vehiculo  = dv.id_vehiculo
JOIN sucursal   s ON s.id_sucursal  = v.id_sucursal_origen
WHERE a.fecha_devolucion_real IS NULL;

COMMENT ON VIEW vw_devoluciones_vencidas IS
'R3/R9 Etapa 2: devoluciones vencidas pendientes (alquiler sin fecha_devolucion_real) con datos de contacto (cliente, dni, telefono, email via usuario), vehiculo y sucursal de origen.';
