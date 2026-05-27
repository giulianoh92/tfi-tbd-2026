-- vw_usuario_legible -- resuelve un auth.users.id (UUID) a un nombre humano para el panel staff.
-- Usada por /admin/auditoria para no mostrar UUIDs crudos. Joinea cliente (clientes
-- finales) y auth.users (incluye staff). Gateada por fn_es_staff(): un no-staff
-- obtiene cero filas. La vista corre con privilegios del owner (NO security_invoker),
-- por eso puede leer auth.users; fn_es_staff() igual evalua el JWT del caller.
CREATE OR REPLACE VIEW vw_usuario_legible AS
SELECT
    au.id,
    COALESCE(NULLIF(trim(c.nombre || ' ' || c.apellido), ''), au.email, au.id::text) AS nombre,
    au.email
FROM auth.users au
LEFT JOIN cliente c ON c.auth_user_id = au.id
WHERE fn_es_staff();

COMMENT ON VIEW vw_usuario_legible IS
'R1 Etapa 2: resuelve UUID de actor de auditoria a nombre legible. Solo staff (fn_es_staff).';
