-- Grants explicitos para las functions del Sprint 2 (R7, R8).
--
-- Comentario sobre redundancia: el bloque DO al final de 04_rls_policies.sql
-- hace `GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO authenticated`,
-- de modo que estas functions ya quedarian ejecutables aun sin este
-- archivo. Aun asi, dejamos los grants explicitos para que la grilla de
-- permisos por function quede legible en `\dp` y revisable en code review
-- (PLAN_IMPLEMENTACION.md §2.4).
--
-- R11: convertidas de PROCEDURE a FUNCTION para exposicion via PostgREST RPC.
-- Idempotente: GRANT EXECUTE es seguro de reaplicar; no falla si ya esta
-- otorgado.

GRANT EXECUTE ON FUNCTION pa_registrar_reserva(
    BIGINT, BIGINT, BIGINT, TIMESTAMP, TIMESTAMP
) TO authenticated;

GRANT EXECUTE ON FUNCTION pa_cancelar_reserva(
    BIGINT, TEXT
) TO authenticated;

-- Tambien dejamos disponibles las funciones de validacion reusables a
-- authenticated por si en el futuro se invocan desde otros procedures que
-- usen SECURITY INVOKER. No hay riesgo: solo retornan VOID o lanzan
-- EXCEPTION, no leen datos sensibles.
-- Sprint 6 (B4.2): fn_validar_periodo ahora acepta tolerancia opcional para
-- el caso walk-in. El grant referencia la signature completa (incluyendo el
-- parametro con DEFAULT) porque Postgres identifica functions por su firma
-- exacta de tipos, no por el subconjunto sin defaults.
GRANT EXECUTE ON FUNCTION fn_validar_periodo(TIMESTAMP, TIMESTAMP, INTERVAL) TO authenticated;
GRANT EXECUTE ON FUNCTION fn_validar_cliente_activo(BIGINT)               TO authenticated;
GRANT EXECUTE ON FUNCTION fn_validar_vehiculo_operativo(BIGINT)           TO authenticated;
