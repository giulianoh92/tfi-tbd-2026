-- Grants para las operaciones de alquiler (R3, R6), el CRUD sobre la
-- entidad vehiculo y el alta presencial de cliente (walk-in).
--
-- Mismo razonamiento que 06_grants_reservas.sql: hay un blanket
-- GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO authenticated en
-- 04_rls_policies.sql, pero se dejan los grants explicitos para que la
-- grilla de permisos por function quede legible en `\dp` y revisable en
-- code review.
--
-- Las functions estan declaradas como FUNCTION (no PROCEDURE) para que
-- PostgREST las exponga via /rest/v1/rpc. Las firmas no incluyen la
-- palabra IN (implicito en FUNCTION) pero si OUT/INOUT.
--
-- No hay rol PostgreSQL `staff` separado: los staff se identifican por el
-- claim app_metadata.role = 'staff' del JWT. El gating se hace dentro de
-- cada function via fn_es_staff(). Por eso las functions de CRUD vehiculo
-- y de alta walk-in tambien se otorgan a `authenticated` y la verificacion
-- runtime queda en el body (defensa en profundidad sobre RLS).

-- Registro de alquiler (presencial o concrecion de una reserva).
GRANT EXECUTE ON FUNCTION pa_registrar_alquiler(
    BIGINT, BIGINT, BIGINT, BIGINT, TIMESTAMP, TIMESTAMP, INTEGER
) TO authenticated;

-- CRUD vehiculo. fn_es_staff() bloquea no-staff dentro del body.
GRANT EXECUTE ON FUNCTION pa_crear_vehiculo(
    BIGINT, BIGINT, VARCHAR, VARCHAR, INTEGER, VARCHAR, INTEGER, TEXT
) TO authenticated;

GRANT EXECUTE ON FUNCTION pa_actualizar_vehiculo(
    BIGINT, VARCHAR, VARCHAR, INTEGER, TEXT
) TO authenticated;

GRANT EXECUTE ON FUNCTION pa_baja_vehiculo(
    BIGINT, TEXT
) TO authenticated;

-- Alta de cliente presencial (walk-in) sin cuenta online previa.
-- fn_es_staff() dentro del body bloquea no-staff (defensa en profundidad).
GRANT EXECUTE ON FUNCTION pa_registrar_cliente_walkin(
    VARCHAR, VARCHAR, VARCHAR, VARCHAR, TEXT
) TO authenticated;
