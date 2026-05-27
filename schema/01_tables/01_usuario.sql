-- NOTA DE DISENIO: esta tabla NO almacena hash de contrasena.
--
-- La autenticacion del sistema corre por Supabase Auth (auth.users),
-- que persiste la contrasena en auth.users.encrypted_password
-- y emite JWTs firmados con la clave del proyecto. El vinculo entre
-- public.cliente y la identidad de Auth se resuelve via cliente.auth_user_id
-- (UUID), poblado por el trigger fn_handle_new_auth_user al crear un user.
--
-- Razones de tener UNA SOLA fuente de credencial:
--   1. Cambios de contrasena (recovery, magic links) viajan por GoTrue
--      sin que la tabla public.usuario tenga que reflejarlos. Eso elimina
--      el riesgo de divergencia entre dos sistemas que tienen que
--      mantenerse en sync.
--   2. Reduce superficie de filtracion: si se filtra public.* el hash
--      no esta ahi; queda en auth.users (schema bloqueado por defecto
--      para roles non-superuser).
--   3. Permite usar features de Auth (OTP, OAuth, MFA) sin reescribir
--      el flujo de login.
--
-- public.usuario se conserva porque la tabla cliente la referencia (via
-- cliente.id_usuario) como bridge con seeds historicos y como modelo de
-- dominio propio (email + alias). NO duplica auth.users porque la
-- columna sensible (encrypted_password) NO existe aqui.
CREATE TABLE IF NOT EXISTS usuario (
    id_usuario      BIGSERIAL PRIMARY KEY,
    -- username queda como alias humano del usuario (mostrable en UI), no
    -- como identificador de login (eso es email/UUID via Supabase Auth).
    username        VARCHAR(50)  NOT NULL UNIQUE,
    email           VARCHAR(150) NOT NULL UNIQUE,
    created_at      TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
);
