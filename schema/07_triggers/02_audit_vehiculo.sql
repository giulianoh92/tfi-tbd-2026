-- Disparador de auditoria para `vehiculo` (R1).
-- Se activa AFTER INSERT/UPDATE/DELETE y delega el registro a fn_audit_generic,
-- que inserta una fila en audit_log con la triple identidad de usuario y los
-- valores anteriores/nuevos serializados como JSONB.
DROP TRIGGER IF EXISTS trg_audit_vehiculo ON vehiculo;
CREATE TRIGGER trg_audit_vehiculo
    AFTER INSERT OR UPDATE OR DELETE ON vehiculo
    FOR EACH ROW
    EXECUTE FUNCTION fn_audit_generic();
