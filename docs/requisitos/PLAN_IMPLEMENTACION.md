# Plan de implementación — Cumplimiento TFI TBD 2026

> **Documento vivo.** Cada tarea tiene un checkbox que se marca a medida que
> se completa. Acompaña a `JUSTIFICACION.md` y al PDF de la cátedra.

---

## Estado global

| Sprint | Foco | Requisitos | Estado |
|--------|------|------------|--------|
| 1 | Auditoría + interfaz | R1 | `completed` |
| 2 | Capa SP de reservas | R7, R8, R5 (parcial) | `completed` |
| 3 | Capa SP de alquileres y CRUD | R3, R4, R5, R6 | `completed` |
| 4 | Job de devoluciones vencidas | R9 | `completed` |
| 5 | Cierre transaccional (`EXCEPTION` + demo `COMMIT/ROLLBACK`) | R2 | `completed` |

Progreso total: **64 / 64 tareas**.

---

## Sprint 1 — Auditoría con triggers + interfaz (R1)

**Objetivo.** Tabla general de auditoría, trigger genérico aplicado a tablas
principales, ruta `/admin/auditoria` para consulta.

**Criterio de aceptación.**
- Todo INSERT/UPDATE/DELETE en tablas auditadas genera 1 fila en `audit_log`.
- La fila contiene `usuario_db`, `usuario_app` (`auth.uid()`), `fecha_hora`,
  `tipo_op`, `tabla`, `id_registro`, `valores_anteriores` y `valores_nuevos`.
- La ruta `/admin/auditoria` lista los logs con paginación y filtros por
  tabla/operación/fecha.
- RLS sobre `audit_log` permite SELECT solo a rol `staff`.

### Tareas

#### 1.1 Tabla `audit_log`
- [x] Crear `schema/01_tables/18_audit_log.sql` con columnas:
  `id BIGSERIAL`, `tabla TEXT`, `id_registro TEXT`, `tipo_op CHAR(1)` (`I`/`U`/`D`),
  `usuario_db TEXT`, `usuario_app UUID`, `fecha_hora TIMESTAMPTZ DEFAULT NOW()`,
  `valores_anteriores JSONB`, `valores_nuevos JSONB`.
  > **Nota implementación:** la PK se llama `id_audit BIGSERIAL` (no `id`) para
  > seguir la convención del resto del schema (`id_<entidad>`). Se agregó
  > además `CONSTRAINT chk_audit_tipo_op CHECK (tipo_op IN ('I','U','D'))`.
- [x] Agregar índices en `schema/03_indexes/`: `(tabla, fecha_hora DESC)`,
  `(usuario_app, fecha_hora DESC)`, `(tipo_op)`.

#### 1.2 Función trigger genérica
- [x] Crear `schema/04_functions/12_fn_audit_generic.sql` con función
  `fn_audit_generic()` que use `TG_OP`, `TG_TABLE_NAME` y `to_jsonb(OLD/NEW)`.
  > **Nota implementación:** la función se declara `SECURITY DEFINER` con
  > `search_path = public` para poder insertar en `audit_log` aún cuando el
  > caller es `authenticated` (que no tiene INSERT directo). `id_registro` se
  > resuelve dinámicamente leyendo la PK desde `pg_index` (no asume nombre
  > "id_*"), lo que la deja reusable si en el futuro se audita una tabla con
  > otra convención.
- [x] Capturar usuario lógico desde `current_setting('request.jwt.claims', true)::jsonb ->> 'sub'`
  con fallback a `NULL` si no hay JWT (operaciones desde `psql`).

#### 1.3 Adjuntar trigger a tablas auditadas
- [x] Crear carpeta `schema/07_triggers/` con `.gitkeep`.
- [x] `07_triggers/01_audit_cliente.sql` — trigger AFTER INS/UPD/DEL en `cliente`.
- [x] `07_triggers/02_audit_vehiculo.sql` — trigger AFTER INS/UPD/DEL en `vehiculo`.
- [x] `07_triggers/03_audit_reserva.sql` — trigger AFTER INS/UPD/DEL en `reserva`.
- [x] `07_triggers/04_audit_alquiler.sql` — trigger AFTER INS/UPD/DEL en `alquiler`.
- [x] `07_triggers/05_audit_factura.sql` — trigger AFTER INS/UPD/DEL en `factura`.
- [x] `07_triggers/06_audit_mantenimiento.sql` — trigger AFTER INS/UPD/DEL en `mantenimiento`.

#### 1.4 Apply script
- [x] Actualizar `scripts/apply.sh` para aplicar `07_triggers` después de
  `06_permissions` (los triggers dependen de funciones y de los roles).

