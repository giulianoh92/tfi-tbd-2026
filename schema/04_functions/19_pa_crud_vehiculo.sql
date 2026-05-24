-- Functions: pa_crear_vehiculo, pa_actualizar_vehiculo, pa_baja_vehiculo
-- Sprint 3 (R3, R4, R5). CRUD de vehiculo via SP, con retorno estandarizado.
--
-- Decision de diseno: los tres SPs viven en un mismo archivo porque
-- comparten el dominio y el codigo de validacion de rol staff. Cada uno
-- expone su firma independiente.
--
-- R11: declarados como FUNCTIONs (no PROCEDUREs) para que PostgREST los
-- exponga via /rest/v1/rpc. Ver JUSTIFICACION.md §R11.
--
-- Acceso (R3 / Anexo A): las mutaciones de flota son responsabilidad
-- exclusiva del staff. No hay un rol PostgreSQL `staff` separado en este
-- proyecto (los staff se distinguen por claim app_metadata.role = 'staff'
-- del JWT). Por eso el GRANT EXECUTE se da a `authenticated` y cada
-- procedure verifica internamente `fn_es_staff()` (definida en
-- schema/06_permissions/02_rls_helpers.sql). Si no es staff -> ERROR_ESTADO.
-- Esta linea de defensa se suma a las RLS sobre `vehiculo` (no via SP).
--
-- Contrato de retorno (R4): p_estado, p_mensaje, p_id_generado donde aplica.

------------------------------------------------------------------------
-- pa_crear_vehiculo
------------------------------------------------------------------------
-- Estado inicial: lookup en estado_vehiculo WHERE nombre = 'disponible'.
-- Si no existe en el catalogo, retorna ERROR (el seed deberia poblarlo).
CREATE OR REPLACE FUNCTION pa_crear_vehiculo(
    p_id_sucursal_origen BIGINT,
    p_id_tipo            BIGINT,
    p_marca              VARCHAR,
    p_modelo             VARCHAR,
    p_anio               INTEGER,
    p_patente            VARCHAR,
    p_km_actuales        INTEGER,
    p_detalle_confort    TEXT,
    OUT p_estado         TEXT,
    OUT p_mensaje        TEXT,
    OUT p_id_generado    BIGINT
)
RETURNS RECORD
LANGUAGE plpgsql
AS $$
DECLARE
    v_id_estado_disp BIGINT;
BEGIN
    p_estado      := 'ERROR';
    p_mensaje     := NULL;
    p_id_generado := NULL;

    -- Solo staff puede crear vehiculos (defensa en profundidad sobre RLS).
    IF NOT fn_es_staff() THEN
        p_estado  := 'ERROR_ESTADO';
        p_mensaje := 'Operacion permitida solo a usuarios staff.';
        RETURN;
    END IF;

    -- Resolver estado inicial 'disponible' desde el catalogo.
    SELECT id_estado
      INTO v_id_estado_disp
      FROM estado_vehiculo
     WHERE lower(nombre) = 'disponible';

    IF v_id_estado_disp IS NULL THEN
        p_estado  := 'ERROR';
        p_mensaje := 'Estado "disponible" no encontrado en catalogo estado_vehiculo.';
        RETURN;
    END IF;

    INSERT INTO vehiculo (
        id_sucursal_origen,
        id_tipo,
        id_estado,
        marca,
        modelo,
        anio,
        patente,
        km_actuales,
        detalle_confort
    )
    VALUES (
        p_id_sucursal_origen,
        p_id_tipo,
        v_id_estado_disp,
        p_marca,
        p_modelo,
        p_anio,
        p_patente,
        COALESCE(p_km_actuales, 0),
        p_detalle_confort
    )
    RETURNING id_vehiculo INTO p_id_generado;

    p_estado  := 'OK';
    p_mensaje := format('Vehiculo %s creado exitosamente.', p_id_generado);

EXCEPTION
    WHEN unique_violation THEN
        -- patente UNIQUE.
        p_estado      := 'ERROR_DUPLICADO';
        p_mensaje     := SQLERRM;
        p_id_generado := NULL;
    WHEN foreign_key_violation THEN
        -- id_sucursal_origen / id_tipo invalidos.
        p_estado      := 'ERROR_REFERENCIAL';
        p_mensaje     := SQLERRM;
        p_id_generado := NULL;
    WHEN check_violation THEN
        -- chk_vehiculo_km, chk_vehiculo_anio.
        p_estado      := 'ERROR_VALIDACION';
        p_mensaje     := SQLERRM;
        p_id_generado := NULL;
    WHEN OTHERS THEN
        p_estado      := 'ERROR';
        p_mensaje     := SQLERRM;
        p_id_generado := NULL;
