-- Tabla tipo_reserva (R7).
--
-- Catalogo de modalidades de reserva (reserva estandar, reserva con
-- garantia, reserva corporativa, etc). Define dos politicas declarativas
-- que consume el procedure pa_registrar_reserva:
--   * requiere_garantia: si TRUE, el procedure exige que se registre una
--     fila en garantia_reserva en la misma transaccion.
--   * antelacion_max_dias: cuantos dias hacia adelante se admite reservar.
-- Centralizar estos parametros en un catalogo evita codificarlos en la
-- logica del procedure y permite cambiarlos sin tocar PL/pgSQL.
CREATE TABLE IF NOT EXISTS tipo_reserva (
    id_tipo_reserva      BIGSERIAL PRIMARY KEY,
    nombre               VARCHAR(50)  NOT NULL UNIQUE,
    descripcion          VARCHAR(255),
    requiere_garantia    BOOLEAN      NOT NULL DEFAULT FALSE,
    antelacion_max_dias  INTEGER      NOT NULL DEFAULT 30,
    CONSTRAINT chk_tipo_reserva_antelacion CHECK (antelacion_max_dias > 0)
);
