-- Politicas de Row Level Security.
--
-- Modelo de acceso:
--   * anon          (sin JWT)              : lectura publica de catalogos + flota disponible.
--   * authenticated (JWT cliente)          : ve y opera sobre SU propio cliente,
--                                            reservas, alquileres y facturas.
--   * staff         (JWT con el atributo   : ve y opera sobre todo. Se identifica
--                    app_metadata.role       via fn_es_staff() leyendo el JWT.
--                    = 'staff')
--
-- DROP POLICY IF EXISTS antes de cada CREATE para idempotencia. La rutina
-- de despliegue ya hace DROP SCHEMA public CASCADE; estos drops son
-- defensa adicional por capas.
--
-- Patron de rendimiento para RLS recomendado por Supabase:
--   Las funciones auxiliares fn_auth_uid(), fn_es_staff(), fn_cliente_del_usuario()
--   se envuelven en (SELECT helper()) dentro de USING/WITH CHECK. El
--   planificador de Postgres reconoce el sub-select como InitPlan y lo evalua
--   UNA sola vez por consulta, en lugar de invocar la funcion por cada fila
--   escaneada. Sin esa envoltura, sobre una tabla de N filas, fn_*() se
--   llamaria N veces (Function Scan) -> O(n). Con la envoltura es O(1) en la
--   funcion + O(n) en la lectura de filas. Las tres auxiliares estan declaradas
--   STABLE (06_permissions/02_rls_helpers.sql), requisito para que el
--   planificador pueda reutilizar el resultado.
--   Ref: https://supabase.com/docs/guides/database/postgres/row-level-security#call-functions-with-select

-- ============================================================
-- CATALOGOS Y FLOTA: lectura publica, escritura solo staff
-- ============================================================

-- vehiculo
DROP POLICY IF EXISTS vehiculo_public_read     ON vehiculo;
DROP POLICY IF EXISTS vehiculo_staff_write     ON vehiculo;
CREATE POLICY vehiculo_public_read ON vehiculo
    FOR SELECT
    USING (TRUE);
CREATE POLICY vehiculo_staff_write ON vehiculo
    FOR ALL TO authenticated
    USING      ((SELECT fn_es_staff()))
    WITH CHECK ((SELECT fn_es_staff()));

-- imagen_vehiculo
DROP POLICY IF EXISTS imagen_public_read   ON imagen_vehiculo;
DROP POLICY IF EXISTS imagen_staff_write   ON imagen_vehiculo;
CREATE POLICY imagen_public_read ON imagen_vehiculo FOR SELECT USING (TRUE);
CREATE POLICY imagen_staff_write ON imagen_vehiculo FOR ALL TO authenticated
    USING ((SELECT fn_es_staff())) WITH CHECK ((SELECT fn_es_staff()));

-- tipo_vehiculo, estado_vehiculo, tipo_reserva, sucursal, taller, tarifa
DROP POLICY IF EXISTS tipo_vehiculo_read   ON tipo_vehiculo;
DROP POLICY IF EXISTS estado_vehiculo_read ON estado_vehiculo;
DROP POLICY IF EXISTS tipo_reserva_read    ON tipo_reserva;
DROP POLICY IF EXISTS sucursal_read        ON sucursal;
DROP POLICY IF EXISTS taller_read          ON taller;
DROP POLICY IF EXISTS tarifa_read          ON tarifa;
CREATE POLICY tipo_vehiculo_read   ON tipo_vehiculo   FOR SELECT USING (TRUE);
CREATE POLICY estado_vehiculo_read ON estado_vehiculo FOR SELECT USING (TRUE);
CREATE POLICY tipo_reserva_read    ON tipo_reserva    FOR SELECT USING (TRUE);
CREATE POLICY sucursal_read        ON sucursal        FOR SELECT USING (TRUE);
CREATE POLICY taller_read          ON taller          FOR SELECT USING (TRUE);
CREATE POLICY tarifa_read          ON tarifa          FOR SELECT USING (TRUE);

DROP POLICY IF EXISTS tipo_vehiculo_staff_write   ON tipo_vehiculo;
DROP POLICY IF EXISTS estado_vehiculo_staff_write ON estado_vehiculo;
DROP POLICY IF EXISTS tipo_reserva_staff_write    ON tipo_reserva;
DROP POLICY IF EXISTS sucursal_staff_write        ON sucursal;
DROP POLICY IF EXISTS taller_staff_write          ON taller;
DROP POLICY IF EXISTS tarifa_staff_write          ON tarifa;
CREATE POLICY tipo_vehiculo_staff_write   ON tipo_vehiculo   FOR ALL TO authenticated USING ((SELECT fn_es_staff())) WITH CHECK ((SELECT fn_es_staff()));
CREATE POLICY estado_vehiculo_staff_write ON estado_vehiculo FOR ALL TO authenticated USING ((SELECT fn_es_staff())) WITH CHECK ((SELECT fn_es_staff()));
CREATE POLICY tipo_reserva_staff_write    ON tipo_reserva    FOR ALL TO authenticated USING ((SELECT fn_es_staff())) WITH CHECK ((SELECT fn_es_staff()));
CREATE POLICY sucursal_staff_write        ON sucursal        FOR ALL TO authenticated USING ((SELECT fn_es_staff())) WITH CHECK ((SELECT fn_es_staff()));
CREATE POLICY taller_staff_write          ON taller          FOR ALL TO authenticated USING ((SELECT fn_es_staff())) WITH CHECK ((SELECT fn_es_staff()));
CREATE POLICY tarifa_staff_write          ON tarifa          FOR ALL TO authenticated USING ((SELECT fn_es_staff())) WITH CHECK ((SELECT fn_es_staff()));

