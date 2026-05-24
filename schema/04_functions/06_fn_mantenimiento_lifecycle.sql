-- AFTER INSERT: move vehicle FSM to 'en_mantenimiento'.
CREATE OR REPLACE FUNCTION fn_mantenimiento_envio()
RETURNS TRIGGER AS $$
DECLARE
    v_id_estado BIGINT;
BEGIN
    -- Bugfix deploy: el catalogo estado_vehiculo registra "en_mantenimiento"
    -- (no "mantenimiento"). El nombre antiguo provocaba que el seed de
    -- mantenimiento fallara y bloqueaba el apply completo.
    SELECT id_estado INTO v_id_estado
    FROM estado_vehiculo WHERE nombre = 'en_mantenimiento';

    IF v_id_estado IS NULL THEN
        RAISE EXCEPTION 'Estado vehiculo "en_mantenimiento" no encontrado en catalogo';
    END IF;

    -- Close current open historial row
    UPDATE historial_estado_vehiculo
    SET fecha_fin = NOW()
    WHERE id_vehiculo = NEW.id_vehiculo
      AND fecha_fin IS NULL;

    -- Insert new historial row
    INSERT INTO historial_estado_vehiculo (id_vehiculo, id_estado, fecha_inicio, fecha_fin, motivo)
    VALUES (NEW.id_vehiculo, v_id_estado, NOW(), NULL, 'Envio a mantenimiento');

    -- Mirror current state on vehiculo
    UPDATE vehiculo
    SET id_estado = v_id_estado
    WHERE id_vehiculo = NEW.id_vehiculo;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_mantenimiento_envio ON mantenimiento;

CREATE TRIGGER trg_mantenimiento_envio
    AFTER INSERT ON mantenimiento
    FOR EACH ROW
    EXECUTE FUNCTION fn_mantenimiento_envio();


-- AFTER UPDATE: when fecha_devolucion transitions NULL -> non-NULL,
-- move vehicle FSM back to 'disponible'.
CREATE OR REPLACE FUNCTION fn_mantenimiento_devolucion()
RETURNS TRIGGER AS $$
DECLARE
    v_id_estado BIGINT;
BEGIN
    SELECT id_estado INTO v_id_estado
    FROM estado_vehiculo WHERE nombre = 'disponible';

    IF v_id_estado IS NULL THEN
        RAISE EXCEPTION 'Estado vehiculo "disponible" no encontrado en catalogo';
    END IF;

    -- Close current open historial row
    UPDATE historial_estado_vehiculo
    SET fecha_fin = NOW()
    WHERE id_vehiculo = NEW.id_vehiculo
      AND fecha_fin IS NULL;

    -- Insert new historial row for 'disponible'
    INSERT INTO historial_estado_vehiculo (id_vehiculo, id_estado, fecha_inicio, fecha_fin, motivo)
    VALUES (NEW.id_vehiculo, v_id_estado, NOW(), NULL, 'Devolucion de mantenimiento');

    -- Mirror current state on vehiculo
    UPDATE vehiculo
    SET id_estado = v_id_estado
    WHERE id_vehiculo = NEW.id_vehiculo;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_mantenimiento_devolucion ON mantenimiento;

CREATE TRIGGER trg_mantenimiento_devolucion
    AFTER UPDATE ON mantenimiento
    FOR EACH ROW
    WHEN (OLD.fecha_devolucion IS NULL AND NEW.fecha_devolucion IS NOT NULL)
    EXECUTE FUNCTION fn_mantenimiento_devolucion();
