-- Tabla garantia_reserva (R7).
--
-- Datos de la tarjeta de credito presentada como garantia cuando el
-- tipo_reserva.requiere_garantia es TRUE. El procedure pa_registrar_reserva
-- inserta aca en la misma transaccion en que crea la reserva, garantizando
-- atomicidad (R2): si la insercion de garantia falla, la reserva no se
-- persiste. El numero de tarjeta NUNCA se guarda en claro: se almacena un
-- resumen criptografico (numero_tarjeta_hash) calculado por la aplicacion.
-- El flag `activa` permite invalidar una garantia sin borrarla (baja logica
-- con trazabilidad).
CREATE TABLE IF NOT EXISTS garantia_reserva (
    id_garantia          BIGSERIAL    PRIMARY KEY,
    id_reserva           BIGINT       NOT NULL,
    tipo                 VARCHAR(30)  NOT NULL,
    titular              VARCHAR(100) NOT NULL,
    numero_tarjeta_hash  VARCHAR(255) NOT NULL,
    vencimiento          DATE         NOT NULL,
    fecha_registro       TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    activa               BOOLEAN      NOT NULL DEFAULT TRUE
);