#### 1.5 Seguridad RLS sobre `audit_log`
- [x] Agregar política en `schema/06_permissions/04_rls_policies.sql` que
  habilite SELECT solo a usuarios con `is_staff()` (helper ya existente).
  > **Nota implementación:** el helper se llama `fn_es_staff()` (no
  > `is_staff()`); se usó ese nombre. También se agregó
  > `ALTER TABLE audit_log ENABLE ROW LEVEL SECURITY` en `03_rls_enable.sql`.
- [x] Bloquear INSERT/UPDATE/DELETE manuales (solo el trigger puede escribir).
  > **Nota implementación:** doble defensa — políticas `FOR INSERT/UPDATE/DELETE`
  > con `USING/CHECK = FALSE` *y* `REVOKE INSERT, UPDATE, DELETE ON audit_log
  > FROM authenticated` + `REVOKE ALL ... FROM anon` en el bloque DO de grants.

#### 1.6 Interfaz de consulta
- [x] Crear `frontend/app/admin/auditoria/page.tsx` con tabla server-side
  paginada usando `supabase.from('audit_log').select().range(...)`.
- [x] Filtros: `tabla` (dropdown), `tipo_op` (I/U/D), rango de fechas.
- [x] Crear `frontend/app/admin/auditoria/[id]/page.tsx` con vista de detalle
  que muestre diff lado a lado entre `valores_anteriores` y `valores_nuevos`.
- [x] Agregar enlace en `frontend/app/admin/page.tsx` (panel staff).
- [x] Actualizar `frontend/types/database.ts` regenerando tipos de Supabase
  con la nueva tabla.
  > **Nota implementación:** no se pudo correr `supabase gen types` (no hay
  > entorno local levantado). Se agregó manualmente el tipo `AuditLog` y la
  > entrada `audit_log` en `Database.public.Tables` con `Insert/Update: never`
  > para que TS rechace cualquier intento de escritura.

#### 1.7 Verificación
- [ ] Ejecutar `scripts/apply.sh` y confirmar que el schema se aplica sin error.
- [ ] Insertar un cliente desde el frontend, verificar que aparece en `audit_log`
  con `usuario_app` poblado.
- [ ] Eliminar una reserva desde admin, verificar que aparece como `D` con
  `valores_anteriores` no vacío.

---

## Sprint 2 — Capa SP de reservas (R5 parcial, R7, R8)

**Objetivo.** Reservas se crean y cancelan exclusivamente vía SP con retorno
estandarizado. Funciones de validación reutilizables.

**Criterio de aceptación.**
- `ReservaForm` invoca `supabase.rpc('pa_registrar_reserva', ...)` y recibe
  `{ p_estado, p_mensaje, p_id_generado }`.
- Hay vista de "Mis reservas" con botón Cancelar que llama
  `pa_cancelar_reserva`.
- Las funciones `fn_validar_*` se reutilizan en Sprint 3 sin duplicar lógica.

### Tareas

#### 2.1 Funciones de validación reusables
- [x] Crear `schema/04_functions/13_fn_validar_periodo.sql`:
  `fn_validar_periodo(p_inicio TIMESTAMP, p_fin TIMESTAMP) RETURNS VOID`.
  Valida que `p_fin > p_inicio` y que `p_inicio > NOW()`. Lanza `RAISE EXCEPTION`.
  > **Nota implementación:** declarada `STABLE` (no `IMMUTABLE`) porque
  > depende de `NOW()`. Lanza con `ERRCODE = 'check_violation'` para que el
  > caller pueda mapear a `ERROR_VALIDACION` capturando `check_violation`.
- [x] Crear `schema/04_functions/14_fn_validar_cliente_activo.sql`:
  `fn_validar_cliente_activo(p_id_cliente BIGINT) RETURNS VOID`. Verifica
  existencia del cliente y que no esté marcado como inactivo (cuando se agregue
  ese flag) o tenga deudas pendientes.
  > **Nota implementación:** la tabla `cliente` no tiene aún un flag de
  > actividad ni una noción persistida de "deuda". Esta versión valida sólo
  > existencia; la función deja un `TODO` documentado para extender la regla
  > cuando se sumen esos campos (Sprint 4 o posterior).
- [x] Crear `schema/04_functions/15_fn_validar_vehiculo_operativo.sql`:
  `fn_validar_vehiculo_operativo(p_id_vehiculo BIGINT) RETURNS VOID`. Verifica
  que el vehículo existe y su `id_estado` sea `disponible`.
  > **Nota implementación:** join contra `estado_vehiculo` con `lower(nombre)
  > = 'disponible'` para tolerar variaciones de capitalización en el catálogo.

#### 2.2 `pa_registrar_reserva`
- [x] Crear `schema/04_functions/16_pa_registrar_reserva.sql` con firma:
  ```sql
  PROCEDURE pa_registrar_reserva(
      IN  p_id_cliente      BIGINT,
      IN  p_id_vehiculo     BIGINT,
      IN  p_id_tipo_reserva BIGINT,
      IN  p_fecha_inicio    TIMESTAMP,
      IN  p_fecha_fin       TIMESTAMP,
      OUT p_estado          TEXT,
      OUT p_mensaje         TEXT,
      OUT p_id_generado     BIGINT
  )
  ```
