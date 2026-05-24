-- Trigger de auditoria para `factura` (R1).
DROP TRIGGER IF EXISTS trg_audit_factura ON factura;
CREATE TRIGGER trg_audit_factura
    AFTER INSERT OR UPDATE OR DELETE ON factura
    FOR EACH ROW
    EXECUTE FUNCTION fn_audit_generic();
