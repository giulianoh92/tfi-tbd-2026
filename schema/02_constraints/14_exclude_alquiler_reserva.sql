-- EXCLUDE constraints excl_alquiler_overlap y excl_reserva_overlap (R7).
--
-- Garantia de NO-SUPERPOSICION temporal a nivel indice para los periodos
-- de un mismo vehiculo. Sostiene la validacion de R7 desde la BD, mas
-- alla del procedure pa_registrar_reserva.
--
-- Problema que resuelve: el trigger fn_check_vehiculo_overlap es best-effort.
-- Dos transacciones concurrentes pueden colarse en la ventana entre el
-- SELECT EXISTS (...) y el INSERT, porque el trigger lee filas con su propio
-- snapshot y Postgres no toma locks predicados sobre el SELECT. Resultado:
-- dos alquileres del mismo vehiculo con periodos solapados terminan
-- persistidos. EXCLUDE USING gist cierra esa ventana porque el indice
-- valida la condicion atomicamente al insertar.
--
-- Implementacion: las EXCLUDE constraints crean indices GiST que combinan
-- igualdad (id_vehiculo WITH =) con interseccion de rangos (tsrange WITH &&).
-- Requiere la extension btree_gist (declarada en 00_extensions.sql) para
-- que un BIGINT pueda convivir con un tsrange en el mismo operador.
--
-- Limites del tsrange:
--   '[)'  => half-open: el limite inferior incluye, el superior excluye.
--   Esto permite que la fecha_fin_prevista de un alquiler coincida exacto
--   con la fecha_inicio del siguiente sin ser considerada solapada
--   (devolucion 10:00, alquiler nuevo 10:00 es un encadenamiento valido).
--
-- WHERE clauses:
--   * alquiler.estado = 'activo'           -> los 'cerrado' no bloquean al
--                                             siguiente.
--   * reserva.estado IN ('pendiente','concretada') -> reservas canceladas
--                                             dejan libre el slot.
--
-- Nota academica (defensa): este archivo concentra constraints
-- multi-columna que dependen de tipos de rango y de la extension
-- btree_gist; por su complejidad se mantienen separadas del CREATE TABLE.
-- NO es una migracion versionada: como toda la DB se reaplica desde cero
-- en cada deploy, el ALTER se ejecuta sobre una tabla recien creada en el
-- mismo despliegue.

ALTER TABLE alquiler
    ADD CONSTRAINT excl_alquiler_overlap
    EXCLUDE USING gist (
        id_vehiculo WITH =,
        tsrange(fecha_inicio, fecha_fin_prevista, '[)') WITH &&
    )
    WHERE (estado = 'activo');

ALTER TABLE reserva
    ADD CONSTRAINT excl_reserva_overlap
    EXCLUDE USING gist (
        id_vehiculo WITH =,
        tsrange(fecha_inicio, fecha_fin_prevista, '[)') WITH &&
    )
    WHERE (estado IN ('pendiente', 'concretada'));
