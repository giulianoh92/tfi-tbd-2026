-- EXCLUDE constraints excl_alquiler_overlap y excl_reserva_overlap (R7).
--
-- Garantia de NO-SUPERPOSICION temporal a nivel de indice para los periodos
-- de un mismo vehiculo. Refuerza la validacion de R7 directamente en la base
-- de datos, mas alla del procedure pa_registrar_reserva.
--
-- Problema que resuelve: el disparador fn_check_vehiculo_overlap es una
-- validacion preventiva (no concluyente bajo concurrencia). Dos transacciones
-- concurrentes pueden superponerse en la ventana entre el SELECT EXISTS (...)
-- y el INSERT, porque el disparador lee filas con su propia instantanea y
-- Postgres no toma candados predicados sobre el SELECT. Resultado: dos
-- alquileres del mismo vehiculo con periodos solapados podrian quedar
-- persistidos. EXCLUDE USING gist cierra esa ventana porque el indice
-- valida la condicion atomicamente al insertar.
--
-- Implementacion: las EXCLUDE constraints crean indices GiST que combinan
-- igualdad (id_vehiculo WITH =) con interseccion de rangos (tsrange WITH &&).
-- Requiere la extension btree_gist (declarada en 00_extensions.sql) para
-- que un BIGINT pueda convivir con un tsrange en el mismo operador GiST.
--
-- Limites del tsrange:
--   '[)'  => semi-abierto: el limite inferior se incluye, el superior se excluye.
--   Esto permite que la fecha_fin_prevista de un alquiler coincida exacto
--   con la fecha_inicio del siguiente sin considerarse solapados
--   (devolucion 10:00, nuevo alquiler 10:00 es un encadenamiento valido).
--
-- Clausulas WHERE:
--   * alquiler.estado = 'activo'                   -> los registros 'cerrado'
--                                                     no bloquean el periodo.
--   * reserva.estado IN ('pendiente','concretada') -> las reservas canceladas
--                                                     liberan el periodo.
--
-- Nota academica (defensa): este archivo concentra restricciones
-- multi-columna que dependen de tipos de rango y de la extension
-- btree_gist; por su complejidad se mantienen separadas del CREATE TABLE.
-- No es una migracion versionada: como toda la base de datos se reaplica
-- desde cero en cada despliegue, el ALTER se ejecuta sobre una tabla
-- recien creada en el mismo proceso.

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
