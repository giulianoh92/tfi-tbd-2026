-- Trigger de auditoria para `reserva` (R1).
DROP TRIGGER IF EXISTS trg_audit_reserva ON reserva;
CREATE TRIGGER trg_audit_reserva
    AFTER INSERT OR UPDATE OR DELETE ON reserva
    FOR EACH ROW
    EXECUTE FUNCTION fn_audit_generic();
