-- Funcion: fn_validar_cliente_activo (R7)
-- Valida que un cliente exista y este habilitado para operar.
--
-- Estado actual del esquema: la tabla `cliente` no tiene aun un indicador de
-- actividad (`activo BOOLEAN`) ni una nocion de "deuda pendiente" persistida.
-- Por lo tanto, esta version se limita a validar EXISTENCIA. La firma queda
-- preparada para que cuando se introduzcan esos campos la regla se extienda
-- aca sin tocar a los callers.
--
-- Extensiones futuras esperadas:
--   * Chequear cliente.activo = TRUE.
--   * Chequear que no haya facturas impagas o alquileres con devolucion
--     vencida sin resolver (tabla devolucion_vencida).
--
-- La funcion lanza RAISE EXCEPTION para que el invocador la capture en su
-- bloque EXCEPTION WHEN OTHERS y lo mapee a p_estado = 'ERROR_VALIDACION' /
-- 'ERROR_REFERENCIAL' segun corresponda.

CREATE OR REPLACE FUNCTION fn_validar_cliente_activo(
    p_id_cliente BIGINT
)
RETURNS VOID
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
    v_existe BOOLEAN;
BEGIN
    IF p_id_cliente IS NULL THEN
        RAISE EXCEPTION 'REGLA DE NEGOCIO: el id_cliente es obligatorio.'
            USING ERRCODE = 'check_violation';
    END IF;

    SELECT EXISTS (
        SELECT 1 FROM cliente WHERE id_cliente = p_id_cliente
    ) INTO v_existe;

    IF NOT v_existe THEN
        RAISE EXCEPTION 'CONTROL DE INTEGRIDAD: el cliente % no existe.', p_id_cliente
            USING ERRCODE = 'foreign_key_violation';
    END IF;

    -- Extension futura: cuando se introduzca cliente.activo o una nocion
    -- de deuda persistida, agregar aqui las verificaciones correspondientes y
    -- mapearlas a ERRCODE = 'check_violation' para que el invocador las
    -- categorice como ERROR_VALIDACION. La firma de esta funcion ya esta
    -- preparada (acepta p_id_cliente) para que los invocadores no cambien.
END;
$$;
