-- Clientes 1-5 con cuenta online (id_usuario), 6-7 walk-in sin login
INSERT INTO cliente (id_usuario, nombre, apellido, dni, telefono, direccion) VALUES
    (1,    'Juan',   'Perez',     '30123456', '011-4555-1111', 'Av. Corrientes 1234, CABA'),
    (2,    'Maria',  'Gomez',     '28987654', '011-4555-2222', 'Av. Santa Fe 4321, CABA'),
    (3,    'Luis',   'Rodriguez', '32456789', '011-4555-3333', 'Av. Cabildo 2500, CABA'),
    (4,    'Ana',    'Sanchez',   '29876543', '0341-555-4444', 'Bv. Orono 1100, Rosario'),
    (5,    'Carlos', 'Martinez',  '31234567', '0351-555-5555', 'Av. Velez Sarsfield 800, Cordoba'),
    (NULL, 'Sofia',  'Lopez',     '33456789', '011-4555-6666', 'Av. del Libertador 5000, San Isidro'),
    (NULL, 'Pedro',  'Fernandez', '27654321', '011-4555-7777', 'Av. Rivadavia 9000, CABA');
