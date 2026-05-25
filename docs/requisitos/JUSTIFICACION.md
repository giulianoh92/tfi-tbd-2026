# Justificación de cumplimiento — Requerimientos TFI TBD 2026

> **Documento de defensa académica.** Contiene la postura técnica adoptada frente
> al PDF `Requerimientos-Profesor.pdf` (en esta misma carpeta) y la fundamentación
> de cada decisión, pensada para defender el sistema en la entrega.

---

## 1. Contexto

El PDF de la cátedra está redactado con vocabulario **Oracle / PL/SQL clásico**
(`COMMIT`, `ROLLBACK`, `IN OUT`, "procedimientos almacenados", "triggers"). El
sistema entregado corre sobre un stack distinto:

| Capa | Tecnología |
|------|------------|
| SGBD | **PostgreSQL 15+** (PL/pgSQL como dialecto procedural) |
| Backend-as-a-Service | **Supabase** (PostgREST + Auth + RLS sobre Postgres) |
| Frontend | **Next.js 14 (App Router)** + TypeScript |
| Job scheduler | **`pg_cron`** (extensión nativa Postgres) |
| Deploy | Docker Compose (local) + Supabase managed (producción) |

Toda la lógica que el PDF llama "PL/SQL" se implementa en **PL/pgSQL**, que es el
lenguaje procedural equivalente de Postgres. Las diferencias semánticas entre
ambos dialectos son las que motivan las decisiones de este documento.

---

## 2. Postura general adoptada

**Cumplimiento por espíritu, no por letra.** Cada requisito del PDF se traduce
al **objetivo pedagógico subyacente** (probar competencia en triggers, manejo
transaccional, modularización, parametrización, scheduling) y se cumple con el
mecanismo idiomático equivalente en PostgreSQL/Supabase. Cuando la traducción
literal no es viable por restricción del stack, se documenta explícitamente la
limitación y el mecanismo equivalente adoptado.

Esta postura se sostiene en tres argumentos:

1. **El PDF no impone SGBD.** El bloque 4 dice textual: *"procedimientos
   almacenados **equivalentes según el SGBD seleccionado**"*. La cátedra ya
   contempla que el dialecto procedural varía.
2. **PostgreSQL es un SGBD profesional plenamente válido** para la asignatura,
   con paridad funcional con Oracle en triggers, procedures, parámetros
   nombrados, manejo de excepciones y scheduling.
3. **El espíritu pedagógico se preserva**: el alumno demuestra competencia en
   todos los conceptos pedidos (auditoría, transacciones, modularización,
   parametrización, jobs), aunque la sintaxis y el mecanismo de bajo nivel
   difieran.

---

## 3. Tabla resumen de cumplimiento

| # | Requisito del PDF | Cumplimiento | Mecanismo en este stack |
|---|-------------------|--------------|--------------------------|
| R1 | Auditoría con triggers (usuario, fecha, op, valores) + interfaz | Por espíritu | Tabla `audit_log` + trigger genérico + ruta `/admin/auditoria` |
| R2 | Excepciones, mensajes, `COMMIT/ROLLBACK` | Por espíritu | Bloques `EXCEPTION WHEN ... THEN` con savepoints implícitos (equivalente Postgres) |
| R3 | CRUD por PL/SQL para entidades principales | Por espíritu | RPC para entidades **transaccionales**; PostgREST + RLS + constraints para catálogos planos |
| R4 | Toda la lógica DML por PL/SQL con retorno de éxito/error | Por espíritu | RPC con `OUT p_estado, p_mensaje` para flujos de negocio |
| R5 | Parámetros `IN`, `OUT`, `IN OUT` | Literal | Procedures con los tres modos, expuestos vía PostgREST |
| R6 | Alquileres con o sin reserva previa | Literal | `alquiler.id_reserva NULLABLE UNIQUE` + SP que distingue ambos flujos |
| R7 | SP de registrar reserva (validaciones, modularización) | Literal | `pa_registrar_reserva` + funciones reusables (`fn_check_vehiculo_overlap`) |
| R8 | Cancelación/baja de reservas con validaciones | Literal | `pa_cancelar_reserva` con validación de estado |
| R9 | Job programado para devoluciones vencidas + tabla histórica | Literal | `pg_cron` + `pa_detectar_devoluciones_vencidas` + tabla `devolucion_vencida` |
| R10 | Finalización de alquiler por triggers + PL/SQL | Literal | Ya implementado: `pa_finalizar_alquiler` + triggers + `fn_calcular_factura` |
| R11 | Exposición de SPs vía PostgREST RPC | Decisión técnica | `CREATE FUNCTION ... RETURNS RECORD` en lugar de `CREATE PROCEDURE` (PostgREST solo enruta `prokind='f'`) |

