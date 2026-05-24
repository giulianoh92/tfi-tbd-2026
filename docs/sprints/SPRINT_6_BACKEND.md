# Sprint 6 — Backend / Base de Datos

**Origen**: code review Senior DB Architect (Postgres + Supabase).
**Scope**: solo `schema/` + `scripts/` + `docs/` + `README.md`. NO toca `frontend/`.
**Ejecutable en paralelo con**: `SPRINT_6_FRONTEND.md` (desacoplado).
**Branch sugerida**: `sprint-6-backend`.
**Modo de validacion**: `scripts/deploy.sh` debe levantar limpio post-sprint.

## Politica del TFI (clave para este sprint)

> **La base de datos es efimera**. Cada push reaplica el schema desde cero (`DROP SCHEMA public CASCADE; CREATE SCHEMA public; ...`). NO hay produccion que migrar. NO se versionan ALTER TABLEs.

Reglas operativas que se derivan:

1. **Editar el codigo directamente** en su archivo de `schema/`. NO usar `ALTER TABLE`, NO usar archivos de "migration".
2. **Cero `DEPRECATED`**. Si algo no se usa, se borra. Si se queda, va con un comentario que explica el porque (defensa academica).
3. **Cada decision tecnica propia de Postgres o Supabase lleva comentario in-line** explicando el motivo. Objetivo: que cualquier linea sea defendible verbalmente en la presentacion sin abrir Stack Overflow.
4. Respetar la estructura del README:
   - `00_extensions.sql`
   - `01_tables/` (un archivo por tabla, FK en linea NO; van en 02)
   - `02_constraints/` (FKs y constraints multi-columna)
   - `03_indexes/`
   - `04_functions/` (funciones, triggers, vistas)
   - `05_seeds/`
   - `06_permissions/`
   - `07_triggers/` ya existe desde Sprint 1; se mantiene y se documenta en README.
5. Sin tildes en codigo SQL; tildes correctas en `.md`.
6. Conventional commits separados por bloque tematico.

---

## Bloque B1 — Concurrencia y unicidad de alquileres (CRITICO)

> Race condition real: `fn_check_vehiculo_overlap` es best-effort. Dos transacciones pueden colarse en la ventana entre `SELECT EXISTS` y el `INSERT`. La solucion idiomatica en Postgres son EXCLUDE constraints con `btree_gist` + `tsrange`.

- [x] B1.1 En `schema/00_extensions.sql`, agregar `CREATE EXTENSION IF NOT EXISTS btree_gist;` con comentario:
  ```sql
  -- btree_gist habilita combinar tipos de igualdad (BIGINT) con rangos (tsrange)
  -- en una misma EXCLUDE constraint via indice GiST. Postgres-only; en Oracle
  -- el equivalente se hace con triggers + locking explicito, mucho mas pesado.
  ```
- [x] B1.2 Editar **directamente** `schema/02_constraints/` (archivo de constraints de alquiler, o crear `XX_alquiler_exclude.sql` siguiendo la numeracion existente). NO usar ALTER:
  ```sql
  -- Garantia de no-superposicion a nivel de indice, NO a nivel de trigger.
  -- WHERE estado='activo' excluye alquileres cancelados/finalizados: dos clientes
  -- pueden tener "alquiler" del mismo vehiculo en el mismo rango si uno esta cerrado.
  -- tsrange con limites '[)' es half-open: fin_prevista de un alquiler puede ser
  -- igual a inicio del siguiente sin colisionar (devolucion 10:00, alquiler 10:00).
  ALTER TABLE alquiler
      ADD CONSTRAINT excl_alquiler_overlap
      EXCLUDE USING gist (
          id_vehiculo WITH =,
          tsrange(fecha_inicio, fecha_fin_prevista, '[)') WITH &&
      )
      WHERE (estado = 'activo');
  ```
  > Nota: este es el unico lugar donde se usa la palabra ALTER, y es porque el README lo dicta: las constraints multi-columna van en `02_constraints/`. NO es una migracion en sentido versionado; es la definicion canonica que se re-aplica desde cero en cada deploy.
