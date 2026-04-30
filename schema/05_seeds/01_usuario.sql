INSERT INTO usuario (username, password_hash, email) VALUES
    ('jperez',     crypt('pass1', gen_salt('bf')), 'jperez@example.com'),
    ('mgomez',     crypt('pass2', gen_salt('bf')), 'mgomez@example.com'),
    ('lrodriguez', crypt('pass3', gen_salt('bf')), 'lrodriguez@example.com'),
    ('asanchez',   crypt('pass4', gen_salt('bf')), 'asanchez@example.com'),
    ('cmartinez',  crypt('pass5', gen_salt('bf')), 'cmartinez@example.com');