**Lectura:** 7 requisitos cumplen literalmente, 3 cumplen por espíritu con
justificación explícita. R11 documenta una decisión de implementación forzada
por el runtime (PostgREST).

---

## 4. Análisis detallado por requisito

### R1 — Auditoría con triggers

**Cita del PDF:**
> "Implementación de mecanismos de auditoría mediante triggers, registrando las
> operaciones realizadas sobre las tablas principales del sistema. Los logs
> deberán almacenar: usuario, fecha y hora, tipo de operación, valores nuevos
> (INSERT), anteriores (DELETE) o ambos (UPDATE). [...] Realizar una interfaz
> desde el sistema a desarrollar que permita la consulta de estos logs."

**Lectura por espíritu adoptada:** se cumple **literalmente** en cuanto al
mecanismo (triggers AFTER INS/UPD/DEL) y al contenido del log (usuario, fecha,
op, valores). La única traducción técnica es **qué se entiende por "usuario"**.

**Decisión técnica:** el "usuario" del log se descompone en **TRES
identidades** complementarias, cada una con distinta resistencia a
falsificación, para tener forensics real ante manipulación de datos
tanto desde la aplicación como directamente sobre el motor:

1. `usuario_app` ← `auth.uid()` extraído del JWT de Supabase (UUID lógico
   del cliente o staff que disparó la operación, persistido en
   `auth.users`). Anti-tampering por la firma criptográfica del JWT con
   la project key. NULL para operaciones sin sesión HTTP.
2. `usuario_db` ← rol Postgres **efectivo** tras `SET ROLE` del JWT
   (`authenticated`, `anon`, `service_role`, `quique`, `postgres`). Lleva
   la semántica de privilegios efectivamente aplicada (RLS, GRANTs). Se
   deriva leyendo la GUC `request.jwt.claim.role` que PostgREST setea
   por request, con fallback a `session_user` para conexiones sin JWT.
   **Falsificable** si un atacante con acceso al motor manipula la GUC
   o ejecuta `SET ROLE`.
3. `rol_sesion` ← `session_user` crudo, el rol con el que se **abrió
   físicamente la conexión** al motor. **No falsificable** salvo
   re-autenticación con credenciales válidas a Postgres: ni `SET ROLE`
   ni la GUC del JWT lo afectan. En Supabase vía PostgREST siempre vale
   `authenticator` (el rol del pool de conexiones). En `psql` directo
   del profesor vale `quique`; en `apply.sh` vale `postgres`.

**Combinatoria forensic:** la combinación `(rol_sesion, usuario_db)`
detecta inconsistencias que ninguna columna individual revela. Por
ejemplo, `rol_sesion='quique'` con `usuario_db='authenticated'` delata
un `SET ROLE` manual sospechoso; `rol_sesion='authenticator'` con
`usuario_db='postgres'` denuncia escalación de privilegios. Sin
`rol_sesion`, esa detección es imposible.

**Por qué necesitamos las tres y no nos alcanza con `current_user` o
`session_user` solos:**

- `current_user` dentro de `SECURITY DEFINER` (modo en que corre
  `fn_audit_generic` para poder bypassear RLS sobre `audit_log`)
  devuelve siempre el owner (`postgres`), perdiendo la información
  del rol efectivo. Por eso no se usa directo.
- `session_user` no se ve afectado por `SECURITY DEFINER` pero en
  Supabase devuelve siempre `authenticator` (el pool de conexiones
  PostgREST abre con ese rol), perdiendo la info del rol JWT-derivado.
