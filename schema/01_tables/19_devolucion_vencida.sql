-- Tabla historica de devoluciones vencidas (R9).
--
-- Poblada por pa_detectar_devoluciones_vencidas() programado via pg_cron
-- cada 6 horas. Un alquiler 'activo' cuya fecha_fin_prevista < NOW() y aun
-- no tiene fecha_devolucion_real es candidato a aparecer aca.
--
-- Diseno:
--   * id_alquiler UNIQUE -> permite ON CONFLICT (id_alquiler) DO UPDATE en
--     el procedure de deteccion. Si la tarea corre 3 veces sobre el mismo
--     alquiler vencido, hay UNA sola fila historica con horas_excedidas
--     actualizadas (no se duplican filas en cada ejecucion del cron).
--   * id_vehiculo / id_cliente NOT NULL -> denormalizados desde alquiler
--     para que las consultas del panel del personal no tengan que hacer JOIN
--     con `alquiler` (que sigue su ciclo de vida y eventualmente puede
--     cerrarse).
--   * fecha_fin_prevista TIMESTAMP (sin tz) -> coincide con el tipo de la
--     columna en `alquiler.fecha_fin_prevista`.
--   * fecha_deteccion TIMESTAMPTZ -> metadato de la tarea programada (hora
--     del servidor, con zona horaria).
--   * horas_excedidas NUMERIC(8,2) -> precision suficiente para mas de un
--     anio de atraso (8760 hs cabe en 8 digitos).
--   * notificado BOOLEAN -> indicador que el personal actualiza desde el
--     panel cuando se contacta al cliente.
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
