-- Garantia de NO-SUPERPOSICION temporal a nivel indice.
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
-- Nota academica (defensa): este archivo es la unica linea del schema que
-- contiene la palabra ALTER. El README dicta que las constraints
-- multi-columna se declaran en 02_constraints/, no inline en el CREATE
-- TABLE. NO es una migracion versionada: como toda la DB es efimera y se
-- reaplica desde cero, este ALTER se ejecuta sobre una tabla recien
-- creada en el mismo deploy.

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