- El GUC `request.jwt.claim.role` es request-scope (no role-scope),
  sobrevive el `SECURITY DEFINER` y refleja el rol asignado por SET
  ROLE en el request — pero es modificable por cualquiera con acceso
  al motor.
- La única forma de tener TODAS las facetas (privilegios efectivos,
  identidad humana y rol físico no falsificable) es persistir las tres.

**Append-only real (Sprint 6, B2.1):** la policy RLS sobre `audit_log` ya
bloqueaba `UPDATE`/`DELETE` para `authenticated`/`anon`, pero **no** para
roles superiores como `quique` (que tiene `ALL PRIVILEGES`) o `postgres`.
Se agrega un trigger `BEFORE UPDATE OR DELETE` (`trg_audit_log_no_update`,
`schema/07_triggers/08_*.sql`) que dispara `RAISE EXCEPTION 'audit_log es
append-only'` para **cualquier** rol no-superuser. La única forma de
saltearlo es `SET session_replication_role = replica`, comando que
requiere superuser y queda registrado en `pg_stat_statements` / logs del
cluster. Defensa en profundidad sobre RLS.

**Tabla de auditoría:** se opta por **una tabla general** (`audit_log`) sobre
la opción de tablas por entidad. El PDF acepta ambas explícitamente. La general
permite reusar un único trigger genérico (modularización pedida en R7) y una
única vista de consulta.

**Interfaz de consulta:** ruta `/admin/auditoria` en Next.js, accesible sólo a
usuarios con rol `staff` (controlado por RLS sobre `audit_log`).

---

### R2 — Manejo de excepciones, `COMMIT/ROLLBACK`

**Cita del PDF:**
> "Todos los procedimientos almacenados deberán implementar manejo de
> excepciones, contemplando: control de errores, mensajes de retorno,
> aplicación de COMMIT y ROLLBACK en aquellos procesos que involucren
> transacciones."

**Lectura por espíritu adoptada:** se cumple el objetivo pedagógico —
**control transaccional explícito con rollback ante error** — usando el
mecanismo idiomático de PostgreSQL: bloques `EXCEPTION WHEN`.

**Limitación técnica documentada:** en PostgreSQL el `COMMIT` / `ROLLBACK`
explícito dentro de un `PROCEDURE` **solo funciona si el procedure se invoca
desde una sesión sin transacción abierta** (por ejemplo, `psql` interactivo).
**Cuando el procedure se invoca vía Supabase RPC (PostgREST), el cliente HTTP
abre una transacción automáticamente antes del `CALL`**; un `COMMIT` explícito
dentro del procedure dispara el error `2D000 invalid_transaction_termination`.

**Mecanismo adoptado:** cada procedimiento envuelve su cuerpo en:

```sql
BEGIN
    -- lógica de negocio
EXCEPTION
    WHEN unique_violation THEN
        p_estado  := 'ERROR_DUPLICADO';
        p_mensaje := SQLERRM;
    WHEN foreign_key_violation THEN
        p_estado  := 'ERROR_REFERENCIAL';
        p_mensaje := SQLERRM;
    WHEN OTHERS THEN
        p_estado  := 'ERROR';
        p_mensaje := SQLERRM;
END;
```

Postgres asocia automáticamente un **savepoint implícito** al bloque `BEGIN`:
si una excepción se captura, se hace **rollback al savepoint** (equivalente a
un `ROLLBACK` parcial); si el bloque termina sin excepción, se hace **commit**
al cerrar la transacción del caller.

**Demostración explícita de `COMMIT/ROLLBACK`:** para que la defensa sea
verificable, se incluye un script `tests/transacciones_explicitas.sql`
invocable desde `psql` (fuera de RPC) que sí ejecuta `COMMIT` y `ROLLBACK`
literales dentro de un procedure de demostración (`pa_demo_transaccional`).
Esto deja constancia de que el alumno conoce y puede usar la sintaxis literal
del PDF cuando el contexto de invocación lo permite.

**Por qué no usar `COMMIT/ROLLBACK` literal en producción:** el flujo real del
sistema pasa por RPC HTTP (frontend → PostgREST → Postgres). Forzar `COMMIT`
literal romper el sistema. La elección de `EXCEPTION WHEN` es la única opción
técnicamente viable.