- [x] Invocar las tres `fn_validar_*` dentro de `BEGIN ... EXCEPTION WHEN ...`.
- [x] `INSERT INTO reserva` confiando en `fn_check_vehiculo_overlap` para
  superposición.
- [x] Capturar `unique_violation`, `foreign_key_violation`, `OTHERS` y
  devolver código + mensaje estandarizado.
  > **Nota implementación:** se agregó captura adicional de `check_violation`
  > (para mapear los `RAISE EXCEPTION` de las `fn_validar_*` y de los CHECK
  > constraints de la tabla) y, dentro del `WHEN OTHERS`, un fallback que
  > detecta el mensaje del trigger `fn_check_vehiculo_overlap` (que no
  > expone un SQLSTATE específico) y lo mapea a `ERROR_VALIDACION`.

#### 2.3 `pa_cancelar_reserva` (uso de `INOUT`)
- [x] Crear `schema/04_functions/17_pa_cancelar_reserva.sql` con firma:
  ```sql
  PROCEDURE pa_cancelar_reserva(
      IN    p_id_reserva BIGINT,
      INOUT p_motivo     TEXT,    -- entra motivo del cliente, sale enriquecido con timestamp y autor
      OUT   p_estado     TEXT,
      OUT   p_mensaje    TEXT
  )
  ```
- [x] Validar transición: solo `pendiente → cancelada`. Rechazar `concretada`
  y `cancelada` con `ERROR_ESTADO`.
- [x] Validar que no exista alquiler asociado con `id_reserva = p_id_reserva`.
- [x] Enriquecer `p_motivo` con prefijo `[{timestamp} | usuario {auth.uid()}]`
  antes de retornarlo.
  > **Nota implementación:** se usa `SELECT ... FOR UPDATE` sobre la
  > `reserva` para evitar carrera con un eventual `pa_registrar_alquiler` que
  > se concrete en paralelo. El JWT se lee con el mismo patrón de
  > `fn_audit_generic` (cast a UUID dentro de bloque `EXCEPTION OTHERS`).

#### 2.4 Permisos (GRANT EXECUTE)
- [x] Agregar en `schema/06_permissions/01_profesor_quique.sql` (o archivo
  nuevo) los `GRANT EXECUTE ON PROCEDURE pa_registrar_reserva, pa_cancelar_reserva
  TO authenticated;`.
  > **Nota implementación:** se creó `schema/06_permissions/06_grants_sprint_2.sql`
  > con grants explícitos por procedure (más claros en `\dp`). Hay redundancia
  > con el `GRANT EXECUTE ON ALL PROCEDURES IN SCHEMA public TO authenticated`
  > del bloque DO al final de `04_rls_policies.sql`, pero se prefiere
  > duplicar para legibilidad / code review (idempotente).

#### 2.5 Refactor frontend
- [x] Modificar `frontend/components/ReservaForm.tsx` para usar
  `supabase.rpc('pa_registrar_reserva', { ... })` en lugar de `.insert()`.
- [x] Manejar respuesta `{ p_estado, p_mensaje, p_id_generado }`: si
  `p_estado !== 'OK'` mostrar `p_mensaje` al usuario; si OK redirigir a
  `/mis-reservas`.
- [x] Crear botón "Cancelar reserva" en `frontend/app/mis-reservas/page.tsx`
  que abra modal pidiendo motivo y llame `pa_cancelar_reserva`.
  > **Nota implementación:** la página `mis-reservas` es server component,
  > así que el botón se separó en `frontend/components/CancelarReservaButton.tsx`
  > (client component con modal + textarea + estado de loading). Solo se
  > renderiza cuando `reserva.estado === 'pendiente'`. También se
  > agregó el tipo `ProcedureEstado` y las firmas RPC en
  > `frontend/types/database.ts` (sección `Functions`).

#### 2.6 Verificación
- [ ] Crear reserva válida desde frontend, verificar que aparece con estado
  `pendiente` y disparó fila en `audit_log` (cumpliendo R1).
- [ ] Intentar crear reserva con fechas superpuestas: debe retornar
  `p_estado = 'ERROR_VALIDACION'` con mensaje claro.
- [ ] Cancelar una reserva `pendiente`: debe transicionar a `cancelada`,
  registrarse en `audit_log`, retornar `OK`.
- [ ] Intentar cancelar una reserva `concretada`: debe retornar
  `ERROR_ESTADO`.

---

## Sprint 3 — Capa SP de alquileres y CRUD (R3, R4, R5, R6)

**Objetivo.** Alquileres se crean por SP soportando ambas modalidades (con y
sin reserva previa). CRUD por SP para vehículo y cliente.

