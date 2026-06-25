-- =============================================================================
-- 30_demo_bulk.sql  --  Datos ficticios de volumen para demo funcional
-- =============================================================================
--
-- QUE GENERA
--   Datos ADICIONALES a los seeds 01-18 (que cargan a mano ~10 vehiculos,
--   7 clientes, 8 facturas). Este script genera CIENTOS de filas
--   programaticamente para que el sistema y el reporte contable
--   (vw_facturacion_mensual / resumen_mensual_sucursal) muestren volumen
--   representativo a lo largo de ~18 meses (2025-01 .. hoy) y las 5 sucursales.
--
-- VOLUMENES APROXIMADOS (random, no deterministas salvo setseed):
--   tarifa                     +15  (completa la matriz 5x5; 10 ya existian)
--   usuario                    ~45  (clientes online nuevos)
--   cliente                    ~80  (id > 7)
--   vehiculo                   ~50  (id > 10; flota total ~60)
--   imagen_vehiculo            ~250 (5 por vehiculo nuevo)
--   ubicacion_vehiculo         ~50  (1 vigente por vehiculo nuevo)
--   historial_estado_vehiculo  ~50  (1 inicial por vehiculo nuevo)
--   reserva                    ~600 (concretadas que originan alquiler +
--                                    pendientes futuras + canceladas)
--   garantia_reserva           ~250 (reservas de tipo estandar)
--   alquiler                   ~700 (cerrados historicos + activos recientes)
--   factura                    ~650 (una por alquiler cerrado)
--   mantenimiento              ~40
--   resumen_mensual_sucursal   ~90  (un cierre por (mes, sucursal) con facturas)
--
-- ESTRATEGIA ANTI-EXCLUDE (clave del diseno)
--   excl_reserva_overlap y excl_alquiler_overlap prohiben solapar el mismo
--   vehiculo en ventanas activas (reserva pendiente/concretada, alquiler
--   activo). Por eso las ventanas de cada vehiculo se generan de forma
--   SECUENCIAL con un cursor de fecha que solo avanza: nunca se solapan.
--   Las reservas canceladas y los alquileres cerrados NO participan del
--   exclude, asi que pueden compartir periodos sin conflicto.
--
-- TRIGGERS DE CICLO DE VIDA (importante)
--   Cargar alquileres cerrados historicos via los triggers de lifecycle
--   (fn_alquiler_start / fn_alquiler_close) ensuciaria historial/ubicacion
--   con cientos de transiciones y dejaria el estado del vehiculo inconsistente.
--   Solucion: se DESHABILITAN los triggers de negocio (lifecycle + overlap +
--   auditoria) durante la carga masiva y se setea el estado final del vehiculo
--   a mano. La EXCLUDE constraint sigue activa y garantiza la no-superposicion.
--   Al terminar se REHABILITAN todos los triggers.
--
-- IDEMPOTENCIA
--   No es idempotente por DNI/patente (usa rangos propios), pero pensado para
--   correr UNA vez tras un apply limpio. Re-correr generaria colisiones de
--   UNIQUE (dni/patente/email) -> usar siempre sobre base recien aplicada.
-- =============================================================================

-- setseed permite reproducir la misma "aleatoriedad" si se desea depurar.
SELECT setseed(0.4242);

-- -----------------------------------------------------------------------------
-- FASE 0: deshabilitar triggers de negocio durante la carga masiva.
--   Se mantienen activas las constraints (CHECK, FK, UNIQUE, EXCLUDE): esas
--   no son triggers de usuario y siguen validando cada fila.
-- -----------------------------------------------------------------------------
ALTER TABLE alquiler DISABLE TRIGGER trg_alquiler_start;
ALTER TABLE alquiler DISABLE TRIGGER trg_alquiler_close;
ALTER TABLE alquiler DISABLE TRIGGER trg_alquiler_set_cerrado;
ALTER TABLE alquiler DISABLE TRIGGER trg_alquiler_no_overlap;
ALTER TABLE alquiler DISABLE TRIGGER trg_audit_alquiler;
ALTER TABLE reserva  DISABLE TRIGGER trg_reserva_no_overlap;
ALTER TABLE reserva  DISABLE TRIGGER trg_audit_reserva;
-- Lifecycle de mantenimiento: la FASE 6 inserta mantenimientos como registro
-- historico/operativo y NO debe tocar el estado del vehiculo (lo dice su
-- propio encabezado). Si estos triggers quedan activos, cada INSERT fuerza al
-- vehiculo a 'en_mantenimiento' y pisa el estado 'alquilado' que la FASE 4
-- seteo para las ventanas activas, rompiendo el invariante
-- vehiculo.id_estado='alquilado' <-> alquiler activo.
ALTER TABLE mantenimiento DISABLE TRIGGER trg_mantenimiento_envio;
ALTER TABLE mantenimiento DISABLE TRIGGER trg_mantenimiento_devolucion;
ALTER TABLE vehiculo DISABLE TRIGGER trg_audit_vehiculo;
ALTER TABLE cliente  DISABLE TRIGGER trg_audit_cliente;
ALTER TABLE factura  DISABLE TRIGGER trg_audit_factura;
ALTER TABLE mantenimiento     DISABLE TRIGGER trg_audit_mantenimiento;
ALTER TABLE imagen_vehiculo   DISABLE TRIGGER trg_imagen_vehiculo_max;