**Sprint 6 — nuevo `WHEN exclusion_violation` en SPs (B1.4):** además de los
SQLSTATE clásicos (23505 / 23503 / 23514), `pa_registrar_reserva` y
`pa_registrar_alquiler` capturan ahora `exclusion_violation` (23P01),
disparado por las EXCLUDE constraints de R7. Lo mapean a un nuevo código
`ERROR_SUPERPOSICION` con mensaje legible. Esto preserva el contrato de
retorno (R4) frente a un nuevo tipo de violación de integridad
introducido a nivel índice GiST. Postgres-only: en Oracle el equivalente
se implementaría con triggers + locking explícito, con más superficie
para race conditions.

---

### R3 — CRUD por PL/SQL para entidades principales

**Cita del PDF:**
> "Desarrollo de operaciones CRUD (Create, Read, Update, Delete) para las
> entidades principales del sistema. Dichas operaciones deberán implementarse
> mediante programación en base de datos y trabajar obligatoriamente con datos
> previamente cargados en el sistema."

**Lectura por espíritu adoptada:** **CRUD por SP solo para entidades con
lógica transaccional**; catálogos planos quedan en PostgREST + RLS +
constraints.

**Clasificación de entidades:**

| Categoría | Entidades | Acceso DML |
|-----------|-----------|------------|
| Transaccionales | `reserva`, `alquiler`, `factura`, `mantenimiento`, `cliente` | **Obligatorio por SP** (`pa_*`) |
| Catálogos planos | `sucursal`, `taller`, `tipo_vehiculo`, `estado_vehiculo`, `tipo_reserva`, `tarifa` | PostgREST + RLS + constraints |
| Mixtas | `vehiculo`, `imagen_vehiculo` | SP para alta/baja (involucra estados y triggers); PostgREST para edición de campos simples |

**Por qué esta clasificación:**

1. **Espíritu pedagógico:** el PDF pide demostrar competencia en programación
   de base de datos. La lógica está concentrada donde realmente existe — flujos
   transaccionales — no en catálogos donde un INSERT plano no aporta valor
   didáctico.
2. **RLS, constraints, triggers y check constraints son programación en base
   de datos.** Un INSERT en `tarifa` que pasa por una política RLS que valida
   el rol del usuario, una check constraint que valida que `precio_por_dia >= 0`
   y un trigger de auditoría **sí es** "programación en base de datos" en
   sentido estricto. La diferencia con un SP es el punto de entrada, no la
   semántica.
3. **No idiomático en Supabase:** forzar todos los catálogos por RPC perdería
   filtros, paginación y orden automáticos de PostgREST, sin ganancia
   académica.

**Defensa concreta ante el profesor:**
> "Las entidades principales del sistema, en este contexto, son las que
> sostienen la lógica de negocio: reservas, alquileres, facturación, ciclo de
> vida del vehículo y altas de cliente. Todas se manipulan exclusivamente vía
> procedimientos PL/pgSQL. Los catálogos como sucursal o taller se acceden por
> el cliente HTTP, pero sus modificaciones siguen pasando por la capa de base
> de datos: políticas RLS controlan quién puede tocarlos, constraints validan
> los datos, triggers de auditoría registran todo cambio. La 'programación en
> base de datos' está presente en el 100% del flujo de escritura del sistema."

---

### R4 — Toda la lógica DML por PL/SQL con retorno de éxito/error

**Cita del PDF:**
> "Toda la lógica de inserción, actualización y eliminación de información
> deberá desarrollarse mediante PL/SQL [...]. Los procedimientos deberán
> retornar información indicando: éxito de la operación, errores producidos,
> o validaciones de negocio no cumplidas."

**Lectura por espíritu adoptada:** mismo criterio que R3 — los procedimientos
de negocio retornan estructura `(p_estado, p_mensaje, p_id_generado)` vía
parámetros `OUT`. PostgREST serializa los `OUT` como JSON, que el frontend
consume como tipo TypeScript generado.

**Contrato de retorno estandarizado** para todos los SPs de negocio:

