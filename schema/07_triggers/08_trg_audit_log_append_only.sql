-- Hard-lock append-only sobre audit_log.
--
-- Defensa en profundidad:
--   * Primera linea: RLS sobre audit_log con USING(FALSE) para authenticated
--     y anon (declarada en 06_permissions/04_rls_policies.sql). Bloquea
--     UPDATE/DELETE desde la API pluginada de PostgREST.
--   * Segunda linea (este trigger): RAISE EXCEPTION en BEFORE UPDATE / DELETE.
--     Necesario porque cualquier rol que tenga BYPASSRLS o que NO sea
--     authenticated/anon (ej: el rol 'quique' del profesor con ALL
--     PRIVILEGES, postgres mismo via psql, service_role en operaciones
--     internas) podria modificar la tabla sin que las policies aplicaran.
--
-- Forma de saltearlo (solo documental): un SUPERUSER que ejecute
--   SET session_replication_role = replica;
-- desactiva todos los triggers. Eso queda registrado por pg_stat_statements
-- y los logs del cluster, asi que es un evento auditable a otro nivel. En
-- la practica, ningun rol no-superuser puede hacerlo.
--
-- Se usa session_user dentro del RAISE para identificar al rol HTTP real
-- (mismo motivo que en fn_audit_generic): aunque el trigger fuera
-- SECURITY DEFINER, session_user mantendria el rol que abrio la sesion
-- (ej: 'authenticated') en lugar de 'postgres'. Esto facilita atribuir
-- intentos maliciosos a sesiones concretas en los logs.

CREATE OR REPLACE FUNCTION fn_audit_log_append_only()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE EXCEPTION 'audit_log es append-only (operacion %, usuario %)',
        TG_OP, session_user
        USING ERRCODE = 'insufficient_privilege';
END;
$$;

DROP TRIGGER IF EXISTS trg_audit_log_no_update ON audit_log;

CREATE TRIGGER trg_audit_log_no_update
    BEFORE UPDATE OR DELETE ON audit_log
    FOR EACH ROW EXECUTE FUNCTION fn_audit_log_append_only();
