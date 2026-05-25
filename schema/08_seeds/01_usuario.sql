-- public.usuario no almacena password_hash. La autenticacion vive en
-- auth.users (Supabase). Estos seeds solo proveen el bridge logico
-- (id_usuario) para los seeds de cliente; no permiten login.
INSERT INTO usuario (username, email) VALUES
    ('jperez',     'jperez@example.com'),
    ('mgomez',     'mgomez@example.com'),
    ('lrodriguez', 'lrodriguez@example.com'),
    ('asanchez',   'asanchez@example.com'),
    ('cmartinez',  'cmartinez@example.com');
