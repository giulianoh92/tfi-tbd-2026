-- Trigger de auditoria para `factura` (R1).
-- La factura es un documento contable: cada emision (R10) debe quedar
-- trazada con usuario, fecha/hora y valores. Se dispara AFTER
-- INSERT/UPDATE/DELETE y delega a fn_audit_generic.
DROP TRIGGER IF EXISTS trg_audit_factura ON factura;
CREATE TRIGGER trg_audit_factura
    AFTER INSERT OR UPDATE OR DELETE ON factura
    FOR EACH ROW
    EXECUTE FUNCTION fn_audit_generic();