-- =============================================================================
-- FASE 1: completar la matriz de tarifas (5 sucursales x 5 tipos = 25 combos).
--   Solo 10 existen del seed 12. Insertamos los 25 con ON CONFLICT DO NOTHING:
--   los 10 ya cargados quedan intactos, se agregan los 15 faltantes.
--   Precios realistas ARS 2026; recargo expresado como fraccion (0.08..0.15).
-- =============================================================================
DO $$
DECLARE
    s   INTEGER;
    t   INTEGER;
    v_precio  NUMERIC(12,2);
    v_recargo NUMERIC(5,2);
BEGIN
    FOR s IN 1..5 LOOP
        FOR t IN 1..5 LOOP
            -- Precio base por tipo con pequena variacion por sucursal (+/- ~5%).
            v_precio := CASE t
                WHEN 1 THEN 22000 + (random()*3000)   -- Compacto   22-25k
                WHEN 2 THEN 28000 + (random()*4000)   -- Sedan      28-32k
                WHEN 3 THEN 40000 + (random()*8000)   -- SUV        40-48k
                WHEN 4 THEN 45000 + (random()*10000)  -- Pickup     45-55k
                ELSE        23000 + (random()*3000)   -- Utilitario 23-26k
            END;
            v_precio := ROUND(v_precio, 2);
            -- Recargo entre 0.08 y 0.15.
            v_recargo := ROUND((0.08 + random()*0.07)::numeric, 2);

            INSERT INTO tarifa (id_sucursal, id_tipo, precio_por_dia, porcentaje_recargo)
            VALUES (s, t, v_precio, v_recargo)
            ON CONFLICT (id_sucursal, id_tipo) DO NOTHING;
        END LOOP;
    END LOOP;
END $$;

-- =============================================================================
-- FASE 2: clientes nuevos (~80). Algunos online (usuario+email), otros
--   presenciales (id_usuario NULL). DNI en rango 20.000.000-45.000.000 con
--   unicidad garantizada (offset por indice del loop).
-- =============================================================================
DO $$
DECLARE
    nombres   TEXT[] := ARRAY[
        'Juan','Maria','Carlos','Ana','Luis','Sofia','Diego','Lucia','Martin','Laura',
        'Pablo','Carla','Jorge','Florencia','Ricardo','Valentina','Hernan','Camila',
        'Gabriel','Julieta','Federico','Agustina','Sebastian','Micaela','Nicolas',
        'Romina','Matias','Daniela','Emiliano','Brenda','Tomas','Rocio','Facundo','Belen'];
    apellidos TEXT[] := ARRAY[
        'Perez','Gomez','Martinez','Rodriguez','Sanchez','Fernandez','Lopez','Diaz',
        'Acosta','Romero','Sosa','Benitez','Gimenez','Silva','Cabrera','Ramirez',
        'Vera','Ojeda','Aguirre','Cardozo','Insaurralde','Britez','Coronel','Escobar',
        'Maidana','Villalba','Zaracho','Encina','Fleitas','Duarte','Riveros','Ferreyra'];
    ciudades  TEXT[] := ARRAY[
        'Posadas','Obera','Puerto Iguazu','Corrientes','Resistencia','Eldorado',
        'Apostoles','Goya','Saenz Pena','Garupa'];
    calles    TEXT[] := ARRAY[
        'Av. Mitre','Bolivar','San Martin','Cordoba','Sarmiento','Belgrano',
        'Rivadavia','Junin','Tucuman','La Rioja','Av. Uruguay','Entre Rios'];

    n_clientes CONSTANT INTEGER := 80;
    i          INTEGER;
    v_nombre   TEXT;
    v_apellido TEXT;
    v_dni      TEXT;
    v_tel      TEXT;
    v_dir      TEXT;
    v_user_id  BIGINT;
    v_online   BOOLEAN;
