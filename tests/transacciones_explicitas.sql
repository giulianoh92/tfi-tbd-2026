-- ============================================================================
-- tests/transacciones_explicitas.sql — Demostracion literal de COMMIT/ROLLBACK
-- ============================================================================
--
-- Sprint 5 (R2). Este script demuestra que el alumno conoce y puede usar la
-- sintaxis Oracle/PL-SQL clasica de control transaccional explicito (COMMIT;
-- ROLLBACK;) dentro de un procedure PL/pgSQL.
--
-- COMO EJECUTARLO
-- ---------------
--   psql "$DATABASE_URL" -f tests/transacciones_explicitas.sql
--
-- o, via wrapper:
--
--   scripts/demo-transaccional.sh
--
-- POR QUE NO ES INVOCABLE VIA SUPABASE RPC (PostgREST)
-- ----------------------------------------------------
-- En PostgreSQL, los COMMIT / ROLLBACK explicitos dentro de un PROCEDURE solo
-- funcionan cuando el procedure se llama desde una sesion SIN transaccion
-- abierta (p.ej. `psql` interactivo, o un script ejecutado con `psql -f`).
--
-- Cuando el procedure se invoca a traves de Supabase / PostgREST, el adaptador
-- HTTP abre una transaccion automaticamente antes del `CALL`. Un `COMMIT;`
-- explicito dentro del procedure dispara el error:
--
--     ERROR 2D000: invalid_transaction_termination
--     DETAIL: cannot commit while a subtransaction is active
--
-- Por ese motivo en los procedures de produccion (pa_registrar_reserva,
-- pa_finalizar_alquiler, etc.) usamos el mecanismo idiomatico de Postgres:
-- bloques `BEGIN ... EXCEPTION WHEN ... END`. Cada `BEGIN` asocia un
-- savepoint implicito: si una excepcion se captura, Postgres hace rollback al
-- savepoint (= ROLLBACK parcial); si el bloque termina sin excepcion, la
-- transaccion del caller se compromete normalmente (= COMMIT implicito).
--
-- Referencia completa: docs/requisitos/JUSTIFICACION.md §R2.
--
-- ESTE SCRIPT DEMUESTRA
-- ---------------------
--   1) Crea una tabla TEMP demo_tx (visible solo durante la sesion psql).
--   2) Crea el procedure pa_demo_transaccional() con:
--        * INSERT (#1) seguido de COMMIT;   -> queda persistido.
--        * INSERT (#2) seguido de ROLLBACK; -> se descarta.
--      Esos COMMIT / ROLLBACK SON LITERALES, igual a Oracle.
--   3) Ejecuta CALL pa_demo_transaccional().
--   4) Hace SELECT count(*) sobre demo_tx -> debe imprimir 1 fila resultante.
-- ============================================================================

\set ON_ERROR_STOP on
\echo
\echo '== Demo transaccional literal (Sprint 5 - R2) =='
\echo

-- Tabla TEMP: vive solo en esta sesion psql, asi no contaminamos el schema
-- public ni interferimos con audit_log.
CREATE TEMP TABLE demo_tx (
    id    SERIAL PRIMARY KEY,
    nota  TEXT,
    creado_en TIMESTAMP DEFAULT NOW()
);

-- Procedure de demostracion. La firma deja constancia explicita de que el
-- alumno conoce la sintaxis del PDF (Oracle-style COMMIT/ROLLBACK).
CREATE OR REPLACE PROCEDURE pa_demo_transaccional()
LANGUAGE plpgsql AS $$
BEGIN
    RAISE NOTICE 'pa_demo_transaccional: inicio (demuestra COMMIT/ROLLBACK literales segun PDF §R2)';

    -- 1) Primer INSERT + COMMIT explicito => debe persistir.
    INSERT INTO demo_tx (nota) VALUES ('Fila #1 — confirmada con COMMIT literal');
    COMMIT;
    RAISE NOTICE '  -> Fila #1 insertada y COMMITeada.';

    -- 2) Segundo INSERT + ROLLBACK explicito => debe descartarse.
    INSERT INTO demo_tx (nota) VALUES ('Fila #2 — sera descartada con ROLLBACK literal');
    ROLLBACK;
    RAISE NOTICE '  -> Fila #2 insertada y luego ROLLBACKeada (no debe persistir).';

    -- Nota: COMMIT / ROLLBACK literales solo se permiten porque el procedure
    -- se invoca desde `psql -f` (sesion sin transaccion abierta del caller).
    -- Si esto se llamara via Supabase RPC, fallaria con
    -- ERRCODE = 2D000 invalid_transaction_termination.

    RAISE NOTICE 'pa_demo_transaccional: fin.';
END;
$$;

-- Ejecucion del procedure
CALL pa_demo_transaccional();

-- Verificacion del estado final: solo Fila #1 debe estar presente.
DO $$
DECLARE
    v_count INTEGER;
BEGIN
    SELECT count(*) INTO v_count FROM demo_tx;
    RAISE NOTICE '--';
    RAISE NOTICE 'Estado final demo_tx: % fila(s) (esperado: 1).', v_count;
    IF v_count = 1 THEN
        RAISE NOTICE 'OK: COMMIT/ROLLBACK literales funcionaron como en Oracle.';
    ELSE
        RAISE EXCEPTION 'FALLO: se esperaba 1 fila resultante, se obtuvieron %.', v_count;
    END IF;
END
$$;

\echo
\echo 'Listado de filas persistidas en demo_tx:'
SELECT id, nota, creado_en FROM demo_tx ORDER BY id;

-- Limpieza: la tabla TEMP se destruye sola al cerrar la sesion psql. El
-- procedure pa_demo_transaccional() queda definido en el schema y puede
-- inspeccionarse luego con `\df+ pa_demo_transaccional`.
