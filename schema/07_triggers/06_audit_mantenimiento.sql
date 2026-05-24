-- Trigger de auditoria para `mantenimiento` (R1).
DROP TRIGGER IF EXISTS trg_audit_mantenimiento ON mantenimiento;
CREATE TRIGGER trg_audit_mantenimiento
    AFTER INSERT OR UPDATE OR DELETE ON mantenimiento
    FOR EACH ROW
    EXECUTE FUNCTION fn_audit_generic();
