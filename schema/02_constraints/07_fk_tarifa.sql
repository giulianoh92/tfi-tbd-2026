-- FKs de tarifa.
--
-- ON DELETE RESTRICT en ambas referencias: una sucursal o un tipo de
-- vehiculo no pueden eliminarse mientras existan tarifas que los
-- referencien. La tarifa es input historico de fn_calcular_factura;
-- preservar la integridad referencial es clave para auditoria de precios
-- aplicados (R10).
ALTER TABLE tarifa
    ADD CONSTRAINT fk_tarifa_sucursal
        FOREIGN KEY (id_sucursal)
        REFERENCES sucursal (id_sucursal)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    ADD CONSTRAINT fk_tarifa_tipo
        FOREIGN KEY (id_tipo)
        REFERENCES tipo_vehiculo (id_tipo)
        ON UPDATE CASCADE
        ON DELETE RESTRICT;
