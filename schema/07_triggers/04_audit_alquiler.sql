-- Trigger de auditoria para `alquiler` (R1).
DROP TRIGGER IF EXISTS trg_audit_alquiler ON alquiler;
CREATE TRIGGER trg_audit_alquiler
    AFTER INSERT OR UPDATE OR DELETE ON alquiler
    FOR EACH ROW
    EXECUTE FUNCTION fn_audit_generic();
