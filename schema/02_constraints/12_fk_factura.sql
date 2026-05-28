-- FKs de factura (R10).
--
-- ON DELETE RESTRICT en ambas referencias: la factura es un documento
-- contable inmutable; ni el alquiler facturado ni el cliente al que se
-- emitio se pueden borrar mientras la factura exista. id_cliente se
-- duplica respecto de alquiler.id_cliente intencionalmente (ver
-- decision de diseno en 01_tables/17_factura.sql) para preservar la
-- instantanea historica del dato al momento de emision.
ALTER TABLE factura
    ADD CONSTRAINT fk_factura_alquiler
        FOREIGN KEY (id_alquiler)
        REFERENCES alquiler (id_alquiler)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    ADD CONSTRAINT fk_factura_cliente
        FOREIGN KEY (id_cliente)
        REFERENCES cliente (id_cliente)
        ON UPDATE CASCADE
        ON DELETE RESTRICT;
