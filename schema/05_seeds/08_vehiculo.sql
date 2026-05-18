-- 10 vehiculos representativos del mercado argentino con foco en NEA:
-- de mas comun a mas confort. Compactos y sedanes para uso urbano, SUVs y
-- pickups para turismo de aventura (Iguazu) y uso rural/forestal, utilitario
-- Kangoo para segmento corporativo regional.
--
-- Bootstrap: todos los vehiculos arrancan en 'disponible'. Los seeds posteriores
-- (15_alquiler, 16_mantenimiento) disparan los triggers de ciclo de vida que
-- transicionan vehiculos 3 y 9 a 'alquilado' y el vehiculo 5 a 'en_mantenimiento'.
--
-- Patentes en formato Mercosur (AA000AA).
INSERT INTO vehiculo (id_sucursal_origen, id_tipo, id_estado, marca, modelo, anio, patente, km_actuales, detalle_confort) VALUES
    -- v1 Fiat Cronos: sedan compacto economico, base de la flota corporativa
    (1, 2, (SELECT id_estado FROM estado_vehiculo WHERE nombre = 'disponible'),
        'Fiat',       'Cronos Drive 1.3',  2023, 'AC056GH', 35000,
        'Aire acondicionado, direccion hidraulica, alzavidrios electricos, radio MP3 con Bluetooth, conector USB.'),

    -- v2 Toyota Corolla: sedan de confort para corporativos y turistas
    (1, 2, (SELECT id_estado FROM estado_vehiculo WHERE nombre = 'disponible'),
        'Toyota',     'Corolla XEi 2.0',   2024, 'AB789LP', 18000,
        'Climatizador automatico, asientos de cuero, control crucero, pantalla tactil 10" con CarPlay/Android Auto, sensores de estacionamiento delanteros y traseros, camara de retroceso.'),

    -- v3 VW Gol Trend: compacto urbano clasico, alta rotacion
    (2, 1, (SELECT id_estado FROM estado_vehiculo WHERE nombre = 'disponible'),
        'Volkswagen', 'Gol Trend 1.6',     2021, 'AD123MN', 52000,
        'Aire acondicionado, direccion hidraulica, alzavidrios delanteros electricos, radio MP3, conector USB.'),

    -- v4 Chevrolet Onix: compacto moderno con multimedia
    (2, 1, (SELECT id_estado FROM estado_vehiculo WHERE nombre = 'disponible'),
        'Chevrolet',  'Onix LT 1.2',       2022, 'AE456OP', 41000,
        'Aire acondicionado, direccion electrica, MyLink 8" con Bluetooth y CarPlay, sensores traseros, control crucero.'),

    -- v5 Toyota Hilux: pickup 4x4 todoterreno para circuitos forestales y selva
    (2, 4, (SELECT id_estado FROM estado_vehiculo WHERE nombre = 'disponible'),
        'Toyota',     'Hilux SRX 4x4',     2024, 'AF780QR', 18000,
        '4x4 con caja reductora, climatizador automatico, sistema multimedia 9", camara 360, asientos de cuero, control de descenso, barra antivuelco.'),

    -- v6 Jeep Renegade: SUV compacto para turismo Iguazu
    (3, 3, (SELECT id_estado FROM estado_vehiculo WHERE nombre = 'disponible'),
        'Jeep',       'Renegade Sport',    2023, 'AG234ST', 15000,
        'Climatizador automatico, Uconnect 8.4" con CarPlay/Android Auto, sensores de estacionamiento, modo Selec-Terrain, ParkSense.'),

    -- v7 Toyota SW4: SUV grande 7 asientos, segmento premium turismo familiar
    (3, 3, (SELECT id_estado FROM estado_vehiculo WHERE nombre = 'disponible'),
        'Toyota',     'SW4 SRX 4x4',       2024, 'AH567UV', 15000,
        'Traccion 4x4 con caja reductora, 7 asientos, climatizador trizona, sistema multimedia 10", control de descenso, sensores 360.'),

    -- v8 Renault Kangoo: utilitario corporativo de carga liviana
    (4, 5, (SELECT id_estado FROM estado_vehiculo WHERE nombre = 'disponible'),
        'Renault',    'Kangoo Express',    2022, 'AJ890WX', 65000,
        'Aire acondicionado, direccion asistida, porton lateral corredizo derecho, capacidad de carga 800 kg, anclajes ISOFIX, radio MP3 con USB.'),

    -- v9 Ford Ranger: pickup 4x4 para uso rural y carga pesada
    (4, 4, (SELECT id_estado FROM estado_vehiculo WHERE nombre = 'disponible'),
        'Ford',       'Ranger XLT 4x4',    2023, 'AK012YZ', 38000,
        '4x4 con bloqueo electronico, climatizador automatico, SYNC 4 con pantalla 12", cargador inalambrico, asientos calefaccionados.'),

    -- v10 VW T-Cross: SUV compacto urbano de gama alta
    (5, 3, (SELECT id_estado FROM estado_vehiculo WHERE nombre = 'disponible'),
        'Volkswagen', 'T-Cross Highline',  2024, 'AL345BC', 12000,
        'Climatizador automatico, MIB3 con pantalla 10.25", asistencia activa de carril, control crucero adaptativo, sensores delanteros y traseros, camara de retroceso.');