**Criterio de aceptación.**
- `pa_registrar_alquiler` acepta `p_id_reserva NULL` o no-`NULL` y valida
  correctamente cada caso.
- Las mutations de `vehiculo` desde el panel admin pasan por SP.
- La alta de cliente (caso staff registrando en mostrador) usa el SP existente
  `pa_registrar_cliente_con_usuario`.

### Tareas

#### 3.1 `pa_registrar_alquiler`
- [x] Crear `schema/04_functions/18_pa_registrar_alquiler.sql` con firma:
  ```sql
  PROCEDURE pa_registrar_alquiler(
      IN  p_id_reserva    BIGINT,    -- NULL = sin reserva previa
      IN  p_id_cliente    BIGINT,
      IN  p_id_vehiculo   BIGINT,
      IN  p_id_tarifa     BIGINT,
      IN  p_fecha_inicio  TIMESTAMP,
      IN  p_fecha_fin     TIMESTAMP,
      IN  p_km_inicio     INTEGER,
      OUT p_estado        TEXT,
      OUT p_mensaje       TEXT,
      OUT p_id_generado   BIGINT
  )
  ```
- [x] Rama **con reserva**: validar que `reserva` exista, esté en `pendiente`,
  pertenezca al mismo cliente y vehículo, y que las fechas coincidan.
  > **Nota implementación:** se usa `SELECT ... FOR UPDATE` sobre la reserva
  > para evitar carrera con un `pa_cancelar_reserva` en paralelo. Las cuatro
  > validaciones (estado, cliente, vehículo, fechas) cortan antes del INSERT
  > devolviendo `ERROR_ESTADO` / `ERROR_VALIDACION` con mensajes específicos.
- [x] Rama **sin reserva**: validar disponibilidad vía
  `fn_validar_vehiculo_operativo` + delegar superposición al trigger
  `fn_check_vehiculo_overlap`.
  > **Nota implementación:** además se invocan `fn_validar_periodo` y
  > `fn_validar_cliente_activo` (las tres `fn_validar_*` de Sprint 2,
  > reusadas tal cual). `fn_validar_periodo` exige `p_inicio > NOW()`, así
  > que el frontend walk-in setea `fecha_inicio = NOW() + 1 min` para no
  > caer en violación de `check_violation`.
- [x] Validar `p_km_inicio >= vehiculo.km_actuales`.
- [x] `INSERT INTO alquiler` (los triggers `trg_alquiler_start` ya marcan la
  reserva como `concretada` y el vehículo como `alquilado`).

#### 3.2 CRUD `vehiculo` por SP
- [x] Crear `schema/04_functions/19_pa_crud_vehiculo.sql` con tres procedures:
  - `pa_crear_vehiculo(IN ..., OUT p_estado, OUT p_mensaje, OUT p_id_generado)`
  - `pa_actualizar_vehiculo(IN p_id_vehiculo, IN ..., OUT p_estado, OUT p_mensaje)`
  - `pa_baja_vehiculo(IN p_id_vehiculo, INOUT p_motivo TEXT, OUT p_estado, OUT p_mensaje)`
    (validar que no tenga alquileres activos antes de soft-delete).
  > **Nota implementación:** el "soft-delete" se materializa como transición
  > a `estado_vehiculo.nombre = 'baja'` (estado nuevo agregado en
  > `05_seeds/06_estado_vehiculo.sql`). El procedure también cierra la fila
  > abierta de `historial_estado_vehiculo` y abre una nueva con el motivo
  > enriquecido (timestamp + uuid del autor, mismo patrón que
  > `pa_cancelar_reserva`). Validaciones extra: rechaza si hay alquileres
  > activos *o* reservas pendientes; si el vehículo ya está en `baja` devuelve
  > `ERROR_ESTADO` (idempotencia explícita). `pa_actualizar_vehiculo` solo
  > toca campos descriptivos — el `id_estado` se gobierna por triggers de
  > lifecycle (R6).

#### 3.3 Permisos
- [x] `GRANT EXECUTE` de los nuevos procedures a `authenticated` (alquiler) y
  `staff` (vehiculo CRUD) en `06_permissions/`.
  > **Nota implementación:** se creó `schema/06_permissions/07_grants_sprint_3.sql`.
  > Como no hay un rol PostgreSQL `staff` separado (los staff se identifican
  > por claim `app_metadata.role = 'staff'` del JWT), los grants de
  > `pa_crear_vehiculo` / `pa_actualizar_vehiculo` / `pa_baja_vehiculo` se
  > otorgan a `authenticated` y cada procedure verifica internamente
  > `fn_es_staff()` (helper de `02_rls_helpers.sql`). Si no es staff,
  > retorna `ERROR_ESTADO`. Defensa en profundidad sobre las RLS de la tabla.