BEGIN
    FOR i IN 1..n_clientes LOOP
        v_nombre   := nombres[1 + floor(random()*array_length(nombres,1))::int];
        v_apellido := apellidos[1 + floor(random()*array_length(apellidos,1))::int];
        -- DNI unico: 20.000.000 + i*317 + jitter pequeno acotado para no colisionar.
        v_dni := (20000000 + i*317 + floor(random()*100)::int + i)::TEXT;
        -- Telefono NEA: prefijos 0376 (Posadas), 0379 (Corrientes), 0362 (Chaco).
        v_tel := (ARRAY['0376','0379','0362','03755','03758'])[1+floor(random()*5)::int]
                 || '-15-' || lpad(floor(random()*900000+100000)::TEXT, 6, '0');
        v_dir := calles[1+floor(random()*array_length(calles,1))::int] || ' '
                 || floor(random()*3500+100)::TEXT || ', '
                 || ciudades[1+floor(random()*array_length(ciudades,1))::int];

        -- ~55% online (con usuario), ~45% presencial (id_usuario NULL).
        v_online := random() < 0.55;
        v_user_id := NULL;

        IF v_online THEN
            INSERT INTO usuario (username, email)
            VALUES (
                lower(v_nombre) || '.' || lower(v_apellido) || i,
                lower(v_nombre) || '.' || lower(v_apellido) || i || '@demo.local'
            )
            RETURNING id_usuario INTO v_user_id;
        END IF;

        INSERT INTO cliente (id_usuario, nombre, apellido, dni, telefono, direccion)
        VALUES (v_user_id, v_nombre, v_apellido, v_dni, v_tel, v_dir);
    END LOOP;
END $$;

-- =============================================================================
-- FASE 3: vehiculos nuevos (~50, id > 10). Distribuidos en 5 sucursales y
--   5 tipos. Marca/modelo coherentes con el tipo. Por cada vehiculo:
--     - 5 imagen_vehiculo (orden 1..5)
--     - 1 ubicacion_vehiculo vigente (fecha_hasta NULL) en su sucursal origen
--     - 1 historial_estado_vehiculo inicial 'disponible' vigente
--   Estado inicial 'disponible'; en fases posteriores algunos pasan a
--   'alquilado' (ventana activa) o 'en_mantenimiento'.
-- =============================================================================
DO $$
DECLARE
    -- modelos[tipo] = lista "Marca Modelo" coherente con el tipo.
    modelos_compacto  TEXT[] := ARRAY['Volkswagen Gol','Volkswagen Polo','Chevrolet Onix','Fiat Argo','Toyota Etios','Renault Sandero'];
    modelos_sedan     TEXT[] := ARRAY['Toyota Corolla','Fiat Cronos','Volkswagen Virtus','Nissan Sentra','Chevrolet Onix Plus','Peugeot 408'];
    modelos_suv       TEXT[] := ARRAY['Volkswagen T-Cross','Jeep Renegade','Chevrolet Tracker','Toyota Corolla Cross','Ford Territory','Nissan Kicks'];
    modelos_pickup    TEXT[] := ARRAY['Toyota Hilux','Ford Ranger','Volkswagen Amarok','Chevrolet S10','Nissan Frontier','Renault Alaskan'];
    modelos_utilit    TEXT[] := ARRAY['Renault Kangoo','Peugeot Partner','Citroen Berlingo','Fiat Ducato','Mercedes-Benz Vito','Renault Master'];

    n_veh    CONSTANT INTEGER := 50;
    i        INTEGER;
    v_tipo   INTEGER;
    v_suc    INTEGER;
    v_marca_modelo TEXT;
    v_marca  TEXT;
    v_modelo TEXT;
    v_anio   INTEGER;
    v_patente TEXT;
    v_km     INTEGER;
    v_estado INTEGER;
    v_id_veh BIGINT;
    j        INTEGER;
    v_letras TEXT := 'ABCDEFGHJKLMNPRSTUVWXYZ';
