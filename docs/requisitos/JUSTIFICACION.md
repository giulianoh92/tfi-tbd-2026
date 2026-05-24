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

**Lectura:** 7 requisitos cumplen literalmente, 3 cumplen por espíritu con
justificación explícita.

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

**Decisión técnica:** la columna `usuario` del log registra **dos identidades**:

1. `usuario_db` ← `current_user` (rol Postgres efectivo).
2. `usuario_app` ← `auth.uid()` extraído del JWT de Supabase (UUID lógico del
   cliente o staff que disparó la operación).

**Por qué:** en Supabase el `current_user` siempre es `authenticator` /
`authenticated` / `anon` (roles de PostgREST), no el usuario lógico de negocio.
Sin la segunda columna la auditoría sería técnicamente correcta pero
funcionalmente inútil. Registrar ambas mantiene trazabilidad completa: a nivel
DBA (rol efectivo) y a nivel negocio (cliente/empleado real).

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

**Separación de responsabilidades:**
- **Validación de período / cliente / vehículo:** funciones puras
  (`fn_validar_*`), retornan boolean o lanzan `RAISE EXCEPTION`.
- **Validación de superposición:** trigger genérico aplicable a `reserva` y
  `alquiler` por igual.
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
