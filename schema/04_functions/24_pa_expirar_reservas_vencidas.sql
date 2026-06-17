-- Procedure: pa_expirar_reservas_vencidas (R12 - procesamiento masivo)
-- Tarea programada de higiene de reservas: cancela en lote todas las
-- reservas 'pendiente' que el cliente nunca concreto y cuya ventana de
-- retiro ya vencio (no-show), liberando el cupo del vehiculo y desactivando
-- la garantia asociada.
--
-- Por que existe:
--   Una reserva 'pendiente' bloquea el vehiculo en su periodo via la
--   constraint EXCLUDE (excl_reserva_overlap). Si el cliente no se presenta
--   a retirar, esa reserva fantasma sigue impidiendo que otro cliente
--   reserve o que el personal alquile el vehiculo en esas fechas. Sin una
--   limpieza periodica, el inventario disponible se degrada con el tiempo.
--
-- Procesamiento MASIVO + VARIAS ACTIVIDADES (a diferencia de
-- pa_cancelar_reserva, que opera sobre UNA reserva por peticion HTTP):
--   1) Cancela en una sola sentencia TODAS las reservas vencidas (set-based,
--      no fila por fila): UPDATE reserva -> estado='cancelada' + motivo.
--   2) Desactiva en lote las garantias de esas reservas: UPDATE
--      garantia_reserva -> activa=FALSE (preserva el historial, no borra).
--   3) Dispara de forma transparente el trigger de auditoria trg_audit_reserva
--      por cada fila modificada -> audit_log queda poblado con la baja
--      automatica (tercera actividad, sin codigo explicito aca).
-- Las tres actividades ocurren dentro de la misma transaccion que pg_cron
-- abre al invocar el procedure: o se aplican todas o ninguna.
--
-- Criterio de seleccion (no-show con ventana de gracia):
--   * estado = 'pendiente'                         -> no concretada ni cancelada.
--   * fecha_inicio < NOW() - ventana_de_gracia     -> el retiro debio ocurrir
--                                                     hace mas de la gracia.
--   * NOT EXISTS alquiler con ese id_reserva        -> el cliente nunca retiro
--                                                     (defensa en profundidad,
--                                                     ademas del estado).
--   La ventana de gracia (24 h) evita cancelar a un cliente que llega con
--   unas horas de demora el mismo dia del retiro.
--
-- Idempotencia: una reserva ya 'cancelada' deja de cumplir el filtro de
-- estado, por lo que corridas sucesivas no la vuelven a tocar ni reescriben
-- su motivo_cancelacion.
--
-- Programada via pg_cron (ver schema/04_functions/21_schedule_jobs.sql) una
-- vez por dia. Al ser tarea automatica no hay peticion HTTP: no retorna
-- p_estado/p_mensaje. Los errores se capturan con EXCEPTION OTHERS +
-- RAISE NOTICE para que queden en el log del cron sin abortar la proxima
-- ejecucion.
--
-- SECURITY DEFINER + SET search_path = public: mismo criterio que
-- pa_detectar_devoluciones_vencidas -> corre como propietario (postgres)
-- cuando lo invoca pg_cron, con UPDATE sobre reserva y garantia_reserva
-- garantizado sin depender de RLS, y blindado contra suplantacion de
-- funciones por search_path.
CREATE OR REPLACE PROCEDURE pa_expirar_reservas_vencidas()
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    -- Margen tras fecha_inicio antes de considerar la reserva un no-show.
    v_gracia      CONSTANT INTERVAL := INTERVAL '24 hours';
    v_reservas    INTEGER := 0;
    v_garantias   INTEGER := 0;
    v_motivo      TEXT;
BEGIN
    v_motivo := format(
        '[%s | sistema:cron] Expiracion automatica: reserva pendiente no '
        'concretada; ventana de retiro vencida hace mas de %s.',
        to_char(NOW(), 'YYYY-MM-DD"T"HH24:MI:SSOF'),
        v_gracia::TEXT
    );

    -- Una sola sentencia con dos CTE modificadoras: la primera cancela las
    -- reservas y devuelve sus ids; la segunda desactiva las garantias de esos
    -- mismos ids. Ambas se ejecutan sobre el mismo snapshot -> consistente y
    -- atomico, sin loop de PL/pgSQL.
    WITH expiradas AS (
        UPDATE reserva r
           SET estado             = 'cancelada',
               motivo_cancelacion = v_motivo
         WHERE r.estado       = 'pendiente'
           AND r.fecha_inicio < (NOW() - v_gracia)
           AND NOT EXISTS (
               SELECT 1 FROM alquiler a WHERE a.id_reserva = r.id_reserva
           )
        RETURNING r.id_reserva
    ),
    garantias AS (
        UPDATE garantia_reserva g
           SET activa = FALSE
          FROM expiradas e
         WHERE g.id_reserva = e.id_reserva
           AND g.activa     = TRUE
        RETURNING g.id_garantia
    )
    SELECT
        (SELECT count(*) FROM expiradas),
        (SELECT count(*) FROM garantias)
      INTO v_reservas, v_garantias;

    RAISE NOTICE
        'pa_expirar_reservas_vencidas: % reservas expiradas, % garantias desactivadas.',
        v_reservas, v_garantias;

EXCEPTION WHEN OTHERS THEN
    -- Nunca dejamos que un error de la tarea interrumpa el cron. La siguiente
    -- ejecucion lo reintentara automaticamente.
    RAISE NOTICE
        'pa_expirar_reservas_vencidas fallo: % (SQLSTATE: %).',
        SQLERRM, SQLSTATE;
END;
$$;
