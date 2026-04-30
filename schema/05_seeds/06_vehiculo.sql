-- Distribucion: 10 vehiculos en 5 sucursales y 5 tipos.
-- Estados alineados con alquileres/mantenimientos en curso de los seeds posteriores:
--   * vehiculo 3 y 9: 'alquilado'  (alquileres en_curso)
--   * vehiculo 5    : 'mantenimiento' (mantenimiento abierto)
--   * resto         : 'disponible'
INSERT INTO vehiculo (id_sucursal, id_tipo, marca, modelo, anio, patente, km_actuales, detalle_confort, estado) VALUES
    (1, 1, 'Toyota',     'Corolla',   2022, 'AB123CD', 35000, 'Aire acond., direccion asistida, GPS',          'disponible'),
    (1, 2, 'Volkswagen', 'Tiguan',    2023, 'AB456EF', 18000, 'Aire acond., asientos cuero, GPS, camara',      'disponible'),
    (2, 1, 'Ford',       'Focus',     2021, 'AB789GH', 52000, 'Aire acond., direccion asistida',               'alquilado'),
    (2, 4, 'Fiat',       'Cronos',    2023, 'AC012IJ', 22000, 'Aire acond., bluetooth, USB',                   'disponible'),
    (2, 3, 'Peugeot',    '208 GT',    2022, 'AC345KL', 28000, 'Aire acond., asientos deportivos, GPS',         'mantenimiento'),
    (3, 2, 'Chevrolet',  'Tracker',   2023, 'AC678MN', 15000, 'Aire acond., GPS, camara',                      'disponible'),
    (3, 5, 'Toyota',     'Hilux',     2022, 'AC901OP', 41000, 'Aire acond., 4x4, direccion asistida',          'disponible'),
    (4, 1, 'Renault',    'Logan',     2021, 'AD234QR', 65000, 'Aire acond., direccion asistida',               'disponible'),
    (4, 4, 'Volkswagen', 'Polo',      2022, 'AD567ST', 38000, 'Aire acond., GPS, USB',                         'alquilado'),
    (4, 4, 'Dodge', 'Viper',      2022, 'AD567ST', 38000, 'Aire acond., GPS, USB',                         'alquilado'),
    (5, 2, 'Jeep',       'Renegade',  2023, 'AD890UV', 12000, 'Aire acond., asientos cuero, GPS',              'disponible');
