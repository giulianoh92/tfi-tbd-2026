-- Clientes 1-5 con cuenta online (id_usuario), 6-7 walk-in sin login.
-- Direcciones y telefonos coherentes con un perfil de operacion en el NEA:
-- mezcla de clientes locales (Posadas, Obera, Corrientes, Resistencia, Iguazu)
-- y un turista porteño que opera online (cliente 2).
INSERT INTO cliente (id_usuario, nombre, apellido, dni, telefono, direccion) VALUES
    (1,    'Juan',   'Perez',     '30123456', '0376-455-1111', 'Av. Roque Saenz Peña 1234, Posadas'),
    (2,    'Maria',  'Gomez',     '28987654', '011-4555-2222', 'Av. Santa Fe 4321, CABA'),
    (3,    'Luis',   'Rodriguez', '32456789', '0375-540-3333', 'Av. San Martin 980, Obera'),
    (4,    'Ana',    'Sanchez',   '29876543', '0379-442-4444', 'Calle Tucuman 450, Corrientes'),
    (5,    'Carlos', 'Martinez',  '31234567', '0362-444-5555', 'Av. Avalos 1230, Resistencia'),
    (NULL, 'Sofia',  'Lopez',     '33456789', '0375-742-6666', 'Av. Brasil 880, Puerto Iguazu'),
    (NULL, 'Pedro',  'Fernandez', '27654321', '0376-455-7777', 'Bv. Roca 2200, Posadas');
