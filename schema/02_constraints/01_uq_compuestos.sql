-- Restricciones UNIQUE compuestas.
--
-- uq_tarifa_sucursal_tipo: garantiza una sola tarifa vigente por
-- combinacion (sucursal, tipo de vehiculo). fn_calcular_factura se apoya
-- en esta unicidad para que la consulta de tarifa por sucursal + tipo no sea
-- ambigua (R10).
-- uq_imagen_vehiculo_orden: cada vehiculo puede tener hasta 5 imagenes,
-- con `orden` 1..5 sin repetir. Sostiene el ordenamiento visual en la
-- interfaz y trabaja en conjunto con la CHECK constraint chk_imagen_orden
-- y con el disparador trg_check_max_imagenes que limita el total a 5.
-- uq_resumen_periodo_sucursal: un solo cierre contable por (mes, sucursal).
-- Habilita el UPSERT idempotente (ON CONFLICT) de pa_cerrar_facturacion
-- _mensual: re-correr el cierre de un mes refresca la fila en lugar de
-- duplicarla (R13).
ALTER TABLE tarifa
    ADD CONSTRAINT uq_tarifa_sucursal_tipo UNIQUE (id_sucursal, id_tipo);

ALTER TABLE imagen_vehiculo
    ADD CONSTRAINT uq_imagen_vehiculo_orden UNIQUE (id_vehiculo, orden);

ALTER TABLE resumen_mensual_sucursal
    ADD CONSTRAINT uq_resumen_periodo_sucursal UNIQUE (periodo, id_sucursal);
