-- Datos demo del catalogo estado_vehiculo (R10).
-- Carga los cinco estados que reconocen los triggers de FSM
-- (fn_alquiler_lifecycle y fn_mantenimiento_lifecycle) y el procedure
-- pa_baja_vehiculo. Los nombres deben ir en minusculas: el CHECK de la
-- tabla y los lookups con lower(nombre) lo exigen.
INSERT INTO estado_vehiculo (nombre, descripcion) VALUES
    ('disponible',      'Vehiculo disponible para alquiler'),
    ('alquilado',       'Vehiculo entregado a cliente en alquiler vigente'),
    ('en_mantenimiento','Vehiculo en taller mecanico'),
    ('en_traslado',     'En transito entre sucursales'),
    -- Estado terminal para baja de flota (R3). Como el schema no
    -- tiene flag soft-delete sobre `vehiculo`, pa_baja_vehiculo transiciona
    -- id_estado a este valor. Un vehiculo en estado 'baja' queda fuera de
    -- fn_validar_vehiculo_operativo (no es 'disponible'), por lo que ni
    -- reservas ni alquileres nuevos pueden referenciarlo.
    ('baja',            'Vehiculo dado de baja de la flota (no operativo)');
