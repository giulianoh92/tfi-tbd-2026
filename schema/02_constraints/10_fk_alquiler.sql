-- FKs de alquiler (R6, R10).
--
-- fk_alquiler_reserva con ON DELETE SET NULL: cubre R6 (alquiler con o
-- sin reserva). Si la reserva se eliminara fisicamente, el alquiler
-- conserva la fila pero pierde el puntero. En el flujo normal no se
-- borran reservas (se cancelan), por lo que este SET NULL es solo un
-- fallback defensivo.
-- Resto de FKs con ON DELETE RESTRICT: cliente, vehiculo, tarifa y
-- sucursal de devolucion son referencias historicas que el alquiler usa
-- al momento de facturar (R10); no se admite su borrado mientras el
-- alquiler exista.
ALTER TABLE alquiler
    ADD CONSTRAINT fk_alquiler_reserva
        FOREIGN KEY (id_reserva)
        REFERENCES reserva (id_reserva)
        ON UPDATE CASCADE
        ON DELETE SET NULL,
    ADD CONSTRAINT fk_alquiler_cliente
        FOREIGN KEY (id_cliente)
        REFERENCES cliente (id_cliente)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    ADD CONSTRAINT fk_alquiler_vehiculo
        FOREIGN KEY (id_vehiculo)
        REFERENCES vehiculo (id_vehiculo)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    ADD CONSTRAINT fk_alquiler_tarifa
        FOREIGN KEY (id_tarifa)
        REFERENCES tarifa (id_tarifa)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    ADD CONSTRAINT fk_alquiler_sucursal_devolucion
        FOREIGN KEY (id_sucursal_devolucion)
        REFERENCES sucursal (id_sucursal)
        ON UPDATE CASCADE
        ON DELETE RESTRICT;
