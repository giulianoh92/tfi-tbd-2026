-- All vehicles bootstrap as 'disponible'. Lifecycle triggers (files 15/16) will
-- transition vehicles 3, 9 -> 'alquilado' and vehicle 5 -> 'en_mantenimiento'.
INSERT INTO vehiculo (id_sucursal_origen, id_tipo, id_estado, marca, modelo, anio, patente, km_actuales, detalle_confort) VALUES
    (1, 1, (SELECT id_estado FROM estado_vehiculo WHERE nombre = 'disponible'), 'Toyota',     'Corolla',  2022, 'AB123CD', 35000, 'Aire acond., direccion asistida, GPS'),
    (1, 2, (SELECT id_estado FROM estado_vehiculo WHERE nombre = 'disponible'), 'Volkswagen', 'Tiguan',   2023, 'AB456EF', 18000, 'Aire acond., asientos cuero, GPS, camara'),
    (2, 1, (SELECT id_estado FROM estado_vehiculo WHERE nombre = 'disponible'), 'Ford',       'Focus',    2021, 'AB789GH', 52000, 'Aire acond., direccion asistida'),
    (2, 1, (SELECT id_estado FROM estado_vehiculo WHERE nombre = 'disponible'), 'Fiat',       'Cronos',   2023, 'AC012IJ', 22000, 'Aire acond., bluetooth, USB'),
    (2, 3, (SELECT id_estado FROM estado_vehiculo WHERE nombre = 'disponible'), 'Peugeot',    '208 GT',   2022, 'AC345KL', 28000, 'Aire acond., asientos deportivos, GPS'),
    (3, 2, (SELECT id_estado FROM estado_vehiculo WHERE nombre = 'disponible'), 'Chevrolet',  'Tracker',  2023, 'AC678MN', 15000, 'Aire acond., GPS, camara'),
    (3, 4, (SELECT id_estado FROM estado_vehiculo WHERE nombre = 'disponible'), 'Toyota',     'Hilux',    2022, 'AC901OP', 41000, 'Aire acond., 4x4, direccion asistida'),
    (4, 1, (SELECT id_estado FROM estado_vehiculo WHERE nombre = 'disponible'), 'Renault',    'Logan',    2021, 'AD234QR', 65000, 'Aire acond., direccion asistida'),
    (4, 5, (SELECT id_estado FROM estado_vehiculo WHERE nombre = 'disponible'), 'Volkswagen', 'Polo',     2022, 'AD567ST', 38000, 'Aire acond., GPS, USB'),
    (5, 2, (SELECT id_estado FROM estado_vehiculo WHERE nombre = 'disponible'), 'Jeep',       'Renegade', 2023, 'AD890UV', 12000, 'Aire acond., asientos cuero, GPS');
