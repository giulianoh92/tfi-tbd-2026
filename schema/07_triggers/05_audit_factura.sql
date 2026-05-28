-- Disparador de auditoria para `factura` (R1).
-- La factura es un documento contable: cada emision (R10) debe quedar
-- registrada con usuario, fecha/hora y valores para garantizar trazabilidad.
-- Se activa AFTER INSERT/UPDATE/DELETE y delega el registro a fn_audit_generic.
DROP TRIGGER IF EXISTS trg_audit_factura ON factura;
CREATE TRIGGER trg_audit_factura
    AFTER INSERT OR UPDATE OR DELETE ON factura
    FOR EACH ROW
    EXECUTE FUNCTION fn_audit_generic();
