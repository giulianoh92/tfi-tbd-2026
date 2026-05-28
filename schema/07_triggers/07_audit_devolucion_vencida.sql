-- Disparador de auditoria para `devolucion_vencida` (R9 + R1).
--
-- Cada deteccion de devolucion vencida y cada actualizacion (notificado,
-- actualizacion de horas) queda registrada en audit_log con usuario_app NULL
-- cuando el INSERT/UPDATE lo realiza la tarea programada (sin JWT) o con el
-- uuid del personal que marca "notificado" desde la interfaz.
DROP TRIGGER IF EXISTS trg_audit_devolucion_vencida ON devolucion_vencida;
CREATE TRIGGER trg_audit_devolucion_vencida
    AFTER INSERT OR UPDATE OR DELETE ON devolucion_vencida
    FOR EACH ROW
    EXECUTE FUNCTION fn_audit_generic();
