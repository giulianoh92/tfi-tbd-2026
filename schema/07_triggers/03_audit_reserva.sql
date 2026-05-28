-- Disparador de auditoria para `reserva` (R1).
-- Se activa AFTER INSERT/UPDATE/DELETE y delega el registro a fn_audit_generic.
-- Cubre los hitos del flujo R7/R8: alta de reserva, cambio de estado a
-- 'concretada' (activado por fn_alquiler_start) y cancelacion (R8).
DROP TRIGGER IF EXISTS trg_audit_reserva ON reserva;
CREATE TRIGGER trg_audit_reserva
    AFTER INSERT OR UPDATE OR DELETE ON reserva
    FOR EACH ROW
    EXECUTE FUNCTION fn_audit_generic();
