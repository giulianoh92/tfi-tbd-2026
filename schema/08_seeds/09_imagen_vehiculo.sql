-- 5 imagenes por vehiculo (3 exteriores + 2 interiores), 50 filas en total.
-- Las URLs apuntan al repositorio publico del proyecto en GitHub (rama main),
-- donde el equipo cargara los archivos bajo assets/vehiculos/vNN-marca-modelo/
-- siguiendo la guia en assets/vehiculos/README.md.
--
-- El disparador trg_imagen_vehiculo_max (BEFORE INSERT) garantiza un maximo de 5.
-- El UNIQUE compuesto (id_vehiculo, orden) impide colisiones de posicion.
INSERT INTO imagen_vehiculo (id_vehiculo, url_imagen, orden) VALUES
    -- v1 Fiat Cronos
    (1,  'https://raw.githubusercontent.com/giulianoh92/tfi-tbd-2026/main/assets/vehiculos/v01-fiat-cronos/exterior-01.jpg', 1),
    (1,  'https://raw.githubusercontent.com/giulianoh92/tfi-tbd-2026/main/assets/vehiculos/v01-fiat-cronos/exterior-02.jpg', 2),
    (1,  'https://raw.githubusercontent.com/giulianoh92/tfi-tbd-2026/main/assets/vehiculos/v01-fiat-cronos/exterior-03.jpg', 3),
    (1,  'https://raw.githubusercontent.com/giulianoh92/tfi-tbd-2026/main/assets/vehiculos/v01-fiat-cronos/interior-01.jpg', 4),
    (1,  'https://raw.githubusercontent.com/giulianoh92/tfi-tbd-2026/main/assets/vehiculos/v01-fiat-cronos/interior-02.jpg', 5),

    -- v2 Toyota Corolla
    (2,  'https://raw.githubusercontent.com/giulianoh92/tfi-tbd-2026/main/assets/vehiculos/v02-toyota-corolla/exterior-01.jpg', 1),
    (2,  'https://raw.githubusercontent.com/giulianoh92/tfi-tbd-2026/main/assets/vehiculos/v02-toyota-corolla/exterior-02.jpg', 2),
    (2,  'https://raw.githubusercontent.com/giulianoh92/tfi-tbd-2026/main/assets/vehiculos/v02-toyota-corolla/exterior-03.jpg', 3),
    (2,  'https://raw.githubusercontent.com/giulianoh92/tfi-tbd-2026/main/assets/vehiculos/v02-toyota-corolla/interior-01.jpg', 4),
    (2,  'https://raw.githubusercontent.com/giulianoh92/tfi-tbd-2026/main/assets/vehiculos/v02-toyota-corolla/interior-02.jpg', 5),

    -- v3 VW Gol Trend
    (3,  'https://raw.githubusercontent.com/giulianoh92/tfi-tbd-2026/main/assets/vehiculos/v03-vw-gol-trend/exterior-01.jpg', 1),
    (3,  'https://raw.githubusercontent.com/giulianoh92/tfi-tbd-2026/main/assets/vehiculos/v03-vw-gol-trend/exterior-02.jpg', 2),
    (3,  'https://raw.githubusercontent.com/giulianoh92/tfi-tbd-2026/main/assets/vehiculos/v03-vw-gol-trend/exterior-03.jpg', 3),
    (3,  'https://raw.githubusercontent.com/giulianoh92/tfi-tbd-2026/main/assets/vehiculos/v03-vw-gol-trend/interior-01.jpg', 4),
    (3,  'https://raw.githubusercontent.com/giulianoh92/tfi-tbd-2026/main/assets/vehiculos/v03-vw-gol-trend/interior-02.jpg', 5),

    -- v4 Chevrolet Onix
    (4,  'https://raw.githubusercontent.com/giulianoh92/tfi-tbd-2026/main/assets/vehiculos/v04-chevrolet-onix/exterior-01.jpg', 1),
    (4,  'https://raw.githubusercontent.com/giulianoh92/tfi-tbd-2026/main/assets/vehiculos/v04-chevrolet-onix/exterior-02.jpg', 2),
    (4,  'https://raw.githubusercontent.com/giulianoh92/tfi-tbd-2026/main/assets/vehiculos/v04-chevrolet-onix/exterior-03.jpg', 3),
    (4,  'https://raw.githubusercontent.com/giulianoh92/tfi-tbd-2026/main/assets/vehiculos/v04-chevrolet-onix/interior-01.jpg', 4),
    (4,  'https://raw.githubusercontent.com/giulianoh92/tfi-tbd-2026/main/assets/vehiculos/v04-chevrolet-onix/interior-02.jpg', 5),

    -- v5 Toyota Hilux
    (5,  'https://raw.githubusercontent.com/giulianoh92/tfi-tbd-2026/main/assets/vehiculos/v05-toyota-hilux/exterior-01.jpg', 1),
    (5,  'https://raw.githubusercontent.com/giulianoh92/tfi-tbd-2026/main/assets/vehiculos/v05-toyota-hilux/exterior-02.jpg', 2),
    (5,  'https://raw.githubusercontent.com/giulianoh92/tfi-tbd-2026/main/assets/vehiculos/v05-toyota-hilux/exterior-03.jpg', 3),
    (5,  'https://raw.githubusercontent.com/giulianoh92/tfi-tbd-2026/main/assets/vehiculos/v05-toyota-hilux/interior-01.jpg', 4),
    (5,  'https://raw.githubusercontent.com/giulianoh92/tfi-tbd-2026/main/assets/vehiculos/v05-toyota-hilux/interior-02.jpg', 5),

    -- v6 Jeep Renegade
    (6,  'https://raw.githubusercontent.com/giulianoh92/tfi-tbd-2026/main/assets/vehiculos/v06-jeep-renegade/exterior-01.jpg', 1),
    (6,  'https://raw.githubusercontent.com/giulianoh92/tfi-tbd-2026/main/assets/vehiculos/v06-jeep-renegade/exterior-02.jpg', 2),
    (6,  'https://raw.githubusercontent.com/giulianoh92/tfi-tbd-2026/main/assets/vehiculos/v06-jeep-renegade/exterior-03.jpg', 3),
    (6,  'https://raw.githubusercontent.com/giulianoh92/tfi-tbd-2026/main/assets/vehiculos/v06-jeep-renegade/interior-01.jpg', 4),
    (6,  'https://raw.githubusercontent.com/giulianoh92/tfi-tbd-2026/main/assets/vehiculos/v06-jeep-renegade/interior-02.jpg', 5),

    -- v7 Toyota SW4
    (7,  'https://raw.githubusercontent.com/giulianoh92/tfi-tbd-2026/main/assets/vehiculos/v07-toyota-sw4/exterior-01.jpg', 1),
    (7,  'https://raw.githubusercontent.com/giulianoh92/tfi-tbd-2026/main/assets/vehiculos/v07-toyota-sw4/exterior-02.jpg', 2),
    (7,  'https://raw.githubusercontent.com/giulianoh92/tfi-tbd-2026/main/assets/vehiculos/v07-toyota-sw4/exterior-03.jpg', 3),
    (7,  'https://raw.githubusercontent.com/giulianoh92/tfi-tbd-2026/main/assets/vehiculos/v07-toyota-sw4/interior-01.jpg', 4),
    (7,  'https://raw.githubusercontent.com/giulianoh92/tfi-tbd-2026/main/assets/vehiculos/v07-toyota-sw4/interior-02.jpg', 5),

    -- v8 Renault Kangoo
    (8,  'https://raw.githubusercontent.com/giulianoh92/tfi-tbd-2026/main/assets/vehiculos/v08-renault-kangoo/exterior-01.jpg', 1),
    (8,  'https://raw.githubusercontent.com/giulianoh92/tfi-tbd-2026/main/assets/vehiculos/v08-renault-kangoo/exterior-02.jpg', 2),
    (8,  'https://raw.githubusercontent.com/giulianoh92/tfi-tbd-2026/main/assets/vehiculos/v08-renault-kangoo/exterior-03.jpg', 3),
    (8,  'https://raw.githubusercontent.com/giulianoh92/tfi-tbd-2026/main/assets/vehiculos/v08-renault-kangoo/interior-01.jpg', 4),
    (8,  'https://raw.githubusercontent.com/giulianoh92/tfi-tbd-2026/main/assets/vehiculos/v08-renault-kangoo/interior-02.jpg', 5),

    -- v9 Ford Ranger
    (9,  'https://raw.githubusercontent.com/giulianoh92/tfi-tbd-2026/main/assets/vehiculos/v09-ford-ranger/exterior-01.jpg', 1),
    (9,  'https://raw.githubusercontent.com/giulianoh92/tfi-tbd-2026/main/assets/vehiculos/v09-ford-ranger/exterior-02.jpg', 2),
    (9,  'https://raw.githubusercontent.com/giulianoh92/tfi-tbd-2026/main/assets/vehiculos/v09-ford-ranger/exterior-03.jpg', 3),
    (9,  'https://raw.githubusercontent.com/giulianoh92/tfi-tbd-2026/main/assets/vehiculos/v09-ford-ranger/interior-01.jpg', 4),
    (9,  'https://raw.githubusercontent.com/giulianoh92/tfi-tbd-2026/main/assets/vehiculos/v09-ford-ranger/interior-02.jpg', 5),

    -- v10 VW T-Cross
    (10, 'https://raw.githubusercontent.com/giulianoh92/tfi-tbd-2026/main/assets/vehiculos/v10-vw-tcross/exterior-01.jpg', 1),
    (10, 'https://raw.githubusercontent.com/giulianoh92/tfi-tbd-2026/main/assets/vehiculos/v10-vw-tcross/exterior-02.jpg', 2),
    (10, 'https://raw.githubusercontent.com/giulianoh92/tfi-tbd-2026/main/assets/vehiculos/v10-vw-tcross/exterior-03.jpg', 3),
    (10, 'https://raw.githubusercontent.com/giulianoh92/tfi-tbd-2026/main/assets/vehiculos/v10-vw-tcross/interior-01.jpg', 4),
    (10, 'https://raw.githubusercontent.com/giulianoh92/tfi-tbd-2026/main/assets/vehiculos/v10-vw-tcross/interior-02.jpg', 5);
