-- Funcion: fn_validar_vehiculo_operativo (R7)
-- Valida que un vehiculo exista y este en estado "disponible".
--
-- Reglas:
--   1) p_id_vehiculo no nulo.
--   2) vehiculo existe.
--   3) vehiculo.id_estado apunta a estado_vehiculo.nombre = 'disponible'
--      (comparacion case-insensitive sobre el catalogo).
--
-- La validacion de superposicion de fechas NO se hace aca. Esa regla la
-- aplica el trigger BEFORE INSERT/UPDATE fn_check_vehiculo_overlap
-- (schema/04_functions/02_*.sql), que ya esta vivo sobre reserva y
-- alquiler. Mantener separacion de responsabilidades segun R7.
--
-- Callers: pa_registrar_reserva y pa_registrar_alquiler (rama "sin reserva
-- previa").

CREATE OR REPLACE FUNCTION fn_validar_vehiculo_operativo(
    p_id_vehiculo BIGINT
)
RETURNS VOID
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
    v_estado_nombre TEXT;
BEGIN
    IF p_id_vehiculo IS NULL THEN
        RAISE EXCEPTION 'REGLA DE NEGOCIO: el id_vehiculo es obligatorio.'
            USING ERRCODE = 'check_violation';
    END IF;

    SELECT lower(ev.nombre)
      INTO v_estado_nombre
      FROM vehiculo v
      JOIN estado_vehiculo ev ON ev.id_estado = v.id_estado
     WHERE v.id_vehiculo = p_id_vehiculo;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'CONTROL DE INTEGRIDAD: el vehiculo % no existe.', p_id_vehiculo
            USING ERRCODE = 'foreign_key_violation';
    END IF;

    IF v_estado_nombre IS DISTINCT FROM 'disponible' THEN
        RAISE EXCEPTION 'REGLA DE NEGOCIO: el vehiculo % no esta disponible (estado actual: %).',
            p_id_vehiculo, v_estado_nombre
            USING ERRCODE = 'check_violation';
    END IF;
END;
$$;