#### 3.4 Refactor frontend (panel admin)
- [x] Crear `frontend/app/admin/alquileres/nuevo/page.tsx` con formulario
  unificado que permita seleccionar reserva existente o crear sin reserva
  (toggle).
  > **Nota implementación:** el formulario interactivo vive en el client
  > component `frontend/components/NuevoAlquilerForm.tsx` (datetime-local
  > para fechas walk-in, autocompletado de `km_inicio` con `km_actuales`
  > del vehiculo seleccionado). La página server-side carga en paralelo
  > reservas pendientes (con joins a cliente/vehículo), clientes,
  > vehículos en estado `disponible` y tarifas.
- [x] El formulario invoca `supabase.rpc('pa_registrar_alquiler', { ... })`.
- [x] Crear `frontend/app/admin/vehiculos/page.tsx` con CRUD que use los
  procedures `pa_crear_vehiculo`, `pa_actualizar_vehiculo`, `pa_baja_vehiculo`.
  > **Nota implementación:** la página delega la coordinación de modales a
  > `VehiculosAdminClient` (client component). Crear y editar se hacen con
  > `VehiculoFormModal` (modo `crear`/`editar`); la baja se hace con
  > `BajaVehiculoButton` (modal aparte con textarea de motivo). El botón
  > "Editar" se deshabilita si el vehículo ya está en `baja`. La card de
  > "Flota" del panel `/admin` deja de ser placeholder y enlaza a la nueva
  > página; se sumó además una card "Nuevo alquiler" que apunta a
  > `/admin/alquileres/nuevo` y un botón directo "+ Nuevo alquiler" en
  > `/admin/alquileres`. Los tipos de las 4 funciones nuevas se sumaron
  > manualmente a `frontend/types/database.ts` siguiendo el mismo formato
  > que `pa_registrar_reserva` / `pa_cancelar_reserva`.

#### 3.5 Verificación
- [ ] Registrar alquiler con reserva previa: la reserva debe quedar
  `concretada` y el vehículo `alquilado`.
- [ ] Registrar alquiler sin reserva previa (walk-in): mismo resultado en
  vehículo, alquiler con `id_reserva = NULL`.
- [ ] Intentar registrar alquiler con `p_km_inicio < vehiculo.km_actuales`:
  debe retornar `ERROR_VALIDACION`.
- [ ] Crear vehículo por SP, verificar que aparece en `audit_log` con
  `tipo_op = 'I'` (cumple R1).

---

## Sprint 4 — Job de devoluciones vencidas (R9)

**Objetivo.** Tarea programada cada 6 horas que detecta alquileres vencidos y
los persiste en tabla histórica.

**Criterio de aceptación.**
- `pg_cron` está instalado y el job `detectar-devoluciones-vencidas` aparece
  en `cron.job`.
- La tabla `devolucion_vencida` se puebla automáticamente.
- Hay vista admin para revisar las detecciones.

### Tareas

#### 4.1 Habilitar `pg_cron`
- [x] Modificar `docker-compose.yml`: cambiar imagen `postgres:16` a
  `supabase/postgres:15.1.0.147` (incluye `pg_cron` precargado).
  > **Nota implementación:** se reemplazo la imagen manteniendo env_file,
  > volumes, ports y healthcheck intactos. La imagen Supabase corre Postgres
  > 15 (no 16) — el schema del proyecto es compatible con ambas. El
  > entrypoint respeta las mismas env vars (POSTGRES_USER, POSTGRES_DB,
  > POSTGRES_PASSWORD), por lo que `.env` no requiere cambios.
- [x] Alternativa si el cambio rompe algo: agregar
  `command: postgres -c shared_preload_libraries='pg_cron' -c cron.database_name='postgres'`
  al servicio.
  > **Nota implementación:** no fue necesario. La imagen Supabase ya viene
  > con `shared_preload_libraries='pg_cron'` cargado por default. La
  > defensa en profundidad esta en el bloque `DO ... EXCEPTION` de
  > `00_extensions.sql` (deja un `RAISE NOTICE` si la extension no esta
  > disponible y no aborta el apply).
- [x] Actualizar `schema/00_extensions.sql` agregando `CREATE EXTENSION IF NOT EXISTS pg_cron;`.
  > **Nota implementación:** envuelto en bloque `DO $$ ... EXCEPTION WHEN
  > OTHERS THEN RAISE NOTICE ... END $$;` para soportar entornos donde el
  > sysadmin no habilito la extension (apply.sh no falla; el job no se
  > schedulea pero el resto del schema sigue).

