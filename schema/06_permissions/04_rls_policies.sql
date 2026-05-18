-- Row Level Security policies.
--
-- Modelo de acceso:
--   * anon          (sin JWT)         : lectura publica de catalogos + flota disponible.
--   * authenticated (JWT cliente)     : ve y opera sobre SU propio cliente,
--                                       reservas, alquileres y facturas.
--   * staff         (JWT con claim    : ve y opera sobre todo. Se identifica
--                    app_metadata.role  via fn_es_staff() leyendo el JWT.
--                    = 'staff')
--
-- DROP POLICY IF EXISTS antes de cada CREATE para idempotencia. apply.sh
-- ya hace DROP SCHEMA public CASCADE; estos drops son defensa en profundidad.

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
    USING      (fn_es_staff())
    WITH CHECK (fn_es_staff());

-- imagen_vehiculo
DROP POLICY IF EXISTS imagen_public_read   ON imagen_vehiculo;
DROP POLICY IF EXISTS imagen_staff_write   ON imagen_vehiculo;
CREATE POLICY imagen_public_read ON imagen_vehiculo FOR SELECT USING (TRUE);
CREATE POLICY imagen_staff_write ON imagen_vehiculo FOR ALL TO authenticated
    USING (fn_es_staff()) WITH CHECK (fn_es_staff());

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
CREATE POLICY tipo_vehiculo_staff_write   ON tipo_vehiculo   FOR ALL TO authenticated USING (fn_es_staff()) WITH CHECK (fn_es_staff());
CREATE POLICY estado_vehiculo_staff_write ON estado_vehiculo FOR ALL TO authenticated USING (fn_es_staff()) WITH CHECK (fn_es_staff());
CREATE POLICY tipo_reserva_staff_write    ON tipo_reserva    FOR ALL TO authenticated USING (fn_es_staff()) WITH CHECK (fn_es_staff());
CREATE POLICY sucursal_staff_write        ON sucursal        FOR ALL TO authenticated USING (fn_es_staff()) WITH CHECK (fn_es_staff());
CREATE POLICY taller_staff_write          ON taller          FOR ALL TO authenticated USING (fn_es_staff()) WITH CHECK (fn_es_staff());
CREATE POLICY tarifa_staff_write          ON tarifa          FOR ALL TO authenticated USING (fn_es_staff()) WITH CHECK (fn_es_staff());

-- ============================================================
-- CLIENTE: ve y edita SOLO su fila. Staff ve todo.
-- ============================================================

DROP POLICY IF EXISTS cliente_self_read   ON cliente;
DROP POLICY IF EXISTS cliente_self_update ON cliente;
DROP POLICY IF EXISTS cliente_staff_all   ON cliente;
CREATE POLICY cliente_self_read ON cliente
    FOR SELECT TO authenticated
    USING (auth_user_id = (SELECT auth.uid()));
CREATE POLICY cliente_self_update ON cliente
    FOR UPDATE TO authenticated
    USING      (auth_user_id = (SELECT auth.uid()))
    WITH CHECK (auth_user_id = (SELECT auth.uid()));
CREATE POLICY cliente_staff_all ON cliente
    FOR ALL TO authenticated
    USING (fn_es_staff()) WITH CHECK (fn_es_staff());

-- usuario (modelo de dominio propio, no auth.users): solo staff.
DROP POLICY IF EXISTS usuario_staff_all ON usuario;
CREATE POLICY usuario_staff_all ON usuario
    FOR ALL TO authenticated
    USING (fn_es_staff()) WITH CHECK (fn_es_staff());

-- ============================================================
-- RESERVA: cliente CRUD sobre las suyas, staff todo.
-- ============================================================

DROP POLICY IF EXISTS reserva_owner_crud ON reserva;
DROP POLICY IF EXISTS reserva_staff_all  ON reserva;
CREATE POLICY reserva_owner_crud ON reserva
    FOR ALL TO authenticated
    USING      (id_cliente = fn_cliente_del_usuario())
    WITH CHECK (id_cliente = fn_cliente_del_usuario());
