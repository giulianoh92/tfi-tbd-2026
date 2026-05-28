-- FK cliente -> usuario.
--
-- ON DELETE SET NULL: el cliente conserva su identidad de dominio aunque
-- se borre el usuario asociado (caso de baja de la cuenta en la aplicacion).
-- Sin esto, una baja del usuario implicaria perder la trazabilidad historica
-- de todas las reservas, alquileres y facturas de ese cliente.
ALTER TABLE cliente
    ADD CONSTRAINT fk_cliente_usuario
        FOREIGN KEY (id_usuario)
        REFERENCES usuario (id_usuario)
        ON UPDATE CASCADE
        ON DELETE SET NULL;
