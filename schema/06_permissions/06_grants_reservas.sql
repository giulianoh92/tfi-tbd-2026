-- Permisos de ejecucion para las operaciones de reserva (R7, R8) y sus
-- validaciones reutilizables.
--
-- Redundancia explicita: el bloque DO al final de 04_rls_policies.sql hace
-- `GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO authenticated`, asi
-- que estas funciones ya quedarian ejecutables sin este archivo. Se dejan
-- los permisos explicitos para que la tabla de permisos por funcion quede
-- legible en `\dp` y revisable en revision de codigo.
--
-- Las funciones estan declaradas como FUNCTION (no PROCEDURE) para que
-- PostgREST las exponga via /rest/v1/rpc.

-- pa_registrar_reserva: 5 parametros IN obligatorios + 4 IN opcionales para
-- garantia (tipo, titular, numero_tarjeta en texto plano, vencimiento). El
-- permiso referencia la firma completa porque Postgres identifica funciones
-- por su lista de tipos de parametros, no por el subconjunto sin defaults.
GRANT EXECUTE ON FUNCTION pa_registrar_reserva(
    BIGINT, BIGINT, BIGINT, TIMESTAMP, TIMESTAMP,
    VARCHAR, VARCHAR, TEXT, DATE
) TO authenticated;

GRANT EXECUTE ON FUNCTION pa_cancelar_reserva(
    BIGINT, TEXT
) TO authenticated;

-- pa_actualizar_cliente: el cliente edita sus propios datos personales.
-- La fila objetivo se resuelve desde el JWT dentro del procedimiento, asi
-- que no hay riesgo de acceso entre inquilinos aunque el permiso sea
-- generico.
GRANT EXECUTE ON FUNCTION pa_actualizar_cliente(
    VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR
) TO authenticated;

-- Tambien se otorga acceso a las funciones de validacion reutilizables a
-- authenticated por si en el futuro se invocan desde otros procedures que
-- usen SECURITY INVOKER. No hay riesgo: solo retornan VOID o lanzan
-- EXCEPTION, no leen datos sensibles.
--
-- fn_validar_periodo acepta una tolerancia opcional (INTERVAL) para
-- diferenciar reservas (granularidad dia) de atenciones presenciales (marca
-- de tiempo con holgura). El permiso referencia la firma completa incluyendo
-- el parametro con DEFAULT porque Postgres identifica funciones por su lista
-- exacta de tipos.
GRANT EXECUTE ON FUNCTION fn_validar_periodo(TIMESTAMP, TIMESTAMP, INTERVAL) TO authenticated;
GRANT EXECUTE ON FUNCTION fn_validar_cliente_activo(BIGINT)               TO authenticated;
GRANT EXECUTE ON FUNCTION fn_validar_vehiculo_operativo(BIGINT)           TO authenticated;