BEGIN
    FOR i IN 1..n_veh LOOP
        v_tipo := 1 + (i % 5);                 -- reparte parejo 1..5
        v_suc  := 1 + (i % 5);                 -- reparte parejo entre sucursales
        -- rota la sucursal respecto al tipo para diversificar combinaciones
        v_suc  := 1 + ((i + v_tipo) % 5);

        v_marca_modelo := CASE v_tipo
            WHEN 1 THEN modelos_compacto[1+floor(random()*array_length(modelos_compacto,1))::int]
            WHEN 2 THEN modelos_sedan[1+floor(random()*array_length(modelos_sedan,1))::int]
            WHEN 3 THEN modelos_suv[1+floor(random()*array_length(modelos_suv,1))::int]
            WHEN 4 THEN modelos_pickup[1+floor(random()*array_length(modelos_pickup,1))::int]
            ELSE        modelos_utilit[1+floor(random()*array_length(modelos_utilit,1))::int]
        END;
        v_marca  := split_part(v_marca_modelo, ' ', 1);
        v_modelo := trim(substr(v_marca_modelo, length(v_marca)+2));

        v_anio := 2019 + floor(random()*8)::int;   -- 2019..2026
        IF v_anio > 2026 THEN v_anio := 2026; END IF;

        -- Patente unica. Formato Mercosur AB123CD; el indice i va embebido
        -- en las cifras para garantizar unicidad sin colisiones.
        v_patente :=
            substr(v_letras, 1+floor(random()*length(v_letras))::int, 1) ||
            substr(v_letras, 1+floor(random()*length(v_letras))::int, 1) ||
            lpad(((i*7) % 1000)::TEXT, 3, '0') ||
            substr(v_letras, 1+((i)   % length(v_letras)), 1) ||
            substr(v_letras, 1+((i*3) % length(v_letras)), 1);

        -- km coherente con antiguedad: ~15.000 km/anio +/- ruido.
        v_km := GREATEST(500, (2026 - v_anio) * 15000 + floor(random()*12000)::int);

        -- Mayoria 'disponible'(1). Algunos 'en_mantenimiento'(3). 'alquilado'(2)
        -- se setea luego en la fase de transacciones para los que tengan
        -- ventana activa. Aca dejamos ~8% en mantenimiento de entrada.
        v_estado := CASE WHEN random() < 0.08 THEN 3 ELSE 1 END;

        INSERT INTO vehiculo (id_sucursal_origen, id_tipo, id_estado, marca, modelo, anio, patente, km_actuales, detalle_confort)
        VALUES (
            v_suc, v_tipo, v_estado, v_marca, v_modelo, v_anio, v_patente, v_km,
            (ARRAY[
                'Aire acondicionado, direccion asistida, ABS',
                'Climatizador, tapizado de cuero, sensor de estacionamiento',
                'Pantalla tactil, camara de retroceso, control crucero',
                'Bluetooth, llantas de aleacion, faros LED',
                'Caja automatica, asientos calefaccionados, techo panoramico'
            ])[1+floor(random()*5)::int]
        )
        RETURNING id_vehiculo INTO v_id_veh;

        -- 5 imagenes (orden 1..5).
        FOR j IN 1..5 LOOP
            INSERT INTO imagen_vehiculo (id_vehiculo, url_imagen, orden)
            VALUES (v_id_veh, 'https://cdn.demo.local/veh/' || v_id_veh || '/' || j || '.jpg', j);
        END LOOP;

        -- Ubicacion vigente en la sucursal de origen.
        INSERT INTO ubicacion_vehiculo (id_vehiculo, id_sucursal, fecha_desde, fecha_hasta)
        VALUES (v_id_veh, v_suc, '2025-01-01 08:00:00', NULL);

        -- Historial de estado inicial vigente (coherente con el estado seteado).
        INSERT INTO historial_estado_vehiculo (id_vehiculo, id_estado, fecha_inicio, fecha_fin, motivo)
        VALUES (
            v_id_veh, v_estado, '2025-01-01 08:00:00', NULL,
            CASE WHEN v_estado = 3 THEN 'Ingreso a flota - en taller' ELSE 'Alta en flota' END
        );
    END LOOP;
END $$;

-- =============================================================================
-- FASE 4: transacciones historicas (el grueso del volumen).
--   Para cada vehiculo nuevo se avanza un CURSOR de fecha desde un arranque
--   aleatorio en 2025, generando ventanas de alquiler secuenciales sin
--   solaparse. Cada ventana cerrada (< NOW()) produce:
--     ~70% reserva 'concretada' previa + alquiler cerrado + factura
--     ~30% walk-in (alquiler.id_reserva NULL) + factura
--   ~20% de los cierres devuelven tarde -> horas_excedidas / recargo.
--   Ademas, ~30% de los vehiculos reciben UNA ventana ACTIVA reciente
--   (alquiler activo, sin factura) -> el vehiculo queda 'alquilado'.
-- =============================================================================
DO $$
DECLARE
    rec_veh  RECORD;
    v_cursor TIMESTAMP;
    v_fin    TIMESTAMP;
    v_dur    INTEGER;
    v_gap    INTEGER;
    v_km     INTEGER;
    v_km_fin INTEGER;
    v_id_tarifa   BIGINT;
    v_precio      NUMERIC(12,2);
    v_recargo_pct NUMERIC(5,2);
    v_id_cliente  BIGINT;
    v_id_tipo_res BIGINT;
    v_id_reserva  BIGINT;
    v_id_alquiler BIGINT;
    v_con_reserva BOOLEAN;
    v_tarde       BOOLEAN;
    v_dev_real    TIMESTAMP;
    v_suc_dev     BIGINT;
    v_horas_exc   NUMERIC(6,2);
    v_costo_base  NUMERIC(12,2);
    v_recargo_exc NUMERIC(12,2);
    v_total       NUMERIC(12,2);
    v_dias        INTEGER;
    v_numero      VARCHAR(30);
    v_n_clientes  BIGINT;
    v_min_cli     BIGINT := 8;        -- clientes nuevos: id >= 8
    v_max_cli     BIGINT;
    v_now         TIMESTAMP := date_trunc('day', NOW());
    v_dio_activa  BOOLEAN;
    v_estado_alq  INTEGER := 2;       -- 'alquilado'
