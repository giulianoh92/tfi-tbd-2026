-- Disparador de auditoria para `cliente` (R1).
-- Se activa AFTER INSERT/UPDATE/DELETE y delega el registro a fn_audit_generic.
DROP TRIGGER IF EXISTS trg_audit_cliente ON cliente;
CREATE TRIGGER trg_audit_cliente
    AFTER INSERT OR UPDATE OR DELETE ON cliente
    FOR EACH ROW
    EXECUTE FUNCTION fn_audit_generic();