END;
$$;


------------------------------------------------------------------------
-- pa_actualizar_vehiculo
------------------------------------------------------------------------
-- Solo se actualizan campos descriptivos. El id_estado se gobierna por los
-- triggers de lifecycle (fn_alquiler_start / fn_alquiler_close /
-- fn_mantenimiento_*). La sucursal de origen tampoco se cambia desde aqui:
-- los traslados se manejan via ubicacion_vehiculo.
CREATE OR REPLACE FUNCTION pa_actualizar_vehiculo(
    p_id_vehiculo     BIGINT,
    p_marca           VARCHAR,
    p_modelo          VARCHAR,
    p_anio            INTEGER,
    p_detalle_confort TEXT,
    OUT p_estado      TEXT,
    OUT p_mensaje     TEXT
)
RETURNS RECORD
LANGUAGE plpgsql
AS $$
DECLARE
    v_filas_afectadas INTEGER;
BEGIN
    p_estado  := 'ERROR';
    p_mensaje := NULL;

    IF NOT fn_es_staff() THEN
        p_estado  := 'ERROR_ESTADO';
        p_mensaje := 'Operacion permitida solo a usuarios staff.';
        RETURN;
    END IF;

    IF p_id_vehiculo IS NULL THEN
        p_estado  := 'ERROR_VALIDACION';
        p_mensaje := 'El id_vehiculo es obligatorio.';
        RETURN;
    END IF;

    UPDATE vehiculo
       SET marca           = COALESCE(p_marca,           marca),
           modelo          = COALESCE(p_modelo,          modelo),
           anio            = COALESCE(p_anio,            anio),
           detalle_confort = COALESCE(p_detalle_confort, detalle_confort)
     WHERE id_vehiculo = p_id_vehiculo;

    GET DIAGNOSTICS v_filas_afectadas = ROW_COUNT;

    IF v_filas_afectadas = 0 THEN
        p_estado  := 'ERROR_REFERENCIAL';
        p_mensaje := format('El vehiculo %s no existe.', p_id_vehiculo);
        RETURN;
    END IF;

    p_estado  := 'OK';
    p_mensaje := format('Vehiculo %s actualizado.', p_id_vehiculo);

EXCEPTION
    WHEN unique_violation THEN
        p_estado  := 'ERROR_DUPLICADO';
        p_mensaje := SQLERRM;
    WHEN check_violation THEN
        p_estado  := 'ERROR_VALIDACION';
        p_mensaje := SQLERRM;
    WHEN foreign_key_violation THEN
        p_estado  := 'ERROR_REFERENCIAL';
        p_mensaje := SQLERRM;
    WHEN OTHERS THEN
        p_estado  := 'ERROR';
        p_mensaje := SQLERRM;
END;
$$;


------------------------------------------------------------------------
-- pa_baja_vehiculo
------------------------------------------------------------------------
-- "Baja logica": como el schema no tiene flag activo/inactivo sobre
-- vehiculo, transicionamos id_estado al estado 'baja' (agregado en
-- 05_seeds/06_estado_vehiculo.sql). Esto saca al vehiculo de cualquier
-- listado operativo (fn_validar_vehiculo_operativo exige 'disponible').
--
-- Validaciones:
--   1) No tener alquileres activos.
--   2) No tener reservas pendientes (defensa adicional: si esta dado de
--      baja no deberian poder concretarse).
--   3) Si ya esta en 'baja' -> ERROR_ESTADO (idempotencia explicita).
--
-- INOUT p_motivo: entra el motivo del staff, sale enriquecido con timestamp
-- + uuid del autor (mismo patron que pa_cancelar_reserva). Quedara visible
-- al caller y se persistira en historial_estado_vehiculo.
CREATE OR REPLACE FUNCTION pa_baja_vehiculo(
    p_id_vehiculo   BIGINT,
    INOUT p_motivo  TEXT,
    OUT p_estado    TEXT,
    OUT p_mensaje   TEXT
)
RETURNS RECORD
LANGUAGE plpgsql
AS $$
DECLARE
    v_id_estado_baja   BIGINT;
    v_id_estado_actual BIGINT;
    v_estado_actual    TEXT;
    v_uuid_app         UUID;
    v_motivo_limpio    TEXT;
    v_tiene_alq        BOOLEAN;
    v_tiene_reserva    BOOLEAN;
