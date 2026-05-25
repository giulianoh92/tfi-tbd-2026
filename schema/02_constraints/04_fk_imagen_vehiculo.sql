-- FK imagen_vehiculo -> vehiculo.
--
-- ON DELETE CASCADE: las imagenes son data accesoria del vehiculo, no
-- tiene sentido conservarlas si el vehiculo desaparece. Caso de uso:
-- limpieza de un vehiculo cargado por error durante una demo.
ALTER TABLE imagen_vehiculo
    ADD CONSTRAINT fk_imagen_vehiculo_vehiculo
        FOREIGN KEY (id_vehiculo)
        REFERENCES vehiculo (id_vehiculo)
        ON UPDATE CASCADE
        ON DELETE CASCADE;
