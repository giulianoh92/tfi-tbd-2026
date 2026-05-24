-- Grants explicitos para las functions del Sprint 3 (R3, R6).
--
-- Mismo razonamiento que 06_grants_sprint_2.sql: hay un GRANT EXECUTE ON
-- ALL FUNCTIONS IN SCHEMA public TO authenticated en 04_rls_policies.sql,
-- pero dejamos grants explicitos para que la grilla de permisos por
-- function quede legible en `\dp` y revisable en code review
-- (PLAN_IMPLEMENTACION.md §3.3).
--
-- R11: convertidas de PROCEDURE a FUNCTION para exposicion via PostgREST RPC.
-- Las firmas no incluyen la palabra IN (implicito en FUNCTION) pero si OUT/INOUT.
--
-- No hay rol PostgreSQL `staff` separado: los staff se identifican por el
-- claim app_metadata.role = 'staff' del JWT. El gating se hace dentro de
-- cada function via fn_es_staff(). Por eso las functions de CRUD vehiculo
-- tambien se otorgan a `authenticated` y la verificacion runtime queda en
-- el body (defensa en profundidad sobre RLS).

-- Sprint 3.1 — alquiler.
GRANT EXECUTE ON FUNCTION pa_registrar_alquiler(
    BIGINT, BIGINT, BIGINT, BIGINT, TIMESTAMP, TIMESTAMP, INTEGER
) TO authenticated;

-- Sprint 3.2 — CRUD vehiculo. fn_es_staff() bloquea no-staff dentro del SP.
GRANT EXECUTE ON FUNCTION pa_crear_vehiculo(
    BIGINT, BIGINT, VARCHAR, VARCHAR, INTEGER, VARCHAR, INTEGER, TEXT
) TO authenticated;

GRANT EXECUTE ON FUNCTION pa_actualizar_vehiculo(
    BIGINT, VARCHAR, VARCHAR, INTEGER, TEXT
) TO authenticated;

GRANT EXECUTE ON FUNCTION pa_baja_vehiculo(
    BIGINT, TEXT
) TO authenticated;