- [x] B1.3 Equivalente para `reserva` (`excl_reserva_overlap`) en el mismo archivo o uno paralelo. Restringido a `estado IN ('pendiente','confirmada')`. Mismo comentario explicativo adaptado.
- [x] B1.4 En `schema/04_functions/16_pa_registrar_reserva.sql` y `18_pa_registrar_alquiler.sql`, **editar el bloque EXCEPTION existente** para mapear el nuevo SQLSTATE:
  ```sql
  EXCEPTION
      ...
      -- 23P01 = exclusion_violation. Lo dispara EXCLUDE USING gist cuando
      -- otra transaccion ya ocupo el rango. Es el "lock optimista" idiomatico.
      WHEN exclusion_violation THEN
          p_estado  := 'ERROR_SUPERPOSICION';
          p_mensaje := 'El vehiculo ya esta reservado/alquilado en ese periodo.';
      ...
  ```
- [x] B1.5 Eliminar el trigger `fn_check_vehiculo_overlap` o convertirlo en mensaje amigable previo (validacion best-effort para errores legibles antes del EXCLUDE). Documentar la decision en el header del archivo: "este trigger NO es la garantia de unicidad; lo es la EXCLUDE constraint. Existe solo para devolver mensajes mas claros en el camino feliz."

**Commit**: `feat(schema): exclude constraint para superposicion de alquileres y reservas`

---

## Bloque B2 — Auditoria append-only real (CRITICO)

> `audit_log` tiene policy `USING (FALSE)` para `authenticated, anon`, pero el rol `quique` (con ALL PRIVILEGES) puede `UPDATE/DELETE` y borrar huella. Ademas, dentro de un trigger SECURITY DEFINER, `current_user = postgres` siempre, lo que invalida la doble identidad documentada.

- [x] B2.1 Crear `schema/07_triggers/08_trg_audit_log_append_only.sql` con trigger BEFORE UPDATE OR DELETE:
  ```sql
  -- El audit_log es append-only por contrato. La policy RLS lo bloquea para
  -- authenticated/anon, pero NO para roles superiores que no sean NOBYPASSRLS.
  -- Este trigger es la segunda linea de defensa: aun el rol postgres dispara
  -- el RAISE si intenta UPDATE/DELETE. Solo un SUPERUSER con SET session_replication_role = replica
  -- podria saltearlo, y eso queda registrado en pg_stat_statements / logs.
  CREATE OR REPLACE FUNCTION fn_audit_log_append_only()
  RETURNS TRIGGER LANGUAGE plpgsql AS $$
  BEGIN
      RAISE EXCEPTION 'audit_log es append-only (operacion %, usuario %)',
          TG_OP, session_user;
  END;
  $$;

  CREATE TRIGGER trg_audit_log_no_update
      BEFORE UPDATE OR DELETE ON audit_log
      FOR EACH ROW EXECUTE FUNCTION fn_audit_log_append_only();
  ```
- [x] B2.2 **Editar** `schema/04_functions/12_fn_audit_generic.sql` y reemplazar `current_user` por `session_user` en la asignacion de `usuario_db`, con comentario:
  ```sql
  -- session_user devuelve el rol con el que se autentico la sesion HTTP
  -- (ej. 'authenticated'), aun dentro de un SECURITY DEFINER que rota
  -- current_user a 'postgres'. Sin esto, la columna usuario_db siempre
  -- registraria 'postgres' y la doble identidad documentada (DB + JWT)
  -- perderia su mitad de DB. Ver Postgres docs: "session_user vs current_user".
  ```
- [x] B2.3 Smoke test (script bash en `tests/audit_append_only.sh` o `psql -c` en validacion manual): conectarse como `quique`, ejecutar `UPDATE audit_log SET tabla='x' WHERE id_audit=1;`. Debe fallar con `audit_log es append-only`.
- [x] B2.4 Smoke test doble identidad: `INSERT` en `cliente` desde rol `authenticated`. Leer `audit_log` y verificar que `usuario_db = 'authenticated'`, no `'postgres'`.

