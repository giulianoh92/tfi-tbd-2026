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
--   3) p_inicio >= NOW() - p_tolerancia_pasado. Reserva clasica usa el
--      default INTERVAL '0' -> inicio estrictamente futuro. Walk-in usa
--      INTERVAL '5 minutes' para tolerar la latencia HTTP entre el momento
--      en que el frontend captura NOW() y el momento en que la fila se
--      inserta en DB.
--
-- Retorna VOID y usa RAISE EXCEPTION cuando una regla falla. El caller
-- captura la excepcion en su bloque EXCEPTION WHEN OTHERS y mapea a
-- p_estado = 'ERROR_VALIDACION'.
--
-- Sprint 6 (B4.2): se anade el parametro p_tolerancia_pasado con default 0
-- (INTERVAL). Asi mantenemos una sola function reusable para los dos casos
-- (R7: modularizacion). Antes, el comentario decia "el frontend debe poner
-- NOW()+1min" para walk-in, lo que delegaba a la UI una regla de negocio
-- que pertenece a la DB. Mas info en JUSTIFICACION.md §R7.

CREATE OR REPLACE FUNCTION fn_validar_periodo(
    p_inicio              TIMESTAMP,
    p_fin                 TIMESTAMP,
    p_tolerancia_pasado   INTERVAL DEFAULT INTERVAL '0'
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

    -- Comparacion contra NOW() con tolerancia. Default 0 -> mismo
    -- comportamiento que antes para los callers existentes (reservas).
    IF p_inicio < NOW() - p_tolerancia_pasado THEN
        RAISE EXCEPTION 'REGLA DE NEGOCIO: la fecha de inicio (%) debe ser actual o futura (tolerancia: %).',
            p_inicio, p_tolerancia_pasado
            USING ERRCODE = 'check_violation';
    END IF;
END;
$$;