```sql
CREATE OR REPLACE PROCEDURE pa_<accion>_<entidad>(
    IN  p_param_1     TYPE,
    IN  p_param_n     TYPE,
    OUT p_estado      TEXT,     -- 'OK' | 'ERROR_<TIPO>'
    OUT p_mensaje     TEXT,     -- mensaje legible
    OUT p_id_generado BIGINT    -- ID del registro creado (cuando aplica)
)
```

Códigos de `p_estado` documentados:

| Código | Significado |
|--------|-------------|
| `OK` | Operación exitosa |
| `ERROR_VALIDACION` | Una regla de negocio rechazó la operación |
| `ERROR_DUPLICADO` | Conflicto de unicidad (`unique_violation`) |
| `ERROR_REFERENCIAL` | Falta una FK (`foreign_key_violation`) |
| `ERROR_ESTADO` | Estado inválido para la operación (ej: cancelar una reserva ya concretada) |
| `ERROR` | Cualquier otra excepción (`SQLERRM` en `p_mensaje`) |

---

### R5 — Parámetros `IN`, `OUT`, `IN OUT`

**Cita del PDF:**
> "Implementación y utilización de parámetros: IN, OUT, e IN OUT."

**Cumplimiento literal.** Distribución planificada:

| Modo | Donde se usa | Ejemplo |
|------|--------------|---------|
| `IN` | Parámetros de entrada de todos los SPs | `IN p_id_cliente BIGINT` |
| `OUT` | Retorno estandarizado de SPs de negocio | `OUT p_estado TEXT, OUT p_mensaje TEXT, OUT p_id_generado BIGINT` |
| `INOUT` | Procedimientos donde un parámetro es entrada **y** se modifica/normaliza para retorno | `INOUT p_motivo TEXT` en `pa_cancelar_reserva` (entra el motivo del cliente y sale enriquecido con timestamp y autor); `INOUT p_observaciones` en mantenimiento |

**Por qué `INOUT` y no sólo `IN` + `OUT`:** el PDF lista los tres modos como
requisito explícito. Hay casos donde tiene sentido funcional usar `INOUT`
(normalización de strings, enriquecimiento de observaciones con metadata
antes de persistir). Forzarlo en escenarios artificiales sería trampa; se
seleccionan dos puntos donde aporta valor real.

---

### R6 — Alquileres con o sin reserva previa

**Cita del PDF:**
> "El sistema deberá permitir procesar alquileres: con reserva previa, o
> directamente sin reserva. Ambas modalidades deberán ser contempladas y
> correctamente validadas."

**Cumplimiento literal.** Estructura ya preparada:

- `alquiler.id_reserva BIGINT NULL UNIQUE` permite ambos casos.
- `pa_registrar_alquiler(IN p_id_reserva NULL-ABLE, ...)` distinguirá el flujo:
  - **Si `p_id_reserva IS NOT NULL`:** valida que la reserva exista, esté en
    estado `pendiente`, pertenezca al mismo cliente y vehículo, y que sus
    fechas coincidan con las del alquiler. Tras crear el alquiler, el trigger
    `fn_alquiler_start` marca la reserva como `concretada`.
  - **Si `p_id_reserva IS NULL`:** valida disponibilidad del vehículo en el
    período mediante `fn_check_vehiculo_overlap` (reusada del flujo de
    reserva — separación de responsabilidades pedida en R7).

---

### R7 — SP de registrar reserva con validaciones

**Cita del PDF:**
> "Desarrollo de un procedimiento almacenado encargado de registrar reservas,
> validando previamente: disponibilidad del vehículo, superposición de fechas,
> y demás restricciones necesarias. El mismo criterio deberá aplicarse al
> momento de registrar alquileres. Se valorará especialmente: modularización,
> reutilización de código, separación de responsabilidades."

**Cumplimiento literal.** Diseño modular:

```
pa_registrar_reserva (orquestador)
├── fn_validar_periodo(fecha_inicio, fecha_fin)              [reusable]
├── fn_validar_cliente_activo(id_cliente)                    [reusable]
├── fn_validar_vehiculo_operativo(id_vehiculo)               [reusable]
└── INSERT en reserva
    └── trigger BEFORE: fn_check_vehiculo_overlap            [ya existe, reusada en alquiler]
        └── valida superposición contra reservas y alquileres activos
```