**Commit**: `fix(schema): audit_log append-only via trigger y session_user en doble identidad`

---

## Bloque B3 — RLS performance: cachear auth.uid()

> Las policies que hacen `USING (auth_user_id = fn_auth_uid())` evaluan la function por fila. Es la primera optimizacion de RLS recomendada por Supabase. Cambio mecanico, ganancia medible en cuanto el cliente tenga decenas de reservas.

- [x] B3.1 **Editar** `schema/06_permissions/04_rls_policies.sql` y reemplazar todas las apariciones de `fn_auth_uid()` y `fn_es_staff()` dentro de `USING`/`WITH CHECK` por su forma cacheada `(SELECT fn_auth_uid())` / `(SELECT fn_es_staff())`. Agregar comentario al inicio del archivo:
  ```sql
  -- Patron oficial de Supabase para RLS: envolver las helpers en (SELECT ...).
  -- Esto fuerza al planner a evaluar la function una sola vez por query
  -- (InitPlan) en lugar de una vez por fila (Function Scan), reduciendo
  -- el costo de O(n) a O(1) sobre tablas grandes. Aplica solo a functions
  -- marcadas STABLE; ambas helpers lo son.
  -- Ref: https://supabase.com/docs/guides/database/postgres/row-level-security#performance
  ```
- [x] B3.2 Validar via `EXPLAIN ANALYZE` que el plan ahora hace `InitPlan` (ej. consulta `SELECT * FROM reserva WHERE id_cliente = (SELECT auth_user_id ...)`). Adjuntar el EXPLAIN antes/despues como comentario en el commit (opcional, util para la defensa).

**Commit**: `perf(rls): cachear auth.uid() y es_staff via subselect`

---

## Bloque B4 — Validacion semantica de tarifa y periodo

> Hoy un cliente avispado puede aplicar la tarifa mas barata de cualquier sucursal/tipo a su alquiler porque `pa_registrar_alquiler` no valida la coherencia tarifa <-> vehiculo. Y `fn_validar_periodo` exige `inicio > NOW()`, rompiendo el flujo walk-in.

- [x] B4.1 **Editar** `schema/04_functions/18_pa_registrar_alquiler.sql`. Agregar bloque de validacion **antes** del INSERT:
  ```sql
  -- Regla de negocio: la tarifa elegida tiene que pertenecer a la sucursal
  -- de origen del vehiculo Y al tipo del vehiculo. La FK aislada no lo asegura
  -- porque tarifa.id_sucursal y tarifa.id_tipo son independientes de vehiculo.
  IF NOT EXISTS (
      SELECT 1
      FROM tarifa t
      JOIN vehiculo v
        ON v.id_tipo = t.id_tipo
       AND v.id_sucursal_origen = t.id_sucursal
      WHERE t.id_tarifa = p_id_tarifa
        AND v.id_vehiculo = p_id_vehiculo
  ) THEN
      p_estado  := 'ERROR_VALIDACION';
      p_mensaje := 'La tarifa no corresponde al tipo/sucursal del vehiculo elegido.';
      RETURN;
  END IF;
  ```
- [x] B4.2 **Editar** `schema/04_functions/13_fn_validar_periodo.sql`. Agregar parametro de tolerancia con default 0, manteniendo retro-compatibilidad de los callers existentes:
  ```sql
  -- p_tolerancia_pasado permite usar la misma helper para reservas (default 0,
  -- inicio estrictamente futuro) y para walk-in (inicio puede ser NOW() menos
  -- algunos minutos para tolerar latencia HTTP). Evita duplicar la function
  -- y mantiene un solo lugar donde vive la regla "inicio < fin, max N meses".
  CREATE OR REPLACE FUNCTION fn_validar_periodo(
      p_inicio              TIMESTAMPTZ,
      p_fin                 TIMESTAMPTZ,
      p_tolerancia_pasado   INTERVAL DEFAULT INTERVAL '0'
  ) RETURNS VOID
  ```
  Y la regla pasa a `p_inicio >= NOW() - p_tolerancia_pasado`.