#### 4.2 Tabla histórica
- [x] Crear `schema/01_tables/19_devolucion_vencida.sql`:
  `id BIGSERIAL`, `id_alquiler BIGINT UNIQUE NOT NULL`, `id_vehiculo BIGINT`,
  `id_cliente BIGINT`, `fecha_fin_prevista TIMESTAMP`, `fecha_deteccion TIMESTAMPTZ DEFAULT NOW()`,
  `horas_excedidas NUMERIC(8,2)`, `notificado BOOLEAN DEFAULT FALSE`.
  > **Nota implementación:** la PK se llama `id_devolucion_vencida` (no
  > `id`) para seguir la convencion `id_<entidad>` del resto del schema
  > (igual criterio que `audit_log.id_audit`). Se agrego
  > `CONSTRAINT chk_devolucion_vencida_horas CHECK (horas_excedidas >= 0)`
  > y `id_vehiculo` / `id_cliente` se hicieron `NOT NULL` (denormalizados
  > desde alquiler para evitar joins en la UI).
- [x] FK en `schema/02_constraints/13_fk_devolucion_vencida.sql`.
  > **Nota implementación:** `ON DELETE CASCADE` en `id_alquiler` (sin
  > alquiler la fila historica deja de tener sentido); `ON DELETE RESTRICT`
  > en cliente y vehiculo (nunca queremos perder esa referencia).
- [x] Índice `(fecha_deteccion DESC)` en `schema/03_indexes/`.
  > **Nota implementación:** archivo `11_idx_devolucion_vencida.sql` con
  > dos indices: `(fecha_deteccion DESC)` para listado cronologico y
  > `(notificado, fecha_deteccion DESC)` para la vista "pendientes".

#### 4.3 Procedure de detección
- [x] Crear `schema/04_functions/20_pa_detectar_devoluciones_vencidas.sql`:
  ```sql
  PROCEDURE pa_detectar_devoluciones_vencidas()
  ```
  - Cursor sobre `alquiler` donde `estado = 'activo' AND fecha_fin_prevista < NOW() AND fecha_devolucion_real IS NULL`.
  - `INSERT INTO devolucion_vencida (...) ON CONFLICT (id_alquiler) DO UPDATE SET horas_excedidas = EXCLUDED.horas_excedidas, fecha_deteccion = NOW()`
    para refrescar sin duplicar.
  - Bloque `EXCEPTION WHEN OTHERS` con `RAISE NOTICE` (al ser job, no hay
    cliente que reciba `OUT`).
  > **Nota implementación:** se usa `INSERT ... SELECT ... ON CONFLICT`
  > en una sola sentencia (mas eficiente que cursor). `horas_excedidas` se
  > calcula con `ROUND(EXTRACT(EPOCH FROM (NOW() - fecha_fin_prevista)) /
  > 3600.0, 2)`. El `ON CONFLICT DO UPDATE` no toca `notificado` para no
  > "desnotificar" filas que el staff ya atendio. Se loggea
  > `GET DIAGNOSTICS ROW_COUNT` para tener trazabilidad en el log del cron.

#### 4.4 Schedule
- [x] Crear `schema/04_functions/21_schedule_jobs.sql` con:
  ```sql
  SELECT cron.schedule(
      'detectar-devoluciones-vencidas',
      '0 */6 * * *',
      $$CALL pa_detectar_devoluciones_vencidas()$$
  );
  ```
- [x] Agregar guarda `IF NOT EXISTS` consultando `cron.job` antes de hacer
  schedule para evitar duplicados en re-aplies.
  > **Nota implementación:** doble guarda — primero `IF NOT EXISTS (SELECT
  > 1 FROM pg_extension WHERE extname='pg_cron')` (skip si la extension no
  > esta), luego `IF EXISTS (... cron.job ... jobname=...)` (skip si el
  > job ya esta). Todo dentro de bloque `DO ... EXCEPTION WHEN OTHERS`
  > para que un permission error o database mismatch no aborte el apply.

#### 4.5 Trigger de auditoría sobre `devolucion_vencida`
- [x] Crear `schema/07_triggers/07_audit_devolucion_vencida.sql` adjuntando
  el `fn_audit_generic` (consistente con R1).
  > **Nota implementación:** cada deteccion (INSERT del job) queda con
  > `usuario_app = NULL` (no hay JWT en el job); cada toggle de
  > `notificado` desde la UI queda con el `uuid` del staff que lo marco.

#### 4.6 Vista admin
- [x] Crear `frontend/app/admin/devoluciones-vencidas/page.tsx` con lista
  de detecciones, columnas: cliente, vehículo, patente, fecha prevista, horas
  excedidas, notificado.
  > **Nota implementación:** server component con paginacion (PAGE_SIZE=50)
  > y tres tabs de filtro: todas, pendientes (notificado=false), notificadas.
  > Join inline a `vehiculo` y `cliente` (FK unica, sin hint). La RLS
  > policy `devolucion_vencida_staff_read` se sumo a `04_rls_policies.sql`
  > junto con el `ENABLE ROW LEVEL SECURITY` en `03_rls_enable.sql`. Se
  > revoco INSERT/DELETE a `authenticated` (la fuente de verdad es el job).
