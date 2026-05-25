-- Grants para las operaciones de reserva (R7, R8) y sus validaciones
-- reutilizables.
--
-- Redundancia explicita: el bloque DO al final de 04_rls_policies.sql hace
-- `GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO authenticated`, asi
-- que estas functions ya quedarian ejecutables sin este archivo. Se dejan
-- los grants explicitos para que la grilla de permisos por function quede
-- legible en `\dp` y revisable en code review.
--
-- Las functions estan declaradas como FUNCTION (no PROCEDURE) para que
-- PostgREST las exponga via /rest/v1/rpc.

-- pa_registrar_reserva: 5 IN obligatorios + 4 IN opcionales para garantia
-- (tipo, titular, numero_tarjeta en texto plano, vencimiento). El grant
-- referencia la firma completa porque Postgres identifica functions por su
-- tipo de parametros, no por el subconjunto sin defaults.
GRANT EXECUTE ON FUNCTION pa_registrar_reserva(
    BIGINT, BIGINT, BIGINT, TIMESTAMP, TIMESTAMP,
    VARCHAR, VARCHAR, TEXT, DATE
) TO authenticated;

GRANT EXECUTE ON FUNCTION pa_cancelar_reserva(
    BIGINT, TEXT
) TO authenticated;

-- Tambien dejamos disponibles las funciones de validacion reusables a
-- authenticated por si en el futuro se invocan desde otros procedures que
-- usen SECURITY INVOKER. No hay riesgo: solo retornan VOID o lanzan
-- EXCEPTION, no leen datos sensibles.
--
-- fn_validar_periodo acepta una tolerancia opcional (INTERVAL) para
-- diferenciar reservas (granularidad dia) de walk-in (timestamp con
-- holgura). El grant referencia la signature completa incluyendo el
-- parametro con DEFAULT porque Postgres identifica functions por su
-- firma exacta de tipos.
GRANT EXECUTE ON FUNCTION fn_validar_periodo(TIMESTAMP, TIMESTAMP, INTERVAL) TO authenticated;
GRANT EXECUTE ON FUNCTION fn_validar_cliente_activo(BIGINT)               TO authenticated;
GRANT EXECUTE ON FUNCTION fn_validar_vehiculo_operativo(BIGINT)           TO authenticated;
