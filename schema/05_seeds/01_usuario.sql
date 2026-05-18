INSERT INTO usuario (username, password_hash, email) VALUES
    ('jperez',     crypt('demo1234', gen_salt('bf')), 'jperez@example.com'),
    ('mgomez',     crypt('demo1234', gen_salt('bf')), 'mgomez@example.com'),
    ('lrodriguez', crypt('demo1234', gen_salt('bf')), 'lrodriguez@example.com'),
    ('asanchez',   crypt('demo1234', gen_salt('bf')), 'asanchez@example.com'),
    ('cmartinez',  crypt('demo1234', gen_salt('bf')), 'cmartinez@example.com');