CREATE POLICY reserva_staff_all ON reserva
    FOR ALL TO authenticated
    USING (fn_es_staff()) WITH CHECK (fn_es_staff());

-- garantia_reserva: cliente solo las propias (via FK reserva), staff todo.
DROP POLICY IF EXISTS garantia_owner_crud ON garantia_reserva;
DROP POLICY IF EXISTS garantia_staff_all  ON garantia_reserva;
CREATE POLICY garantia_owner_crud ON garantia_reserva
    FOR ALL TO authenticated
    USING      (id_reserva IN (SELECT id_reserva FROM reserva WHERE id_cliente = fn_cliente_del_usuario()))
    WITH CHECK (id_reserva IN (SELECT id_reserva FROM reserva WHERE id_cliente = fn_cliente_del_usuario()));
CREATE POLICY garantia_staff_all ON garantia_reserva
    FOR ALL TO authenticated
    USING (fn_es_staff()) WITH CHECK (fn_es_staff());

-- ============================================================
-- ALQUILER: cliente solo lectura de los suyos. Crear/cerrar solo staff.
-- ============================================================

DROP POLICY IF EXISTS alquiler_owner_read ON alquiler;
DROP POLICY IF EXISTS alquiler_staff_all  ON alquiler;
CREATE POLICY alquiler_owner_read ON alquiler
    FOR SELECT TO authenticated
    USING (id_cliente = fn_cliente_del_usuario());
CREATE POLICY alquiler_staff_all ON alquiler
    FOR ALL TO authenticated
    USING (fn_es_staff()) WITH CHECK (fn_es_staff());

-- ============================================================
-- FACTURA: cliente lectura de las suyas. Generadas por staff via RPC.
-- ============================================================

DROP POLICY IF EXISTS factura_owner_read ON factura;
DROP POLICY IF EXISTS factura_staff_all  ON factura;
CREATE POLICY factura_owner_read ON factura
    FOR SELECT TO authenticated
    USING (id_cliente = fn_cliente_del_usuario());
CREATE POLICY factura_staff_all ON factura
    FOR ALL TO authenticated
    USING (fn_es_staff()) WITH CHECK (fn_es_staff());

-- ============================================================
-- HISTORIAL Y UBICACION: solo staff (operativo interno).
-- ============================================================

DROP POLICY IF EXISTS ubicacion_staff_all          ON ubicacion_vehiculo;
DROP POLICY IF EXISTS historial_estado_staff_all   ON historial_estado_vehiculo;
DROP POLICY IF EXISTS mantenimiento_staff_all      ON mantenimiento;
CREATE POLICY ubicacion_staff_all        ON ubicacion_vehiculo        FOR ALL TO authenticated USING (fn_es_staff()) WITH CHECK (fn_es_staff());
CREATE POLICY historial_estado_staff_all ON historial_estado_vehiculo FOR ALL TO authenticated USING (fn_es_staff()) WITH CHECK (fn_es_staff());
CREATE POLICY mantenimiento_staff_all    ON mantenimiento             FOR ALL TO authenticated USING (fn_es_staff()) WITH CHECK (fn_es_staff());

-- ============================================================
-- GRANTS para roles de Supabase
-- ============================================================
-- Los roles anon y authenticated necesitan USAGE sobre el schema y
-- SELECT/INSERT/UPDATE/DELETE sobre las tablas; RLS recorta el alcance fila
-- por fila. Sin GRANT no llegan ni a evaluar las policies.

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'anon') THEN
        EXECUTE 'GRANT USAGE ON SCHEMA public TO anon, authenticated';
        EXECUTE 'GRANT SELECT ON ALL TABLES IN SCHEMA public TO anon';
        EXECUTE 'GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO authenticated';
        EXECUTE 'GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO authenticated';
        EXECUTE 'GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO authenticated';
        EXECUTE 'GRANT EXECUTE ON ALL PROCEDURES IN SCHEMA public TO authenticated';
    END IF;
END
$$;
