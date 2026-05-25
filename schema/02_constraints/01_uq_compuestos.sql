-- Constraints UNIQUE compuestas.
--
-- uq_tarifa_sucursal_tipo: asegura una sola tarifa vigente por
-- combinacion (sucursal, tipo de vehiculo). fn_calcular_factura se apoya
-- en esta unicidad para que el lookup de tarifa por sucursal + tipo no sea
-- ambiguo (R10).
-- uq_imagen_vehiculo_orden: cada vehiculo puede tener hasta 5 imagenes,
-- con `orden` 1..5 sin repetir. Sostiene el ordenamiento visual del
-- frontend y trabaja en conjunto con la CHECK constraint chk_imagen_orden
-- y con el trigger trg_check_max_imagenes que limita el total a 5.
ALTER TABLE tarifa
    ADD CONSTRAINT uq_tarifa_sucursal_tipo UNIQUE (id_sucursal, id_tipo);

ALTER TABLE imagen_vehiculo
    ADD CONSTRAINT uq_imagen_vehiculo_orden UNIQUE (id_vehiculo, orden);
