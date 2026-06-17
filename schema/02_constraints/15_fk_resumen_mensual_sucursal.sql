-- FK de resumen_mensual_sucursal (R13).
--
-- ON DELETE RESTRICT en id_sucursal: el cierre contable es un registro
-- historico; nunca queremos borrar una sucursal que tiene meses consolidados
-- a su nombre (perderia trazabilidad fiscal del periodo). Si una sucursal
-- debe darse de baja, primero hay que resolver su historico de cierres.
ALTER TABLE resumen_mensual_sucursal
    ADD CONSTRAINT fk_resumen_mensual_sucursal_sucursal
        FOREIGN KEY (id_sucursal)
        REFERENCES sucursal (id_sucursal)
        ON UPDATE CASCADE
        ON DELETE RESTRICT;