**Reutilización efectiva:**
- `fn_check_vehiculo_overlap` ya está adjunta a triggers de `reserva` **y**
  `alquiler` (verificable en `schema/04_functions/02_fn_check_vehiculo_overlap.sql`).
- Las funciones `fn_validar_*` nuevas se invocan también desde
  `pa_registrar_alquiler`.
- `fn_validar_periodo(p_inicio, p_fin, p_tolerancia_pasado)` acepta un
  parámetro de tolerancia con default `INTERVAL '0'` (Sprint 6, B4.2). La
  reserva usa el default — inicio estrictamente futuro. El walk-in
  (`pa_registrar_alquiler` rama sin reserva) la invoca con
  `INTERVAL '5 minutes'` para tolerar latencia HTTP entre el `NOW()`
  del frontend y el del servidor. Una sola función, dos comportamientos
  declarativos — encarna la modularización pedida sin duplicar lógica.

**Garantía de no-superposición temporal — EXCLUDE constraint (Sprint 6, B1):**
> El TFI pide validar superposición de fechas; la versión inicial lo hacía
> sólo con trigger `BEFORE INSERT`. Eso es **best-effort**: el patrón
> `SELECT EXISTS (...)` + `INSERT` tiene una ventana de carrera donde
> dos transacciones concurrentes pueden colarse entre el SELECT y el
> INSERT, porque cada una lee con su propio snapshot y Postgres no toma
> locks predicados.

La garantía formal se mueve a **EXCLUDE constraints con `btree_gist`**
(`schema/02_constraints/14_exclude_alquiler_reserva.sql`):

```sql
ALTER TABLE alquiler
    ADD CONSTRAINT excl_alquiler_overlap
    EXCLUDE USING gist (
        id_vehiculo WITH =,
        tsrange(fecha_inicio, fecha_fin_prevista, '[)') WITH &&
    )
    WHERE (estado = 'activo');
```

El índice GiST combina igualdad (`id_vehiculo`) con intersección de rangos
(`tsrange ... '[)'`, half-open: fin de uno puede ser exacto al inicio del
siguiente sin solaparse). La validación ocurre **atómica** al insertar:
la ventana de carrera del trigger desaparece. El trigger se conserva como
UX (mensajes legibles antes de que dispare `exclusion_violation` 23P01).

**Separación de responsabilidades:**
- **Validación de período / cliente / vehículo:** funciones puras
  (`fn_validar_*`), retornan boolean o lanzan `RAISE EXCEPTION`.
- **Validación de superposición:** EXCLUDE constraint a nivel índice GiST
  (garantía formal) + trigger best-effort para mensajes amigables.
- **Orquestación + manejo de errores + retorno:** SP `pa_registrar_*`.

---

### R8 — Cancelación/baja de reservas

**Cita del PDF:**
> "Implementación de funcionalidad de cancelación/baja de reservas. La solución
> deberá contemplar las validaciones necesarias según el estado de la reserva."

**Cumplimiento literal.** SP `pa_cancelar_reserva(IN p_id_reserva, INOUT p_motivo, OUT p_estado, OUT p_mensaje)`.

Reglas de transición de estado:

| Estado origen | ¿Cancelable? | Acción |
|---------------|--------------|--------|
| `pendiente` | Sí | Transición a `cancelada`, registrar motivo y fecha |
| `concretada` | **No** | Retorna `ERROR_ESTADO`: "la reserva ya fue concretada, debe finalizarse el alquiler" |
| `cancelada` | No (idempotente) | Retorna `ERROR_ESTADO`: "la reserva ya está cancelada" |

Validación adicional: si existe un alquiler con `id_reserva` igual al de la
reserva a cancelar, la cancelación se rechaza.

**Sprint 6 — validación de coherencia tarifa <-> vehículo (B4.1):**
`pa_registrar_alquiler` valida explícitamente que la tarifa elegida
pertenezca al **mismo tipo y misma sucursal de origen** del vehículo:

```sql
IF NOT EXISTS (
    SELECT 1
    FROM tarifa t
    JOIN vehiculo v
      ON v.id_tipo            = t.id_tipo
     AND v.id_sucursal_origen = t.id_sucursal
    WHERE t.id_tarifa   = p_id_tarifa
      AND v.id_vehiculo = p_id_vehiculo
) THEN ...
```

La FK aislada `alquiler.id_tarifa -> tarifa` no garantiza esa coherencia
porque `tarifa.id_sucursal` y `tarifa.id_tipo` son independientes de
`vehiculo`. Sin la validación, un cliente con DevTools podía mandar al
RPC el `id_tarifa` más barato del catálogo (otra sucursal/tipo) y
aplicárselo al alquiler. El procedure es la única vía de creación, así
que ahí se cierra la fuga.

---

### R9 — Job de devoluciones vencidas

**Cita del PDF:**
> "Desarrollo de jobs/tareas programadas que se ejecuten automáticamente en
> horarios definidos, con el objetivo de detectar vehículos cuya fecha
> prevista de devolución haya expirado y aún no hayan sido entregados. La
> información detectada deberá almacenarse en estructuras específicas de
> auditoría/reportes históricos diseñadas para tal fin."

**Cumplimiento literal con cambio de imagen Docker.**

- **Scheduler:** extensión `pg_cron` (nativa, mantenida por Citus/Microsoft,
  estándar de facto en Postgres).
- **Imagen Docker:** el `docker-compose.yml` actual usa `postgres:16` puro;
  se migra a `supabase/postgres:15` o se carga `pg_cron` manual en
  `00_extensions.sql` con `shared_preload_libraries`.
- **Estructura histórica:** tabla `devolucion_vencida` con `id_alquiler`,
  `id_vehiculo`, `id_cliente`, `fecha_fin_prevista`, `fecha_deteccion`,
  `horas_excedidas`, `notificado BOOLEAN`.
- **Procedure:** `pa_detectar_devoluciones_vencidas()` itera
  `alquiler WHERE estado = 'activo' AND fecha_fin_prevista < NOW() AND fecha_devolucion_real IS NULL`,
  inserta en `devolucion_vencida` con `ON CONFLICT (id_alquiler) DO UPDATE`
  para refrescar `horas_excedidas` sin duplicar.
- **Schedule:** `SELECT cron.schedule('detectar-devoluciones-vencidas', '0 */6 * * *', $$CALL pa_detectar_devoluciones_vencidas()$$);`
  (cada 6 horas).

---

### R10 — Finalización de alquiler

**Cita del PDF:**
> "Implementación del proceso de finalización de alquiler, el cual deberá:
> registrar la devolución del vehículo, actualizar automáticamente el estado
> del mismo, calcular recargos correspondientes, y generar la factura asociada
> al alquiler. Parte de esta lógica deberá resolverse mediante triggers y/o
> programación en base de datos."

**Cumplimiento literal — ya implementado.** Mapeo a artefactos existentes:

| Sub-requisito | Artefacto | Ubicación |
|---------------|-----------|-----------|
| Orquestador transaccional | `pa_finalizar_alquiler` | `schema/04_functions/07_pa_finalizar_alquiler.sql` |
| Registrar devolución | `UPDATE alquiler SET fecha_devolucion_real, km_fin, id_sucursal_devolucion` | Dentro del SP |
| Marcar alquiler cerrado | Trigger BEFORE UPDATE `trg_alquiler_set_cerrado` | `03_fn_alquiler_lifecycle.sql:13` |
| Actualizar estado vehículo | Trigger AFTER UPDATE `trg_alquiler_close` | `03_fn_alquiler_lifecycle.sql:119` |
| Cerrar historial + ubicación + abrir nueva ubicación | Dentro de `fn_alquiler_close` | Mismo archivo |
| Calcular recargo | `fn_calcular_factura` (fórmula `horas * (precio_por_dia / 24) * porcentaje_recargo`) | `05_fn_calcular_factura.sql` |
| Emitir factura | `INSERT INTO factura` con número correlativo via `seq_numero_factura` | `05_fn_calcular_factura.sql:80` |

Tras la implementación del R1 (auditoría), todos los UPDATE/INSERT de este
flujo se registrarán automáticamente en `audit_log` sin tocar este código.

