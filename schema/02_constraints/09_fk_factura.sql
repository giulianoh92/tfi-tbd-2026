ALTER TABLE factura DROP CONSTRAINT IF EXISTS fk_factura_alquiler;
ALTER TABLE factura
    ADD CONSTRAINT fk_factura_alquiler
        FOREIGN KEY (id_alquiler) REFERENCES alquiler (id_alquiler)
        ON UPDATE CASCADE ON DELETE RESTRICT;

ALTER TABLE factura DROP CONSTRAINT IF EXISTS fk_factura_cliente;
ALTER TABLE factura
    ADD CONSTRAINT fk_factura_cliente
        FOREIGN KEY (id_cliente) REFERENCES cliente (id_cliente)
        ON UPDATE CASCADE ON DELETE RESTRICT;