- [x] B4.3 En `pa_registrar_alquiler` rama walk-in, invocar con `INTERVAL '5 minutes'`. En `pa_registrar_reserva` mantener la llamada sin parametro (usa default 0). Eliminar el comentario "TODO frontend pone NOW()+1min" en `18_pa_registrar_alquiler.sql`.

**Commit**: `feat(schema): validacion de tarifa coherente y tolerancia walk-in en fn_validar_periodo`

---

## Bloque B5 — Higiene y consistencia

- [x] B5.1 Borrar `schema/03_indexes/07_idx_historial_estado_vehiculo` (archivo sin extension `.sql`, no se aplica porque `apply.sh` filtra `*.sql`; ademas duplicaria `uq_historial_estado_vigente`).
- [x] B5.2 **Editar** `schema/00_extensions.sql` para remover `CREATE EXTENSION ... "uuid-ossp"` si esta presente. Justificacion en comentario donde se conservan las extensiones:
  ```sql
  -- pgcrypto provee gen_random_uuid() (RFC 4122 v4). uuid-ossp historicamente
  -- aportaba uuid_generate_v4() y derivados, pero hoy duplica funcionalidad
  -- y suma superficie de attack sin uso real en el proyecto.
  ```
- [x] B5.3 **Editar** las functions que comparan catalogo `estado_vehiculo` de forma case-sensitive y unificar a `lower(nombre)`:
  - `schema/04_functions/03_fn_alquiler_lifecycle.sql:35`
  - `schema/04_functions/06_fn_mantenimiento_lifecycle.sql:11, 52`
- [x] B5.4 **Editar** `schema/01_tables/` (archivo de `estado_vehiculo`) agregando CHECK in-line con comentario:
  ```sql
  nombre VARCHAR(50) NOT NULL UNIQUE
      -- Forzamos minusculas en el catalogo para que los lookups sean
      -- predecibles. Mezclar 'Disponible' y 'disponible' rompe triggers
      -- silenciosamente; mejor cerrar la puerta a nivel constraint.
      CHECK (nombre = lower(nombre))
  ```
- [x] B5.5 **Editar** `schema/04_functions/02_fn_check_vehiculo_overlap.sql` (si sobrevive a B1.5) reemplazando `COALESCE(NEW.id_reserva, -1) <> COALESCE(r.id_reserva, -1)` por `NEW.id_reserva IS DISTINCT FROM r.id_reserva`. Comentario:
  ```sql
  -- IS DISTINCT FROM trata NULL como un valor mas (NULL <> 5 = NULL,
  -- pero NULL IS DISTINCT FROM 5 = TRUE). Mas limpio que sentinels (-1)
  -- que podrian colisionar con IDs reales en otro contexto.
  ```
- [ ] B5.6 Renumerar `schema/04_functions/` si quedo el hueco del `04_*.sql` faltante para que el orden alfabetico de apply.sh sea legible. NO crear archivo dummy; renombrar lo siguiente.

**Commit**: `chore(schema): housekeeping (huerfanos, extensions no usadas, lookups consistentes)`

---

## Bloque B6 — Resolver password_hash: borrar lo que no se usa

> No se "marca deprecated": o sirve, o no esta. La decision academica que se defiende: **la unica fuente de verdad para credenciales es `auth.users.encrypted_password`**, gestionada por Supabase Auth (GoTrue), que emite JWTs y maneja refresh/recovery. Mantener un `usuario.password_hash` paralelo es invitacion a divergencia de credenciales.

