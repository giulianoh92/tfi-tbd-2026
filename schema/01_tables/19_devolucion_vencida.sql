-- Tabla historica de devoluciones vencidas (R9, Sprint 4).
--
-- Poblada por pa_detectar_devoluciones_vencidas() schedulado via pg_cron
-- cada 6 horas. Un alquiler 'activo' cuya fecha_fin_prevista < NOW() y aun
-- no tiene fecha_devolucion_real es candidato a aparecer aca.
--
-- Diseno:
--   * id_alquiler UNIQUE -> permite ON CONFLICT (id_alquiler) DO UPDATE en
--     el procedure de deteccion. Si el job corre 3 veces sobre el mismo
--     alquiler vencido, hay UNA sola fila historica con horas_excedidas
--     actualizadas (no se duplican filas en cada pasada del cron).
--   * id_vehiculo / id_cliente NOT NULL -> denormalizados desde alquiler
--     para que las consultas del panel staff no tengan que joinear con
--     `alquiler` (que sigue su lifecycle y eventualmente puede cerrar).
--   * fecha_fin_prevista TIMESTAMP (sin tz) -> coincide con el tipo de la
--     columna en `alquiler.fecha_fin_prevista`.
--   * fecha_deteccion TIMESTAMPTZ -> es metadato del job (hora del server,
--     timezone-aware).
--   * horas_excedidas NUMERIC(8,2) -> precision suficiente para 1+ ano de
--     atraso (8760 hs cabe en 8 digitos).
--   * notificado BOOLEAN -> flag que el staff toggle desde el panel cuando
--     contacta al cliente.
CREATE TABLE IF NOT EXISTS devolucion_vencida (
    id_devolucion_vencida BIGSERIAL    PRIMARY KEY,
    id_alquiler           BIGINT       NOT NULL UNIQUE,
    id_vehiculo           BIGINT       NOT NULL,
    id_cliente            BIGINT       NOT NULL,
    fecha_fin_prevista    TIMESTAMP    NOT NULL,
    fecha_deteccion       TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    horas_excedidas       NUMERIC(8,2) NOT NULL DEFAULT 0,
    notificado            BOOLEAN      NOT NULL DEFAULT FALSE,
    CONSTRAINT chk_devolucion_vencida_horas CHECK (horas_excedidas >= 0)
);
