-- Funcion: fn_validar_periodo (R7)
-- Valida la consistencia temporal de un periodo de reserva o alquiler. Se
-- invoca desde pa_registrar_reserva y pa_registrar_alquiler.
--
-- Reglas validadas:
--   1) p_inicio y p_fin deben estar definidos.
--   2) p_fin estricto > p_inicio. La tabla reserva ya tiene chk_reserva_fechas
--      pero al validar aca cortamos antes (mensaje claro) y no llegamos al
--      INSERT cuando ya sabemos que va a fallar.
--   3) p_inicio >= NOW() - p_tolerancia_pasado. La reserva estandar usa el
--      valor por defecto INTERVAL '0' -> inicio estrictamente futuro. El
--      flujo presencial usa INTERVAL '5 minutes' para tolerar la latencia
--      entre el momento en que la aplicacion cliente captura NOW() y el
--      momento en que la fila se inserta en la base.
--
-- Retorna VOID y usa RAISE EXCEPTION cuando una regla falla. El caller
-- captura la excepcion en su bloque EXCEPTION WHEN OTHERS y mapea a
-- p_estado = 'ERROR_VALIDACION'.
--
-- p_tolerancia_pasado tiene por defecto 0 (INTERVAL) para mantener una sola
-- funcion reutilizable entre ambos flujos (R7: modularizacion).
--
-- Modos de comparacion contra el presente:
--   * p_tolerancia_pasado = INTERVAL '0' (por defecto): marca de tiempo
--     estricta, p_inicio >= NOW(). Util si el invocador envia una hora
--     concreta y quiere impedir incluso unos segundos en el pasado.
--   * p_tolerancia_pasado = INTERVAL 'X': marca de tiempo con holgura. El
--     flujo presencial usa '5 minutes' para tolerar la latencia entre que
--     la interfaz captura NOW() y el INSERT llega a la base.
--   * p_tolerancia_pasado = NULL: modo "granularidad dia". Compara solo
--     la parte de fecha de p_inicio contra CURRENT_DATE. Pensado para flujos
--     donde la interfaz muestra un selector de fecha (sin hora) y envia el
--     timestamp con hora 00:00:00. Sin este modo la reserva del MISMO dia
--     fallaria, porque 2026-05-25 00:00:00 < NOW() cuando ya pasaron unos
--     minutos del comienzo del dia.

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

    -- Modo "granularidad dia": compara solo la parte de fecha, ignora la hora.
    -- Permite reservar para el dia actual aunque ya hayan pasado horas desde las 00:00.
    IF p_tolerancia_pasado IS NULL THEN
        IF p_inicio::date < CURRENT_DATE THEN
            RAISE EXCEPTION 'REGLA DE NEGOCIO: la fecha de inicio (%) debe ser hoy o un dia futuro.',
                p_inicio::date
                USING ERRCODE = 'check_violation';
        END IF;
        RETURN;
    END IF;

    -- Modo marca de tiempo con tolerancia (por defecto 0 o intervalo positivo).
    IF p_inicio < NOW() - p_tolerancia_pasado THEN
        RAISE EXCEPTION 'REGLA DE NEGOCIO: la fecha de inicio (%) debe ser actual o futura (tolerancia: %).',
            p_inicio, p_tolerancia_pasado
            USING ERRCODE = 'check_violation';
    END IF;
END;
$$;
