-- Disparador de auditoria para `alquiler` (R1).
-- Se activa AFTER INSERT/UPDATE/DELETE y delega el registro a fn_audit_generic.
-- Cubre los hitos del ciclo de vida R10: apertura del contrato, modificaciones
-- intermedias y cierre con devolucion.
DROP TRIGGER IF EXISTS trg_audit_alquiler ON alquiler;
CREATE TRIGGER trg_audit_alquiler
    AFTER INSERT OR UPDATE OR DELETE ON alquiler
    FOR EACH ROW
    EXECUTE FUNCTION fn_audit_generic();