- [x] B6.1 Auditar con `rg "password_hash"` y `rg "fn_validar_credenciales"` que no hay invocaciones en runtime (ni functions del schema, ni RPC desde el frontend).
- [x] B6.2 Si NO se usa en runtime:
  - **Editar** `schema/01_tables/` (tabla `usuario`) y eliminar la columna `password_hash` del CREATE TABLE.
  - Borrar `schema/04_functions/08_fn_validar_credenciales.sql` completo.
  - Ajustar seeds en `schema/05_seeds/01_usuario.sql` si insertan password_hash.
  - Agregar al header de `schema/01_tables/` (archivo de usuario) un comentario que sirva de mojon defensivo:
    ```sql
    -- NOTA DE DISENIO: esta tabla NO almacena hash de contrasena.
    -- La autenticacion del sistema corre por Supabase Auth (auth.users),
    -- que persiste la contrasena bcrypt en auth.users.encrypted_password
    -- y emite JWTs firmados con la clave del proyecto. El vinculo entre
    -- public.cliente y la identidad de Auth se resuelve via cliente.auth_user_id
    -- (UUID), poblado por el trigger fn_handle_new_auth_user al crear un user.
    -- Razones de tener UNA SOLA fuente de credencial:
    --   1. Cambios de contrasena (recovery, magic links) viajan por GoTrue
    --      sin que la tabla public.usuario tenga que reflejarlos.
    --   2. Reduce superficie de filtracion: si se filtra public.* el hash
    --      no esta ahi; queda en auth.users (schema bloqueado por defecto
    --      para roles non-superuser).
    --   3. Permite usar features de Auth (OTP, OAuth, MFA) sin reescribir
    --      el flujo de login.
    ```
- [x] B6.3 Si sigue usandose para algun caso edge (improbable, pero verificar): conservar columna + function y agregar comentario explicito sobre por que existe esa ruta paralela. **Por defecto, este sprint asume que se borra**.
- [x] B6.4 Mismo criterio para `usuario.username` si solo se llenaba como seed y ningun runtime lo lee: borrarlo. Si se mantiene como nombre de usuario alternativo al email, comentar el porque.

**Commit**: `refactor(schema): eliminar password_hash y fn_validar_credenciales (Supabase Auth como unica fuente)`

---

## Bloque B7 — Comentar denormalizaciones intencionales

> No es "documentar deprecaciones" — es dejar evidencia in-line de POR QUE el codigo es asi para que la defensa academica pueda apoyarse en el comentario.

- [x] B7.1 **Editar** `schema/01_tables/` archivo de `factura` y agregar comentario sobre `id_cliente`:
  ```sql
  id_cliente BIGINT NOT NULL,
      -- DECISION DE DISENIO: id_cliente se duplica respecto de alquiler.id_cliente
      -- intencionalmente. La factura es un documento contable inmutable: si en
      -- el futuro se reasigna el alquiler a otro cliente (caso corporativo,
      -- transferencia), la factura conserva al cliente que firmo en su momento.
      -- Para "cliente actual del alquiler" leer via JOIN con alquiler.
  ```
- [x] B7.2 **Editar** `schema/04_functions/05_fn_calcular_factura.sql` cerca de `NEXTVAL('seq_numero_factura')` con comentario:
  ```sql
  -- numero_factura puede tener huecos: si una transaccion hace ROLLBACK
  -- (ej. EXCEPTION captura un error post-NEXTVAL), Postgres NO retrocede
  -- la secuencia (comportamiento estandar para evitar lock contention).
  -- Para correlativo fiscal sin huecos hay que usar una tabla contadora
  -- con UPDATE bajo lock; queda fuera de scope del TFI academico, se
  -- documenta la limitacion en JUSTIFICACION.md §R10.
  ```
- [x] B7.3 Idem en `schema/04_functions/12_fn_audit_generic.sql` cerca del `SECURITY DEFINER`:
  ```sql
  -- SECURITY DEFINER: el trigger inserta en audit_log saltandose RLS. Es
  -- intencional. RLS sobre audit_log esta en USING(FALSE) para escritura
  -- desde authenticated/anon, asi que la unica via valida es esta function
  -- corriendo con privilegios del owner. Combinado con search_path=public
  -- y el trigger append-only de B2, el log no es manipulable end-to-end.
  ```

**Commit**: `docs(schema): comentar in-line decisiones defensables (factura snapshot, secuencia con huecos, audit security definer)`

---