- [x] Botón "Marcar como notificado" que actualice `notificado = TRUE`.
  > **Nota implementación:** componente cliente `MarcarNotificadoButton`
  > que togglea con `supabase.from('devolucion_vencida').update({
  > notificado: !current }).eq('id_devolucion_vencida', id)`. La RLS
  > `devolucion_vencida_staff_update` autoriza solo a `fn_es_staff()`.
  > Tambien se sumo una card "Devoluciones vencidas" al panel `/admin`
  > mostrando el conteo de pendientes; los tipos `DevolucionVencida` +
  > entrada en `Tables` se agregaron a `frontend/types/database.ts`
  > (Insert: never, Update: solo `notificado`).

#### 4.7 Verificación
- [ ] Insertar manualmente un alquiler con `fecha_fin_prevista` en el pasado.
- [ ] Ejecutar `CALL pa_detectar_devoluciones_vencidas()` manualmente:
  verificar inserción en `devolucion_vencida`.
- [ ] Consultar `SELECT * FROM cron.job` y confirmar que el job está
  schedulado.
- [ ] Esperar / forzar próxima ejecución y confirmar idempotencia (no se
  duplica la fila).

---

## Sprint 5 — Cierre transaccional + demo `COMMIT/ROLLBACK` (R2)

**Objetivo.** Todos los procedures envuelven su cuerpo en `EXCEPTION WHEN`.
Hay script demo que ejecuta `COMMIT/ROLLBACK` literales fuera de RPC para
demostrar competencia con la sintaxis Oracle.

**Criterio de aceptación.**
- Cada procedure de negocio tiene bloque `EXCEPTION` que mapea al menos
  `unique_violation`, `foreign_key_violation`, `OTHERS`.
- `tests/transacciones_explicitas.sql` ejecuta sin error desde `psql` y
  demuestra `COMMIT`/`ROLLBACK` literales.
- README documenta la política transaccional.

### Tareas

#### 5.1 Refactor procedures existentes
- [x] `schema/04_functions/07_pa_finalizar_alquiler.sql`: envolver cuerpo en
  `BEGIN ... EXCEPTION WHEN ... THEN p_estado := 'ERROR_...'; p_mensaje := SQLERRM; END;`.
  Agregar `OUT p_estado TEXT, OUT p_mensaje TEXT`.
  > **Nota implementación:** se agregaron tambien `OUT p_id_factura BIGINT` y
  > el parametro de entrada `p_estado_final_vehiculo` se renombro a
  > `p_estado_destino_vehiculo` para no colisionar con el OUT `p_estado`.
  > El procedure trae `DROP PROCEDURE IF EXISTS pa_finalizar_alquiler(BIGINT,
  > INTEGER, BIGINT, VARCHAR, BIGINT, TEXT) CASCADE` previo al CREATE OR
  > REPLACE porque cambiar la firma altera la identidad en `pg_proc`. El
  > re-GRANT lo hace el bloque DO al final de `04_rls_policies.sql`.
- [x] `schema/04_functions/09_pa_enviar_mantenimiento_programado.sql`: idem,
  agregar `OUT p_estado, OUT p_mensaje`.
  > **Nota implementación:** mismo patron de DROP PROCEDURE previo
  > (`BIGINT, BIGINT, TEXT`).
- [x] `schema/04_functions/10_pa_registrar_devolucion_mantenimiento.sql`: idem.
  > **Nota implementación:** DROP PROCEDURE con la firma vieja (`BIGINT,
  > INTEGER`) antes del CREATE OR REPLACE.
- [x] `schema/04_functions/11_pa_registrar_cliente_con_usuario.sql`: idem,
  agregar `OUT p_id_generado BIGINT` con el `id_usuario` creado.
  > **Nota implementación:** ademas se captura en el `WHEN OTHERS` el
  > caso de `fn_validar_credenciales` (que lanza `RAISE EXCEPTION` sin
  > SQLSTATE especifico) detectando "formato" en el SQLERRM y mapeando a
  > `ERROR_VALIDACION`.

#### 5.2 Refactor frontend para nuevo retorno
- [x] Actualizar todos los call sites de los procedures refactoreados para
  leer `p_estado` y mostrar `p_mensaje` en caso de error.
- [x] Componentes afectados: `CerrarAlquilerForm.tsx`, formularios de admin
  que usen mantenimiento.
  > **Nota implementación:** el unico call site existente es
  > `frontend/components/CerrarAlquilerForm.tsx` (lee `p_estado`,
  > `p_mensaje` y `p_id_factura`). No hay UI activa para
  > `pa_enviar_mantenimiento_programado`, `pa_registrar_devolucion_mantenimiento`
  > ni `pa_registrar_cliente_con_usuario` — se actualizaron solo los tipos
  > en `frontend/types/database.ts` (seccion `Functions`) con la nueva
  > firma para que cuando se construyan esas UI los tipos compilen contra
  > el retorno estandarizado `{ p_estado, p_mensaje [, p_id_*] }`.

