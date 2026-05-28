-- NOTA DE DISENIO: esta tabla NO almacena el resumen criptografico (hash)
-- de contrasena.
--
-- La autenticacion del sistema corre por Supabase Auth (auth.users),
-- que persiste la contrasena en auth.users.encrypted_password
-- y emite JWTs firmados con la clave del proyecto. El vinculo entre
-- public.cliente y la identidad de Auth se resuelve via cliente.auth_user_id
-- (UUID), poblado por el disparador fn_handle_new_auth_user al crear un
-- usuario.
--
-- Razones de tener UNA SOLA fuente de credencial:
--   1. Cambios de contrasena (recuperacion, magic links) viajan por GoTrue
--      sin que la tabla public.usuario tenga que reflejarlos. Eso elimina
--      el riesgo de divergencia entre dos sistemas que deben mantenerse
--      sincronizados.
--   2. Reduce la superficie de filtracion: si se expone public.* el resumen
--      criptografico no esta ahi; queda en auth.users (esquema bloqueado por
--      defecto para usuarios sin privilegios de administrador).
--   3. Permite usar funciones de Auth (OTP, OAuth, MFA) sin reescribir el
--      flujo de inicio de sesion.
--
-- public.usuario se conserva porque la tabla cliente la referencia (via
-- cliente.id_usuario) como puente con registros historicos y como modelo de
-- dominio propio (email + alias). NO duplica auth.users porque la
-- columna sensible (encrypted_password) NO existe aqui.
CREATE TABLE IF NOT EXISTS usuario (
    id_usuario      BIGSERIAL PRIMARY KEY,
    -- username queda como alias visible del usuario (mostrable en la interfaz), no
    -- como identificador de inicio de sesion (eso es email/UUID via Supabase Auth).
    username        VARCHAR(50)  NOT NULL UNIQUE,
    email           VARCHAR(150) NOT NULL UNIQUE,
    created_at      TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
);