## Bloque B8 — Hardening del job pg_cron

- [x] B8.1 **Editar** `schema/04_functions/20_pa_detectar_devoluciones_vencidas.sql` y marcar la procedure como `SECURITY DEFINER SET search_path = public`. Comentario:
  ```sql
  -- SECURITY DEFINER: el job corre como owner (postgres) via pg_cron.
  -- Marcamos explicitamente search_path=public para evitar function
  -- hijacking via schemas en el PATH del invocador (mitigation estandar
  -- contra CVE-2007-2138 y derivados). El INSERT en devolucion_vencida
  -- bypassea RLS por ser definer, lo cual es necesario porque
  -- 'service_role' y el rol del job no figuran en las policies de la tabla.
  ```
- [x] B8.2 **Editar** `schema/06_permissions/` para revocar EXECUTE del PUBLIC/authenticated sobre `pa_detectar_devoluciones_vencidas` y otorgarlo solo a `postgres, service_role`. Comentario:
  ```sql
  -- Este procedure NO es API publica: solo lo invoca pg_cron. Restringir
  -- EXECUTE evita que un cliente con bypass de RLS via SECURITY DEFINER
  -- consuma recursos lanzando el job manualmente desde el frontend.
  ```
- [x] B8.3 Confirmar que `cron.schedule(...)` en `schema/04_functions/21_schedule_jobs.sql` queda envuelto en DO/EXCEPTION (para el caso de Postgres puro sin pg_cron en CI) y con comentario apuntando a Supabase docs.

**Commit**: `feat(jobs): hardening de pa_detectar_devoluciones_vencidas (security definer + grants restringidos)`

---

## Bloque B9 — Sincronizar README con la estructura real

- [x] B9.1 **Editar** `README.md` seccion "Estructura del schema": agregar `07_triggers/` a la tabla con descripcion ("Triggers de auditoria y append-only del log."). El folder existe desde Sprint 1 y `apply.sh` ya lo aplica; el README esta desincronizado.
- [x] B9.2 Si en B1.5 sobrevive `fn_check_vehiculo_overlap`, mencionar en el README que la garantia de unicidad temporal es por EXCLUDE constraint, no por trigger.
- [x] B9.3 Agregar referencia rapida en `README.md` (o `CONTRIBUTING.md`) al criterio "decision Postgres-especifica -> comentario in-line" para futuros aportes del equipo.

**Commit**: `docs(readme): sincronizar estructura del schema (07_triggers) y criterio de comentarios defensables`

---

## Validacion final

- [ ] V1. `docker compose down -v && docker compose up -d --wait`.
- [ ] V2. `./scripts/deploy.sh` levanta sin errores end-to-end.
- [ ] V3. Smoke test concurrencia: dos `psql` simultaneos intentando reservar el mismo vehiculo en periodos solapados -> uno entra, el otro recibe `ERROR_SUPERPOSICION`.
- [ ] V4. Smoke test auditoria append-only: `UPDATE audit_log ... ` desde `quique` -> falla con `audit_log es append-only`.
- [ ] V5. Smoke test doble identidad: insert via rol `authenticated` -> `audit_log.usuario_db = 'authenticated'`, no `'postgres'`.
- [ ] V6. CI verde en GitHub Actions (`validate` + `deploy`).
- [ ] V7. Lectura final de `JUSTIFICACION.md`: actualizar §R7 (EXCLUDE), §R1 (append-only + session_user), §R8 (validacion tarifa), §R2 (mantener), §R10 (huecos en numero_factura documentados).
- [ ] V8. `rg "TODO|FIXME|DEPRECATED" schema/` debe devolver vacio (o solo TODOs explicitamente listados en out-of-scope).

---

## Out of scope (Sprint 7+)

- Migracion de `seq_numero_factura` a tabla contadora con UPDATE bajo lock (cuando se justifique con un requerimiento fiscal real).
- Particionado de `audit_log` por mes (cuando el volumen lo demande).
- Retencion / archiving del audit_log.
- Materializacion de views para reportes.