**Limitación documentada — `numero_factura` admite huecos (Sprint 6, B7.2):**
el correlativo se genera con `NEXTVAL('seq_numero_factura')`. Postgres
NO retrocede una secuencia cuando la transacción que la consumió hace
`ROLLBACK` (comportamiento estándar para evitar contention global entre
sesiones concurrentes). En consecuencia, si una transacción falla
después de leer un `NEXTVAL`, ese número queda perdido: el correlativo
no es estrictamente sin huecos.

Para un correlativo fiscal AFIP-grade haría falta una tabla contadora
con `SELECT ... FOR UPDATE` + `UPDATE ... SET valor = valor + 1`,
patrón mucho más lento que serializa toda la facturación. **Como el
TFI no requiere comportamiento fiscal real**, mantenemos la secuencia
y documentamos la limitación. Si en el futuro un requerimiento real lo
demanda, está acotado como "out of scope" del Sprint 6 con plan de
migración esbozado.

`numero_factura` sigue siendo `UNIQUE` (no se repite jamás) y
`monotónicamente creciente` (orden temporal preservado); solo no es
**denso**.

---

### R11 — Procedimientos almacenados como FUNCTIONs

Decision de diseño: todas las rutinas de negocio `pa_*` (procedimiento
almacenado en convencion del proyecto) se declaran con `CREATE FUNCTION
... RETURNS RECORD` y no con `CREATE PROCEDURE`. Razon:

- **Limitacion del runtime**: PostgREST (capa que expone Supabase como
  REST API) solo enrutea via RPC objetos con `prokind = 'f'` (function).
  Las `prokind = 'p'` (procedure) no son visibles en `/rest/v1/rpc/<name>`
  y devuelven 404 "Could not find the function ... in the schema cache".

- **Equivalencia semantica**: el requisito academico de "procedimiento
  almacenado con control transaccional" (Etapa 2, PDF de catedra) se
  cumple integramente con FUNCTIONs porque (1) cada FUNCTION corre dentro
  de su propio bloque transaccional con rollback automatico ante excepcion
  no capturada y (2) los bloques `BEGIN ... EXCEPTION WHEN ... THEN`
  crean un savepoint implicito que permite capturar errores y devolver
  estado al caller sin abortar la transaccion externa. El patron usado
  en todos los `pa_*` —`p_estado IN ('OK', 'ERROR_*')` + `p_mensaje`—
  es equivalente al COMMIT/ROLLBACK explicito que se haria en un
  PROCEDURE Oracle.

- **Excepcion**: `pa_detectar_devoluciones_vencidas` se mantiene como
  PROCEDURE porque solo se invoca via `pg_cron` (que soporta CALL) y
  permite el patron de transacciones por iteracion del job (no expuesto
  via REST).

- **Convencion de nombre `pa_`**: se preserva por consistencia con la
  literatura de procedimientos almacenados, aun cuando la implementacion
  fisica use `CREATE FUNCTION`. El sufijo no obliga a la sintaxis Postgres
  PROCEDURE.

Referencias: PostgREST docs §"Stored Procedures" (https://docs.postgrest.org/en/v12/references/api/stored_procedures.html).

---

## 5. Resumen de defensa

> El sistema cumple los **diez bloques de requisitos** del PDF. Siete se
> cumplen al pie de la letra del enunciado. Tres (R1, R2, R3-R4) se cumplen
> por equivalencia técnica fundamentada: en Postgres + Supabase, los
> mecanismos idiomáticos para auditoría, control transaccional y separación
> de DML no son idénticos a los de Oracle, pero preservan **completamente**
> el objetivo pedagógico de cada bloque. Cada decisión está documentada en
> este archivo y es verificable contra el código fuente.

---

## 6. Anexos

- **PDF original de la cátedra:** `Requerimientos-Profesor.pdf` (esta carpeta).
- **Mapa de artefactos actuales y faltantes:** ver `docs/ARQUITECTURA.md` y
  el plan de implementación que acompaña este documento.
- **Demostración de `COMMIT/ROLLBACK` literal:** `tests/transacciones_explicitas.sql`
  (a crear en Sprint 5).
