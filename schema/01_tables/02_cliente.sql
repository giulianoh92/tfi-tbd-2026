-- auth_user_id: bridge con Supabase Auth (auth.users.id, tipo UUID).
-- Sin FK formal a auth.users para mantener el schema portable fuera de Supabase
-- (un docker postgres puro tampoco tiene el schema auth). UNIQUE garantiza
-- mapping 1:1 con la identidad. El trigger fn_handle_new_auth_user (ver
-- 04_functions/07_*.sql) crea la fila cliente automaticamente en cada signUp.
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