BEGIN
    SELECT MAX(id_cliente) INTO v_max_cli FROM cliente;

    -- Recorrer solo vehiculos nuevos (id > 10) que no esten en mantenimiento.
    FOR rec_veh IN
        SELECT v.id_vehiculo, v.id_sucursal_origen, v.id_tipo, v.km_actuales, v.id_estado
        FROM vehiculo v
        WHERE v.id_vehiculo > 10
        ORDER BY v.id_vehiculo
    LOOP
        -- Tarifa de la sucursal de origen + tipo (existe seguro tras FASE 1).
        SELECT id_tarifa, precio_por_dia, porcentaje_recargo
          INTO v_id_tarifa, v_precio, v_recargo_pct
          FROM tarifa
         WHERE id_sucursal = rec_veh.id_sucursal_origen
           AND id_tipo     = rec_veh.id_tipo;

        -- km de partida: bastante por debajo del km_actuales para que la
        -- secuencia de alquileres lo vaya incrementando hasta ~km_actuales.
        v_km := GREATEST(500, rec_veh.km_actuales - 30000 - floor(random()*10000)::int);

        -- Cursor inicial: dia aleatorio del primer trimestre 2025.
        v_cursor := TIMESTAMP '2025-01-05 09:00:00' + (floor(random()*80)::int || ' days')::interval;

        v_dio_activa := FALSE;

        -- Avanzar el cursor mientras quepan ventanas CERRADAS antes de hoy.
        LOOP
            v_dur := 2 + floor(random()*11)::int;          -- 2..12 dias
            v_fin := v_cursor + (v_dur || ' days')::interval;

            EXIT WHEN v_fin >= v_now - INTERVAL '10 days';  -- dejar margen para la ventana activa

            -- Cliente al azar entre los nuevos.
            v_id_cliente := v_min_cli + floor(random()*(v_max_cli - v_min_cli + 1))::int;

            -- km de la ventana.
            v_km_fin := v_km + 150 + floor(random()*1500)::int;

            -- ~70% con reserva concretada previa.
            v_con_reserva := random() < 0.70;
            v_id_reserva  := NULL;

            IF v_con_reserva THEN
                v_id_tipo_res := 1 + floor(random()*3)::int;   -- 1..3
                INSERT INTO reserva (id_cliente, id_vehiculo, id_tipo_reserva, fecha_inicio, fecha_fin_prevista, estado, fecha_creacion)
                VALUES (
                    v_id_cliente, rec_veh.id_vehiculo, v_id_tipo_res,
                    v_cursor, v_fin, 'concretada',
                    v_cursor - ((1 + floor(random()*10)::int) || ' days')::interval
                )
                RETURNING id_reserva INTO v_id_reserva;

                -- Garantia si el tipo de reserva la requiere (tipo 1 = estandar).
                IF v_id_tipo_res = 1 THEN
                    INSERT INTO garantia_reserva (id_reserva, tipo, titular, numero_tarjeta_hash, vencimiento, fecha_registro, activa)
                    SELECT
                        v_id_reserva,
                        (ARRAY['Visa','Mastercard','Amex'])[1+floor(random()*3)::int],
                        c.nombre || ' ' || c.apellido,
                        md5(random()::text),
                        (v_fin + INTERVAL '2 years')::date,
                        v_cursor - INTERVAL '1 day',
                        TRUE
                    FROM cliente c WHERE c.id_cliente = v_id_cliente;
                END IF;
            END IF;

            -- ~20% devuelve tarde (horas excedidas).
            v_tarde := random() < 0.20;
            IF v_tarde THEN
                v_dev_real := v_fin + ((1 + floor(random()*24)::int) || ' hours')::interval;
            ELSE
                -- devuelve en hora o un poco antes (no genera recargo).
                v_dev_real := v_fin - ((floor(random()*6)::int) || ' hours')::interval;
                IF v_dev_real <= v_cursor THEN
                    v_dev_real := v_fin;
                END IF;
            END IF;

            -- Sucursal de devolucion: ~80% la de origen, ~20% otra.
            IF random() < 0.80 THEN
                v_suc_dev := rec_veh.id_sucursal_origen;
            ELSE
                v_suc_dev := 1 + floor(random()*5)::int;
            END IF;

            -- Alquiler CERRADO directo (triggers de lifecycle deshabilitados).
            INSERT INTO alquiler (id_reserva, id_cliente, id_vehiculo, id_tarifa, id_sucursal_devolucion, fecha_inicio, fecha_fin_prevista, fecha_devolucion_real, km_inicio, km_fin, estado)
            VALUES (
                v_id_reserva, v_id_cliente, rec_veh.id_vehiculo, v_id_tarifa, v_suc_dev,
                v_cursor, v_fin, v_dev_real, v_km, v_km_fin, 'cerrado'
            )
            RETURNING id_alquiler INTO v_id_alquiler;

            -- ----- Calculo de factura (replica fn_calcular_factura) -----
            v_dias := CEIL(EXTRACT(EPOCH FROM (v_fin - v_cursor)) / 86400);
            IF v_dias <= 0 THEN v_dias := 1; END IF;
            v_costo_base := v_dias * v_precio;

            v_horas_exc   := 0;
            v_recargo_exc := 0;
            IF v_dev_real > v_fin THEN
                v_horas_exc   := CEIL(EXTRACT(EPOCH FROM (v_dev_real - v_fin)) / 3600);
                v_recargo_exc := ROUND(v_horas_exc * (v_precio / 24.0) * v_recargo_pct, 2);
            END IF;
            v_total := v_costo_base + v_recargo_exc;

            v_numero := 'FAC-' || LPAD(NEXTVAL('seq_numero_factura')::TEXT, 6, '0');

            INSERT INTO factura (id_alquiler, id_cliente, numero_factura, fecha_emision,
                                 precio_por_dia_aplicado, porcentaje_recargo_aplicado,
                                 costo_base, horas_excedidas, recargo_excedente, total)
            VALUES (
                v_id_alquiler, v_id_cliente, v_numero, v_dev_real::date,
                v_precio, v_recargo_pct, v_costo_base, v_horas_exc, v_recargo_exc, v_total
            );

            -- Avanzar km y cursor (gap entre alquileres 1..20 dias).
            v_km  := v_km_fin;
            v_gap := 1 + floor(random()*20)::int;
            v_cursor := v_fin + (v_gap || ' days')::interval;
        END LOOP;

        -- --------- Ventana ACTIVA reciente (~30% de los vehiculos) ----------
        -- Solo si el vehiculo no esta en mantenimiento. Un alquiler activo,
        -- sin factura, que abarca NOW(). El EXCLUDE de activos se respeta:
        -- es la unica ventana activa de este vehiculo y no solapa con cerrados
        -- (los cerrados no participan del exclude de activos de todos modos).
        IF rec_veh.id_estado <> 3 AND random() < 0.30 THEN
            v_dur    := 3 + floor(random()*8)::int;                  -- 3..10 dias
            v_cursor := v_now - ((1 + floor(random()*3)::int) || ' days')::interval;  -- empezo hace 1..3 dias
            v_fin    := v_cursor + (v_dur || ' days')::interval;     -- termina en el futuro
            v_id_cliente := v_min_cli + floor(random()*(v_max_cli - v_min_cli + 1))::int;
            v_km_fin := v_km + 100;  -- placeholder, no se usa (km_fin NULL)

            v_con_reserva := random() < 0.50;
            v_id_reserva  := NULL;
            IF v_con_reserva THEN
                v_id_tipo_res := 1 + floor(random()*3)::int;
                INSERT INTO reserva (id_cliente, id_vehiculo, id_tipo_reserva, fecha_inicio, fecha_fin_prevista, estado, fecha_creacion)
                VALUES (v_id_cliente, rec_veh.id_vehiculo, v_id_tipo_res, v_cursor, v_fin, 'concretada', v_cursor - INTERVAL '2 days')
                RETURNING id_reserva INTO v_id_reserva;

                IF v_id_tipo_res = 1 THEN
                    INSERT INTO garantia_reserva (id_reserva, tipo, titular, numero_tarjeta_hash, vencimiento, fecha_registro, activa)
                    SELECT v_id_reserva, (ARRAY['Visa','Mastercard','Amex'])[1+floor(random()*3)::int],
                           c.nombre || ' ' || c.apellido, md5(random()::text),
                           (v_fin + INTERVAL '2 years')::date, v_cursor - INTERVAL '1 day', TRUE
                    FROM cliente c WHERE c.id_cliente = v_id_cliente;
                END IF;
            END IF;

            INSERT INTO alquiler (id_reserva, id_cliente, id_vehiculo, id_tarifa, id_sucursal_devolucion, fecha_inicio, fecha_fin_prevista, fecha_devolucion_real, km_inicio, km_fin, estado)
            VALUES (v_id_reserva, v_id_cliente, rec_veh.id_vehiculo, v_id_tarifa, NULL, v_cursor, v_fin, NULL, v_km, NULL, 'activo');

            -- El vehiculo queda 'alquilado': reflejar en vehiculo + historial.
            UPDATE historial_estado_vehiculo
               SET fecha_fin = v_cursor
             WHERE id_vehiculo = rec_veh.id_vehiculo AND fecha_fin IS NULL;
            INSERT INTO historial_estado_vehiculo (id_vehiculo, id_estado, fecha_inicio, fecha_fin, motivo)
            VALUES (rec_veh.id_vehiculo, v_estado_alq, v_cursor, NULL, 'Inicio de alquiler');
            UPDATE vehiculo SET id_estado = v_estado_alq WHERE id_vehiculo = rec_veh.id_vehiculo;
        END IF;
    END LOOP;