BEGIN
    p_estado  := 'ERROR';
    p_mensaje := NULL;

    IF NOT fn_es_staff() THEN
        p_estado  := 'ERROR_ESTADO';
        p_mensaje := 'Operacion permitida solo a usuarios staff.';
        RETURN;
    END IF;

    -- Normalizar motivo y enriquecer (mismo patron que pa_cancelar_reserva).
    v_motivo_limpio := COALESCE(NULLIF(trim(p_motivo), ''), '(sin motivo informado)');

    BEGIN
        v_uuid_app := (current_setting('request.jwt.claims', true)::jsonb ->> 'sub')::UUID;
    EXCEPTION WHEN OTHERS THEN
        v_uuid_app := NULL;
    END;

    p_motivo := format(
        '[%s | usuario %s] %s',
        to_char(NOW(), 'YYYY-MM-DD"T"HH24:MI:SSOF'),
        COALESCE(v_uuid_app::TEXT, 'anonimo'),
        v_motivo_limpio
    );

    -- Resolver estado 'baja' del catalogo.
    SELECT id_estado
      INTO v_id_estado_baja
      FROM estado_vehiculo
     WHERE lower(nombre) = 'baja';

    IF v_id_estado_baja IS NULL THEN
        p_estado  := 'ERROR';
        p_mensaje := 'Estado "baja" no encontrado en catalogo estado_vehiculo (revisar seed).';
        RETURN;
    END IF;

    -- Bloquear la fila para evitar carrera con un alquiler/reserva concurrente.
    SELECT v.id_estado, lower(ev.nombre)
      INTO v_id_estado_actual, v_estado_actual
      FROM vehiculo v
      JOIN estado_vehiculo ev ON ev.id_estado = v.id_estado
     WHERE v.id_vehiculo = p_id_vehiculo
     FOR UPDATE;

    IF NOT FOUND THEN
        p_estado  := 'ERROR_REFERENCIAL';
        p_mensaje := format('El vehiculo %s no existe.', p_id_vehiculo);
        RETURN;
    END IF;

    -- Idempotencia explicita: ya esta en baja.
    IF v_estado_actual = 'baja' THEN
        p_estado  := 'ERROR_ESTADO';
        p_mensaje := format('El vehiculo %s ya esta dado de baja.', p_id_vehiculo);
        RETURN;
    END IF;

    -- No permitir baja con alquileres activos.
    SELECT EXISTS (
        SELECT 1 FROM alquiler
         WHERE id_vehiculo = p_id_vehiculo
           AND estado = 'activo'
    ) INTO v_tiene_alq;

    IF v_tiene_alq THEN
        p_estado  := 'ERROR_ESTADO';
        p_mensaje := format(
            'El vehiculo %s tiene alquileres activos; no se puede dar de baja.',
            p_id_vehiculo
        );
        RETURN;
    END IF;

    -- No permitir baja con reservas pendientes (defensa adicional).
    SELECT EXISTS (
        SELECT 1 FROM reserva
         WHERE id_vehiculo = p_id_vehiculo
           AND estado = 'pendiente'
    ) INTO v_tiene_reserva;

    IF v_tiene_reserva THEN
        p_estado  := 'ERROR_ESTADO';
        p_mensaje := format(
            'El vehiculo %s tiene reservas pendientes; cancelalas antes de la baja.',
            p_id_vehiculo
        );
        RETURN;
    END IF;

    -- Cerrar fila abierta de historial y abrir una para 'baja' con el motivo.
    UPDATE historial_estado_vehiculo
       SET fecha_fin = NOW()
     WHERE id_vehiculo = p_id_vehiculo
       AND fecha_fin IS NULL;

    INSERT INTO historial_estado_vehiculo (
        id_vehiculo, id_estado, fecha_inicio, fecha_fin, motivo
    )
    VALUES (
        -- historial_estado_vehiculo.motivo es VARCHAR(255); truncamos el
        -- motivo enriquecido para evitar string_too_long. El INOUT p_motivo
        -- sigue conteniendo el texto completo para que el caller lo vea.
        p_id_vehiculo, v_id_estado_baja, NOW(), NULL, left(p_motivo, 255)
    );

    -- Espejar estado actual en vehiculo.
    UPDATE vehiculo
       SET id_estado = v_id_estado_baja
     WHERE id_vehiculo = p_id_vehiculo;

    p_estado  := 'OK';
    p_mensaje := format('Vehiculo %s dado de baja.', p_id_vehiculo);

EXCEPTION
    WHEN foreign_key_violation THEN
        p_estado  := 'ERROR_REFERENCIAL';
        p_mensaje := SQLERRM;
    WHEN check_violation THEN
        p_estado  := 'ERROR_VALIDACION';
        p_mensaje := SQLERRM;
    WHEN OTHERS THEN
        p_estado  := 'ERROR';
        p_mensaje := SQLERRM;
END;
$$;