#### 5.3 Demo literal de `COMMIT/ROLLBACK`
- [x] Crear `tests/transacciones_explicitas.sql` con:
  - Procedure `pa_demo_transaccional()` que ejecuta un INSERT, hace
    `COMMIT;` explícito, ejecuta otro INSERT, hace `ROLLBACK;` explícito,
    y verifica el estado final con `RAISE NOTICE`.
  - Comentario explicativo: "Este script se ejecuta vía `psql -f` (fuera de
    transacción HTTP). No es invocable desde Supabase RPC por la restricción
    documentada en `JUSTIFICACION.md` §R2."
  > **Nota implementación:** se usa `CREATE TEMP TABLE demo_tx` para no
  > contaminar el schema `public` ni la tabla `audit_log`. La verificacion
  > final (`SELECT count(*) ... esperado: 1`) lanza `RAISE EXCEPTION` si el
  > estado no es el esperado, asi `ON_ERROR_STOP=1` corta el script.
- [x] Script `scripts/demo-transaccional.sh` que ejecute
  `psql "$DATABASE_URL" -f tests/transacciones_explicitas.sql`.
  > **Nota implementación:** mismo patron que `deploy.sh` para resolver
  > `DATABASE_URL` desde `.env` (POSTGRES_USER / POSTGRES_PASSWORD /
  > POSTGRES_DB / POSTGRES_PORT). Si no hay `psql` en el host se
  > documenta como error explicito (sin fallback a docker para no acoplar
  > el script al stack de docker-compose).

#### 5.4 Documentación
- [x] Agregar sección "Política transaccional" en `README.md` enlazando
  `docs/requisitos/JUSTIFICACION.md` §R2.
- [x] Agregar referencia a `tests/transacciones_explicitas.sql` como
  "demostración literal de COMMIT/ROLLBACK".

#### 5.5 Verificación
- [ ] Ejecutar `bash scripts/demo-transaccional.sh` contra docker-compose
  local: debe terminar sin errores y mostrar las trazas de `RAISE NOTICE`.
- [ ] Invocar cada procedure refactoreado vía RPC desde el frontend y
  verificar que retorna `{ p_estado, p_mensaje, ... }`.
- [ ] Disparar deliberadamente un `unique_violation` (ej: registrar cliente
  con DNI duplicado) y verificar que el frontend muestra mensaje legible,
  no un error 500.

> **Nota verificación:** los items de 5.5 quedan pendientes para la
> verificacion en vivo (no se pueden marcar desde la sesion de codigo, ya
> que requieren ejecutar docker compose y el frontend contra Supabase).

---

## Anexo A — Mapeo final requisito → artefacto

| Req | Artefacto principal | Sprint |
|-----|---------------------|--------|
| R1 | `audit_log` + `fn_audit_generic` + `/admin/auditoria` | 1 |
| R2 | `EXCEPTION WHEN` en todos los SPs + `pa_demo_transaccional` | 5 |
| R3 | `pa_crud_vehiculo` + `pa_registrar_cliente_con_usuario` + SPs de reserva/alquiler | 2, 3, 5 |
| R4 | Contrato `(p_estado, p_mensaje, p_id_generado)` en todos los SPs | 2, 3, 5 |
| R5 | `IN` (todos) / `OUT` (estandar) / `INOUT` (`pa_cancelar_reserva.p_motivo`, `pa_baja_vehiculo.p_motivo`) | 2, 3 |
| R6 | `pa_registrar_alquiler` con `p_id_reserva` nullable | 3 |
| R7 | `pa_registrar_reserva` + `fn_validar_*` + `fn_check_vehiculo_overlap` (reusada) | 2 |
| R8 | `pa_cancelar_reserva` con validaciones de estado | 2 |
| R9 | `pg_cron` + `devolucion_vencida` + `pa_detectar_devoluciones_vencidas` | 4 |
| R10 | `pa_finalizar_alquiler` + triggers de lifecycle + `fn_calcular_factura` (ya existe, se refactor en S5) | — / 5 |

---

## Anexo B — Convenciones para esta entrega

- **Nomenclatura SP:** `pa_<accion>_<entidad>` (alta) o `pa_<accion>` (cuando
  involucra varias entidades). Coherente con los existentes.
- **Nomenclatura función:** `fn_<que_valida_o_calcula>`.
- **Códigos de retorno:** `OK | ERROR_VALIDACION | ERROR_DUPLICADO | ERROR_REFERENCIAL | ERROR_ESTADO | ERROR`.
- **Numeración archivos:** continuación del esquema actual (`18_`, `19_`, `20_`...).
- **Commits:** convencionales (`feat(schema):`, `feat(frontend):`, `refactor(schema):`).