END $$;

-- =============================================================================
-- FASE 5: reservas futuras (pendientes) y canceladas adicionales (~130).
--   Pendientes: fecha_inicio > NOW(), sin alquiler. Respetan el EXCLUDE
--   (una sola pendiente por vehiculo en ventana futura, secuencial).
--   Canceladas: con motivo; NO participan del EXCLUDE -> libres de solapar.
-- =============================================================================
DO $$
DECLARE
    rec_veh  RECORD;
    v_inicio TIMESTAMP;
    v_fin    TIMESTAMP;
    v_cli    BIGINT;
    v_min_cli BIGINT := 8;
    v_max_cli BIGINT;
    v_tipo_res BIGINT;
    v_id_reserva BIGINT;
    v_now    TIMESTAMP := date_trunc('day', NOW());
    v_cursor TIMESTAMP;
    v_k      INTEGER;
    v_motivos TEXT[] := ARRAY[
        'Cliente cancelo por cambio de planes',
        'No se presento a retirar el vehiculo',
        'Pago rechazado',
        'Duplicado por error de carga',
        'Cliente encontro mejor tarifa'];
BEGIN
    SELECT MAX(id_cliente) INTO v_max_cli FROM cliente;

    FOR rec_veh IN
        SELECT id_vehiculo, id_estado FROM vehiculo WHERE id_vehiculo > 10 ORDER BY id_vehiculo
    LOOP
        -- ---- 1 o 2 reservas PENDIENTES futuras, secuenciales ----
        v_cursor := v_now + ((20 + floor(random()*40)::int) || ' days')::interval;
        FOR v_k IN 1..(1 + floor(random()*2)::int) LOOP
            v_inicio := v_cursor;
            v_fin    := v_inicio + ((2 + floor(random()*9)::int) || ' days')::interval;
            v_cli    := v_min_cli + floor(random()*(v_max_cli - v_min_cli + 1))::int;
            v_tipo_res := 1 + floor(random()*3)::int;

            INSERT INTO reserva (id_cliente, id_vehiculo, id_tipo_reserva, fecha_inicio, fecha_fin_prevista, estado, fecha_creacion)
            VALUES (v_cli, rec_veh.id_vehiculo, v_tipo_res, v_inicio, v_fin, 'pendiente', v_now - INTERVAL '1 day')
            RETURNING id_reserva INTO v_id_reserva;

            IF v_tipo_res = 1 THEN
                INSERT INTO garantia_reserva (id_reserva, tipo, titular, numero_tarjeta_hash, vencimiento, fecha_registro, activa)
                SELECT v_id_reserva, (ARRAY['Visa','Mastercard','Amex'])[1+floor(random()*3)::int],
                       c.nombre || ' ' || c.apellido, md5(random()::text),
                       (v_fin + INTERVAL '2 years')::date, v_now, TRUE
                FROM cliente c WHERE c.id_cliente = v_cli;
            END IF;

            -- avanzar cursor con gap para no solapar la siguiente pendiente
            v_cursor := v_fin + ((5 + floor(random()*15)::int) || ' days')::interval;
        END LOOP;

        -- ---- 1 reserva CANCELADA (puede solapar: no entra al EXCLUDE) ----
        v_inicio := v_now - ((30 + floor(random()*180)::int) || ' days')::interval;
        v_fin    := v_inicio + ((2 + floor(random()*7)::int) || ' days')::interval;
        v_cli    := v_min_cli + floor(random()*(v_max_cli - v_min_cli + 1))::int;
        v_tipo_res := 1 + floor(random()*3)::int;

        INSERT INTO reserva (id_cliente, id_vehiculo, id_tipo_reserva, fecha_inicio, fecha_fin_prevista, estado, fecha_creacion, motivo_cancelacion)
        VALUES (v_cli, rec_veh.id_vehiculo, v_tipo_res, v_inicio, v_fin, 'cancelada',
                v_inicio - INTERVAL '3 days',
                v_motivos[1+floor(random()*array_length(v_motivos,1))::int]);
    END LOOP;