-- ============================================================
-- CLIENTE: ve y edita SOLO su fila. Staff ve todo.
-- ============================================================

DROP POLICY IF EXISTS cliente_self_read   ON cliente;
DROP POLICY IF EXISTS cliente_self_update ON cliente;
DROP POLICY IF EXISTS cliente_staff_all   ON cliente;
CREATE POLICY cliente_self_read ON cliente
    FOR SELECT TO authenticated
    USING (auth_user_id = (SELECT fn_auth_uid()));
CREATE POLICY cliente_self_update ON cliente
    FOR UPDATE TO authenticated
    USING      (auth_user_id = (SELECT fn_auth_uid()))
    WITH CHECK (auth_user_id = (SELECT fn_auth_uid()));
CREATE POLICY cliente_staff_all ON cliente
    FOR ALL TO authenticated
    USING ((SELECT fn_es_staff())) WITH CHECK ((SELECT fn_es_staff()));

-- usuario (tabla de dominio propio, no auth.users): solo personal.
DROP POLICY IF EXISTS usuario_staff_all ON usuario;
CREATE POLICY usuario_staff_all ON usuario
    FOR ALL TO authenticated
    USING ((SELECT fn_es_staff())) WITH CHECK ((SELECT fn_es_staff()));

-- ============================================================
-- RESERVA: cliente CRUD sobre las suyas, staff todo.
-- ============================================================

DROP POLICY IF EXISTS reserva_owner_crud ON reserva;
DROP POLICY IF EXISTS reserva_staff_all  ON reserva;
CREATE POLICY reserva_owner_crud ON reserva
    FOR ALL TO authenticated
    USING      (id_cliente = (SELECT fn_cliente_del_usuario()))
    WITH CHECK (id_cliente = (SELECT fn_cliente_del_usuario()));
CREATE POLICY reserva_staff_all ON reserva
    FOR ALL TO authenticated
    USING ((SELECT fn_es_staff())) WITH CHECK ((SELECT fn_es_staff()));

-- garantia_reserva: cliente solo las propias (via FK reserva), staff todo.
DROP POLICY IF EXISTS garantia_owner_crud ON garantia_reserva;
DROP POLICY IF EXISTS garantia_staff_all  ON garantia_reserva;
CREATE POLICY garantia_owner_crud ON garantia_reserva
    FOR ALL TO authenticated
    USING      (id_reserva IN (SELECT id_reserva FROM reserva WHERE id_cliente = (SELECT fn_cliente_del_usuario())))
    WITH CHECK (id_reserva IN (SELECT id_reserva FROM reserva WHERE id_cliente = (SELECT fn_cliente_del_usuario())));
CREATE POLICY garantia_staff_all ON garantia_reserva
    FOR ALL TO authenticated
    USING ((SELECT fn_es_staff())) WITH CHECK ((SELECT fn_es_staff()));

-- ============================================================
-- ALQUILER: cliente solo lectura de los suyos. Crear/cerrar solo staff.
-- ============================================================

DROP POLICY IF EXISTS alquiler_owner_read ON alquiler;
DROP POLICY IF EXISTS alquiler_staff_all  ON alquiler;
CREATE POLICY alquiler_owner_read ON alquiler
    FOR SELECT TO authenticated
    USING (id_cliente = (SELECT fn_cliente_del_usuario()));
CREATE POLICY alquiler_staff_all ON alquiler
    FOR ALL TO authenticated
    USING ((SELECT fn_es_staff())) WITH CHECK ((SELECT fn_es_staff()));

-- ============================================================
-- FACTURA: cliente lectura de las suyas. Generadas por staff via RPC.
-- ============================================================

DROP POLICY IF EXISTS factura_owner_read ON factura;
DROP POLICY IF EXISTS factura_staff_all  ON factura;
CREATE POLICY factura_owner_read ON factura
    FOR SELECT TO authenticated
    USING (id_cliente = (SELECT fn_cliente_del_usuario()));
CREATE POLICY factura_staff_all ON factura
    FOR ALL TO authenticated
    USING ((SELECT fn_es_staff())) WITH CHECK ((SELECT fn_es_staff()));

-- ============================================================
-- HISTORIAL Y UBICACION: solo staff (operativo interno).
-- ============================================================

