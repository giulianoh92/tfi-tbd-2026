ALTER TABLE imagen_vehiculo
    ADD CONSTRAINT fk_imagen_vehiculo_vehiculo
        FOREIGN KEY (id_vehiculo)
        REFERENCES vehiculo (id_vehiculo)
        ON UPDATE CASCADE
        ON DELETE CASCADE;
