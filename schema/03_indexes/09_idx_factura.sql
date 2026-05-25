-- Indice de soporte para la FK factura -> cliente (R10).
--
-- Acelera el listado "historial de facturas de un cliente" tipico del
-- panel de cuenta. id_alquiler ya tiene indice implicito por su UNIQUE
-- constraint en la tabla.
CREATE INDEX idx_factura_cliente ON factura (id_cliente);
