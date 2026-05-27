-- vw_usuario_legible -- resuelve un auth.users.id (UUID) a un nombre humano para el panel staff.
-- Usada por /admin/auditoria para no mostrar UUIDs crudos. Joinea cliente (clientes
-- finales) y auth.users (incluye staff). Gateada por fn_es_staff(): un no-staff
-- obtiene cero filas.
--
-- Vive en 06_permissions (no en 05_views) por dos motivos:
--   1) Depende de fn_es_staff(), definida en 02_rls_helpers (mismo directorio,
--      orden lexico posterior, ya disponible cuando corre este archivo).
--   2) Referencia auth.users (schema de Supabase Auth). En entornos sin Supabase
--      (Postgres puro / CI de validacion) ese schema no existe, por eso el bloque
--      DO solo crea la vista si auth.users esta presente; si no, la omite sin error.
--
-- La vista corre con privilegios del owner (NO security_invoker), por eso puede
-- leer auth.users; fn_es_staff() igual evalua el JWT del caller en cada query.

DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = 'auth' AND table_name = 'users'
    ) THEN
        EXECUTE $v$
            CREATE OR REPLACE VIEW vw_usuario_legible AS
            SELECT
                au.id,
                COALESCE(
                    NULLIF(trim(c.nombre || ' ' || c.apellido), ''),
                    au.email,
                    au.id::text
                ) AS nombre,
                au.email
            FROM auth.users au
            LEFT JOIN cliente c ON c.auth_user_id = au.id
            WHERE fn_es_staff();
        $v$;

        EXECUTE $c$
            COMMENT ON VIEW vw_usuario_legible IS
            'R1 Etapa 2: resuelve UUID de actor de auditoria a nombre legible. Solo staff (fn_es_staff).';
        $c$;

        GRANT SELECT ON vw_usuario_legible TO quique, authenticated, service_role;
    ELSE
        RAISE NOTICE 'auth.users no existe; se omite vw_usuario_legible (entorno sin Supabase Auth).';
    END IF;
END
$$;
