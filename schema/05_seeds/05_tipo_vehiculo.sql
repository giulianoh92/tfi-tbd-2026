-- Tipos representativos del mercado argentino, con foco en lo que circula en NEA:
-- mezcla de compactos urbanos, sedanes, SUVs y pickups (alta demanda zonal por
-- turismo de aventura y uso forestal/rural). Utilitario reemplaza a Cupe porque
-- los Kangoo/Partner son frecuentes en flotas de alquiler regional, los cupes
-- practicamente no circulan.
INSERT INTO tipo_vehiculo (nombre, descripcion) VALUES
    ('Compacto',   'Vehiculo compacto de uso urbano, bajo consumo'),
    ('Sedan',      'Vehiculo de 4 puertas con baul separado, uso familiar y corporativo'),
    ('SUV',        'Vehiculo deportivo utilitario, alto despeje, ideal para turismo'),
    ('Pickup',     'Camioneta con caja de carga, traccion 4x4, demanda alta en NEA'),
    ('Utilitario', 'Furgon o van de carga, hasta 800 kg, segmento corporativo');
