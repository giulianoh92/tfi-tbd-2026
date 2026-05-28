-- Disparador de auditoria para `mantenimiento` (R1).
-- Se activa AFTER INSERT/UPDATE/DELETE y delega el registro a fn_audit_generic.
-- Cubre el envio del vehiculo a taller y la devolucion del servicio, ambos
-- relevantes para reconstruir los periodos de no disponibilidad de un vehiculo.
DROP TRIGGER IF EXISTS trg_audit_mantenimiento ON mantenimiento;
CREATE TRIGGER trg_audit_mantenimiento
    AFTER INSERT OR UPDATE OR DELETE ON mantenimiento
    FOR EACH ROW
    EXECUTE FUNCTION fn_audit_generic();