DROP POLICY IF EXISTS ubicacion_staff_all          ON ubicacion_vehiculo;
DROP POLICY IF EXISTS historial_estado_staff_all   ON historial_estado_vehiculo;
DROP POLICY IF EXISTS mantenimiento_staff_all      ON mantenimiento;
CREATE POLICY ubicacion_staff_all        ON ubicacion_vehiculo        FOR ALL TO authenticated USING ((SELECT fn_es_staff())) WITH CHECK ((SELECT fn_es_staff()));
CREATE POLICY historial_estado_staff_all ON historial_estado_vehiculo FOR ALL TO authenticated USING ((SELECT fn_es_staff())) WITH CHECK ((SELECT fn_es_staff()));
CREATE POLICY mantenimiento_staff_all    ON mantenimiento             FOR ALL TO authenticated USING ((SELECT fn_es_staff())) WITH CHECK ((SELECT fn_es_staff()));

-- ============================================================
-- AUDIT_LOG: solo el personal puede leer; nadie puede escribir manualmente.
-- ============================================================
-- La unica via de escritura es el disparador fn_audit_generic (declarado
-- SECURITY DEFINER -> corre como propietario postgres y omite RLS). Cualquier
-- INSERT/UPDATE/DELETE manual via PostgREST se rechaza porque no hay
-- politica que lo permita y RLS por defecto deniega.

DROP POLICY IF EXISTS audit_log_staff_read ON audit_log;
CREATE POLICY audit_log_staff_read ON audit_log
    FOR SELECT TO authenticated
    USING ((SELECT fn_es_staff()));

-- Bloqueo explicito de escritura manual: politicas FOR INSERT/UPDATE/DELETE
-- con USING/CHECK = FALSE. Defensa adicional por capas sobre la ausencia de
-- politica permisiva (que ya seria suficiente, pero conviene dejarlo
-- declarativo).
DROP POLICY IF EXISTS audit_log_no_insert ON audit_log;
DROP POLICY IF EXISTS audit_log_no_update ON audit_log;
DROP POLICY IF EXISTS audit_log_no_delete ON audit_log;
CREATE POLICY audit_log_no_insert ON audit_log
    FOR INSERT TO authenticated, anon
    WITH CHECK (FALSE);
CREATE POLICY audit_log_no_update ON audit_log
    FOR UPDATE TO authenticated, anon
    USING (FALSE) WITH CHECK (FALSE);
CREATE POLICY audit_log_no_delete ON audit_log
    FOR DELETE TO authenticated, anon
    USING (FALSE);

-- ============================================================
-- DEVOLUCION_VENCIDA: solo el personal puede leer y actualizar `notificado`.
-- ============================================================
-- Tabla poblada por pa_detectar_devoluciones_vencidas() (tarea pg_cron). El
-- procedure corre como rol postgres (propietario del esquema), que tiene
-- BYPASSRLS -> el INSERT/UPDATE de la tarea no necesita politica.
--
-- El personal la lee desde /admin/devoluciones-vencidas y puede marcar como
-- notificado=TRUE. NO se permite INSERT ni DELETE desde la interfaz (la fuente
-- de verdad es la tarea programada).

DROP POLICY IF EXISTS devolucion_vencida_staff_read   ON devolucion_vencida;
DROP POLICY IF EXISTS devolucion_vencida_staff_update ON devolucion_vencida;
CREATE POLICY devolucion_vencida_staff_read ON devolucion_vencida
    FOR SELECT TO authenticated
    USING ((SELECT fn_es_staff()));
CREATE POLICY devolucion_vencida_staff_update ON devolucion_vencida
    FOR UPDATE TO authenticated
    USING      ((SELECT fn_es_staff()))
    WITH CHECK ((SELECT fn_es_staff()));

-- ============================================================
-- GRANTS para roles de Supabase
-- ============================================================
-- Los roles anon y authenticated necesitan USAGE sobre el esquema y
-- SELECT/INSERT/UPDATE/DELETE sobre las tablas; RLS recorta el alcance fila
-- por fila. Sin GRANT no llegan ni a evaluar las politicas.

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'anon') THEN
        EXECUTE 'GRANT USAGE ON SCHEMA public TO anon, authenticated';
        EXECUTE 'GRANT SELECT ON ALL TABLES IN SCHEMA public TO anon';
        EXECUTE 'GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO authenticated';
        EXECUTE 'GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO authenticated';
        EXECUTE 'GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO authenticated';
        EXECUTE 'GRANT EXECUTE ON ALL PROCEDURES IN SCHEMA public TO authenticated';

        -- audit_log: se revoca la escritura para que ni siquiera llegue a
        -- evaluar la politica. La unica via de insercion es el disparador
        -- fn_audit_generic via SECURITY DEFINER. anon ni siquiera puede SELECT.
        EXECUTE 'REVOKE INSERT, UPDATE, DELETE ON audit_log FROM authenticated';
        EXECUTE 'REVOKE ALL ON audit_log FROM anon';

        -- devolucion_vencida: el personal solo lee y actualiza (marcar notificado).
        -- INSERT/DELETE quedan reservados a la tarea (corre como postgres). anon
        -- no la ve.
        EXECUTE 'REVOKE INSERT, DELETE ON devolucion_vencida FROM authenticated';
        EXECUTE 'REVOKE ALL ON devolucion_vencida FROM anon';
    END IF;
END
$$;