END $$;

-- =============================================================================
-- FASE 6: mantenimientos (~40). Mezcla de cerrados (con fecha_devolucion) y
--   2-3 abiertos. Sobre vehiculos nuevos, repartidos en el tiempo y talleres.
--   NOTA: no se tocan estados de vehiculo aca para no chocar con ventanas
--   activas; el mantenimiento queda como registro historico/operativo.
-- =============================================================================
DO $$
DECLARE
    rec_veh RECORD;
    v_envio DATE;
    v_dev   DATE;
    v_taller INTEGER;
    v_abierto BOOLEAN;
    v_count INTEGER := 0;
    v_obs   TEXT[] := ARRAY[
        'Service de 10.000 km',
        'Cambio de pastillas de freno',
        'Reparacion de aire acondicionado',
        'Alineacion y balanceo',
        'Cambio de correa de distribucion',
        'Reparacion de chapa y pintura por siniestro menor',
        'Cambio de neumaticos',
        'Revision de tren delantero'];
    v_abiertos_meta CONSTANT INTEGER := 3;
    v_abiertos_creados INTEGER := 0;
BEGIN
    FOR rec_veh IN
        SELECT id_vehiculo FROM vehiculo WHERE id_vehiculo > 10 ORDER BY random() LIMIT 40
    LOOP
        v_count := v_count + 1;
        v_taller := 1 + floor(random()*3)::int;
        -- fecha de envio repartida en 2025..2026.
        v_envio := (DATE '2025-02-01' + (floor(random()*480)::int))::date;

        -- Los ultimos del recorrido quedan abiertos (hasta 3).
        v_abierto := (v_abiertos_creados < v_abiertos_meta) AND random() < 0.10;

        IF v_abierto THEN
            v_abiertos_creados := v_abiertos_creados + 1;
            INSERT INTO mantenimiento (id_vehiculo, id_taller, fecha_envio, fecha_devolucion, observaciones)
            VALUES (rec_veh.id_vehiculo, v_taller, v_envio, NULL,
                    v_obs[1+floor(random()*array_length(v_obs,1))::int] || ' (en proceso)');
        ELSE
            v_dev := v_envio + (1 + floor(random()*15)::int);
            INSERT INTO mantenimiento (id_vehiculo, id_taller, fecha_envio, fecha_devolucion, observaciones)
            VALUES (rec_veh.id_vehiculo, v_taller, v_envio, v_dev,
                    v_obs[1+floor(random()*array_length(v_obs,1))::int]);
        END IF;
    END LOOP;

    -- Garantizar al menos algunos abiertos si la probabilidad no los genero.
    IF v_abiertos_creados = 0 THEN
        FOR rec_veh IN
            SELECT id_vehiculo FROM vehiculo WHERE id_vehiculo > 10 ORDER BY random() LIMIT 2
        LOOP
            INSERT INTO mantenimiento (id_vehiculo, id_taller, fecha_envio, fecha_devolucion, observaciones)
            VALUES (rec_veh.id_vehiculo, 1+floor(random()*3)::int,
                    (DATE '2026-05-01' + floor(random()*40)::int)::date, NULL,
                    'Revision general (en proceso)');
        END LOOP;
    END IF;
