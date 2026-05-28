-- Permisos de ejecucion para las operaciones de alquiler (R3, R6), el CRUD
-- sobre la entidad vehiculo y el alta presencial de cliente.
--
-- Mismo razonamiento que 06_grants_reservas.sql: hay un permiso general
-- GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO authenticated en
-- 04_rls_policies.sql, pero se dejan los permisos explicitos para que la
-- tabla de permisos por funcion quede legible en `\dp` y revisable en
-- revision de codigo.
--
-- Las funciones estan declaradas como FUNCTION (no PROCEDURE) para que
-- PostgREST las exponga via /rest/v1/rpc. Las firmas no incluyen la
-- palabra IN (implicito en FUNCTION) pero si OUT/INOUT.
--
-- No hay rol PostgreSQL `staff` separado: el personal se identifica por el
-- atributo app_metadata.role = 'staff' del JWT. La verificacion se hace
-- dentro de cada funcion via fn_es_staff(). Por eso las funciones de CRUD
-- vehiculo y de alta presencial tambien se otorgan a `authenticated` y la
-- verificacion en tiempo de ejecucion queda en el cuerpo (defensa adicional
-- por capas sobre RLS).

-- Registro de alquiler (presencial o concrecion de una reserva).
GRANT EXECUTE ON FUNCTION pa_registrar_alquiler(
    BIGINT, BIGINT, BIGINT, BIGINT, TIMESTAMP, TIMESTAMP, INTEGER
) TO authenticated;

-- CRUD vehiculo. fn_es_staff() bloquea usuarios sin rol de personal dentro del cuerpo.
GRANT EXECUTE ON FUNCTION pa_crear_vehiculo(
    BIGINT, BIGINT, VARCHAR, VARCHAR, INTEGER, VARCHAR, INTEGER, TEXT
) TO authenticated;

GRANT EXECUTE ON FUNCTION pa_actualizar_vehiculo(
    BIGINT, VARCHAR, VARCHAR, INTEGER, TEXT
) TO authenticated;

GRANT EXECUTE ON FUNCTION pa_baja_vehiculo(
    BIGINT, TEXT
) TO authenticated;

-- Alta de cliente presencial sin cuenta en linea previa.
-- fn_es_staff() dentro del cuerpo bloquea usuarios sin rol de personal
-- (defensa adicional por capas).
GRANT EXECUTE ON FUNCTION pa_registrar_cliente_walkin(
    VARCHAR, VARCHAR, VARCHAR, VARCHAR, TEXT
) TO authenticated;
