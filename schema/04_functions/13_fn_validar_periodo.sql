-- Funcion: fn_validar_periodo
-- Sprint 2 (R7). Valida la consistencia temporal de un periodo de reserva o
-- alquiler. Se invoca desde los procedures pa_registrar_reserva y, mas
-- adelante en Sprint 3, desde pa_registrar_alquiler.
--
-- Reglas validadas:
--   1) p_inicio y p_fin deben estar definidos.
--   2) p_fin estricto > p_inicio. La tabla reserva ya tiene chk_reserva_fechas
--      pero al validar aca cortamos antes (mensaje claro) y no llegamos al
--      INSERT cuando ya sabemos que va a fallar.
--   3) p_inicio > NOW(). No tiene sentido permitir reservar para el pasado;
--      las reservas son por definicion adelantadas. Walk-in (sin reserva) se
--      maneja con pa_registrar_alquiler en Sprint 3, donde esta regla se
--      relaja.
--
-- Retorna VOID y usa RAISE EXCEPTION cuando una regla falla. El caller
-- captura la excepcion en su bloque EXCEPTION WHEN OTHERS y mapea a
-- p_estado = 'ERROR_VALIDACION'.

CREATE OR REPLACE FUNCTION fn_validar_periodo(
    p_inicio TIMESTAMP,
    p_fin    TIMESTAMP
)
RETURNS VOID
LANGUAGE plpgsql
STABLE
AS $$
BEGIN
    IF p_inicio IS NULL OR p_fin IS NULL THEN
        RAISE EXCEPTION 'REGLA DE NEGOCIO: las fechas de inicio y fin son obligatorias.'
            USING ERRCODE = 'check_violation';
    END IF;

    IF p_fin <= p_inicio THEN
        RAISE EXCEPTION 'REGLA DE NEGOCIO: la fecha de fin (%) debe ser posterior a la fecha de inicio (%).',
            p_fin, p_inicio
            USING ERRCODE = 'check_violation';
    END IF;

    IF p_inicio <= NOW() THEN
        RAISE EXCEPTION 'REGLA DE NEGOCIO: la fecha de inicio (%) debe ser futura.',
            p_inicio
            USING ERRCODE = 'check_violation';
    END IF;
END;
$$;
