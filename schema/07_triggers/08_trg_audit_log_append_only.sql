-- Bloqueo estricto de solo insercion sobre audit_log.
--
-- Defensa en capas:
--   * Primera capa: RLS sobre audit_log con USING(FALSE) para authenticated
--     y anon (declarada en 06_permissions/04_rls_policies.sql). Bloquea
--     UPDATE/DELETE desde la API expuesta por PostgREST.
--   * Segunda capa (este disparador): RAISE EXCEPTION en BEFORE UPDATE / DELETE.
--     Necesario porque cualquier rol que tenga BYPASSRLS o que NO sea
--     authenticated/anon (ej: el rol 'quique' del profesor con ALL
--     PRIVILEGES, postgres mismo via psql, service_role en operaciones
--     internas) podria modificar la tabla sin que las politicas aplicaran.
--
-- Unica forma de eludir este mecanismo (solo documental): un superusuario
-- que ejecute:
--   SET session_replication_role = replica;
-- desactiva todos los disparadores. Eso queda registrado en
-- pg_stat_statements y en los registros del cluster, por lo que es un
-- evento rastreable a otro nivel. En la practica, ningun usuario sin
-- privilegios de administrador puede hacerlo.
--
-- Se usa session_user dentro del RAISE para identificar el rol de la sesion
-- real (mismo criterio que en fn_audit_generic): aunque el disparador fuera
-- SECURITY DEFINER, session_user mantiene el rol que abrio la sesion
-- (ej: 'authenticated') en lugar de 'postgres'. Esto facilita atribuir
-- intentos no autorizados a sesiones concretas en los registros del servidor.

CREATE OR REPLACE FUNCTION fn_audit_log_append_only()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE EXCEPTION 'audit_log es de solo insercion (operacion %, usuario %)',
        TG_OP, session_user
        USING ERRCODE = 'insufficient_privilege';
END;
$$;

DROP TRIGGER IF EXISTS trg_audit_log_no_update ON audit_log;

CREATE TRIGGER trg_audit_log_no_update
    BEFORE UPDATE OR DELETE ON audit_log
    FOR EACH ROW EXECUTE FUNCTION fn_audit_log_append_only();
