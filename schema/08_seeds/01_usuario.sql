-- public.usuario no almacena el resumen criptografico (hash) de la contrasena.
-- La autenticacion reside en auth.users (Supabase). Estos datos iniciales solo
-- proveen el enlace logico (id_usuario) para los datos de cliente;
-- no habilitan el inicio de sesion.
INSERT INTO usuario (username, email) VALUES
    ('jperez',     'jperez@example.com'),
    ('mgomez',     'mgomez@example.com'),
    ('lrodriguez', 'lrodriguez@example.com'),
    ('asanchez',   'asanchez@example.com'),
    ('cmartinez',  'cmartinez@example.com');
