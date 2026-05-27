-- Tabla cliente (R3, R6).
--
-- Modelo de dominio de la persona fisica que reserva y/o alquila
-- vehiculos. Se soporta tanto al cliente con cuenta online (registrado a
-- traves de Supabase Auth) como al cliente walk-in que opera presencial
-- sin login (R6).
--
-- auth_user_id: bridge con Supabase Auth (auth.users.id, tipo UUID). Sin
-- FK formal a auth.users para mantener el schema portable fuera de
-- Supabase.
-- UNIQUE garantiza mapping 1:1 con la identidad. El trigger
-- fn_handle_new_auth_user crea automaticamente la fila cliente en cada
-- signUp; pa_registrar_cliente_walkin la crea con auth_user_id NULL para
-- los presenciales.
CREATE TABLE IF NOT EXISTS cliente (
    id_cliente    BIGSERIAL PRIMARY KEY,
    id_usuario    BIGINT       UNIQUE,
    auth_user_id  UUID         UNIQUE,
    nombre        VARCHAR(100) NOT NULL,
    apellido      VARCHAR(100) NOT NULL,
    dni           VARCHAR(20)  NOT NULL UNIQUE,
    telefono      VARCHAR(30),
    direccion     VARCHAR(200)
);
