-- Trigger de auditoria para `vehiculo` (R1).
DROP TRIGGER IF EXISTS trg_audit_vehiculo ON vehiculo;
CREATE TRIGGER trg_audit_vehiculo
    AFTER INSERT OR UPDATE OR DELETE ON vehiculo
    FOR EACH ROW
    EXECUTE FUNCTION fn_audit_generic();