END $$;

-- =============================================================================
-- FASE 7: rollup contable. Rellena resumen_mensual_sucursal por cada
--   (periodo, sucursal_origen del vehiculo) presente en factura. Idempotente
--   via ON CONFLICT (periodo, id_sucursal). Asi el reporte mensual muestra
--   volumen en TODOS los meses con facturacion, no solo el mes que cerro la
--   tarea programada del seed 18.
-- =============================================================================
INSERT INTO resumen_mensual_sucursal (
    periodo, id_sucursal, facturas_emitidas,
    total_costo_base, total_recargos, total_facturado,
    km_recorridos, fecha_cierre
)
SELECT
    DATE_TRUNC('month', f.fecha_emision)::DATE,
    v.id_sucursal_origen,
    COUNT(*),
    SUM(f.costo_base),
    SUM(f.recargo_excedente),
    SUM(f.total),
    SUM(COALESCE(a.km_fin, a.km_inicio) - a.km_inicio),
    NOW()
FROM factura f
JOIN alquiler a ON a.id_alquiler = f.id_alquiler
JOIN vehiculo v ON v.id_vehiculo = a.id_vehiculo
GROUP BY 1, 2
ON CONFLICT (periodo, id_sucursal) DO UPDATE SET
    facturas_emitidas = EXCLUDED.facturas_emitidas,
    total_costo_base  = EXCLUDED.total_costo_base,
    total_recargos    = EXCLUDED.total_recargos,
    total_facturado   = EXCLUDED.total_facturado,
    km_recorridos     = EXCLUDED.km_recorridos,
    fecha_cierre      = EXCLUDED.fecha_cierre;

-- =============================================================================
-- FASE 8: rehabilitar todos los triggers de negocio deshabilitados en FASE 0.
-- =============================================================================
ALTER TABLE alquiler ENABLE TRIGGER trg_alquiler_start;
ALTER TABLE alquiler ENABLE TRIGGER trg_alquiler_close;
ALTER TABLE alquiler ENABLE TRIGGER trg_alquiler_set_cerrado;
ALTER TABLE alquiler ENABLE TRIGGER trg_alquiler_no_overlap;
ALTER TABLE alquiler ENABLE TRIGGER trg_audit_alquiler;
ALTER TABLE reserva  ENABLE TRIGGER trg_reserva_no_overlap;
ALTER TABLE reserva  ENABLE TRIGGER trg_audit_reserva;
ALTER TABLE mantenimiento ENABLE TRIGGER trg_mantenimiento_envio;
ALTER TABLE mantenimiento ENABLE TRIGGER trg_mantenimiento_devolucion;
ALTER TABLE vehiculo ENABLE TRIGGER trg_audit_vehiculo;
ALTER TABLE cliente  ENABLE TRIGGER trg_audit_cliente;
ALTER TABLE factura  ENABLE TRIGGER trg_audit_factura;
ALTER TABLE mantenimiento     ENABLE TRIGGER trg_audit_mantenimiento;
ALTER TABLE imagen_vehiculo   ENABLE TRIGGER trg_imagen_vehiculo_max;

-- Fin de 30_demo_bulk.sql
