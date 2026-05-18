# Arquitectura — Sistema de Alquiler de Vehículos (TBD TFI 2026)

> **Documento de diseño arquitectónico — Etapa 2.**
> Materia: Tecnologías de Bases de Datos · UTN FRRe · Cuatrimestre 1 2026
> Autor del modelado: Giuliano Holzmann · Aportes: Marcia Viera

---

## 1. Resumen ejecutivo

El sistema implementa un **modelo BaaS (Backend-as-a-Service) puro** sobre Supabase. Toda la lógica de negocio, autorización y validación vive en **PostgreSQL** (constraints, triggers, funciones, procedures, Row Level Security). El frontend se comunica directamente con la base de datos a través de la **API REST auto-generada por PostgREST**, autenticando vía **JWT emitidos por GoTrue**.

**Decisión de diseño clave:** No se desarrolla un backend tradicional ni Edge Functions. Todas las operaciones se cubren con:

- **PostgREST** → CRUD genérico sobre tablas/vistas
- **JWT + RLS** → autorización por fila evaluada por Postgres
- **Funciones SQL invocadas vía RPC** → lógica de dominio (ej. `pa_finalizar_alquiler`, `fn_calcular_factura`)
- **Triggers** → invariantes de dominio y cascadas de estado (lifecycle de alquiler, mantenimiento, ubicación)

Esto reduce la superficie del sistema a dos artefactos desplegables: el **schema SQL** (fuente de verdad en este repo) y la **app de frontend** (desplegable estático).

---

## 2. Vista de componentes (alto nivel)

```mermaid
flowchart LR
    subgraph Browser["Cliente (Browser)"]
        FE["Frontend SPA<br/>(supabase-js)"]
    end

    subgraph SB["Supabase Platform (managed)"]
        GT["GoTrue<br/>Auth Service"]
        PR["PostgREST<br/>REST API"]
        RT["Realtime<br/>WebSocket"]
        ST["Storage<br/>(S3-compat)"]
        KG["Kong<br/>API Gateway"]
    end

    subgraph PG["PostgreSQL 16"]
        AUTH[("auth.users<br/>(schema auth)")]
        DOM[("Schema public<br/>17 tablas + funciones<br/>+ triggers + RLS")]
    end

    FE -- "HTTPS<br/>JWT en Authorization header" --> KG
    KG --> GT
    KG --> PR
    KG --> RT
    KG --> ST

    GT -- "CRUD identidades" --> AUTH
    PR -- "SQL parametrizado<br/>+ SET LOCAL role" --> DOM
    RT -- "Logical replication" --> DOM
    ST -- "Metadata" --> DOM

    AUTH -. "auth.uid()<br/>referenciado por<br/>RLS policies" .-> DOM
```

### Componentes

| # | Componente | Responsabilidad | Mantenimiento |
|---|------------|-----------------|---------------|
| 1 | **Frontend SPA** | UI, manejo de sesión local, llamadas a Supabase. Sin lógica de negocio. | Equipo dev |
| 2 | **Kong (API Gateway)** | Single entrypoint, routing por path, rate limiting. | Supabase managed |
| 3 | **GoTrue (Auth)** | Signup/login, emisión de JWT firmados (HS256), refresh tokens, OAuth. | Supabase managed |
| 4 | **PostgREST** | Traduce HTTP → SQL; deriva endpoints leyendo `information_schema`. | Supabase managed |
| 5 | **Realtime** | Stream de cambios vía replication slots → WebSocket. | Supabase managed (opcional) |
| 6 | **Storage** | Buckets para imágenes de vehículos (alternativa a URLs externas actuales). | Supabase managed (opcional) |
| 7 | **PostgreSQL 16** | Motor relacional. Lógica de dominio completa. | Self-managed vía repo |

---

## 3. PostgreSQL — diagrama de clases internas

El núcleo del sistema. Cinco bloques lógicos: **tablas de dominio**, **catálogos**, **funciones de negocio**, **triggers de invariantes**, **policies RLS**.

```mermaid
classDiagram
    direction LR

    class Tablas_Dominio {
        <<schema public>>
        +usuario(id_usuario, username, password_hash, email)
        +cliente(id_cliente, id_usuario FK, dni, nombre, ...)
        +sucursal(id_sucursal, nombre, direccion, ...)
        +vehiculo(id_vehiculo, id_sucursal_origen FK, id_estado FK, ...)
        +reserva(id_reserva, id_cliente FK, id_vehiculo FK, id_tipo_reserva FK, estado)
        +alquiler(id_alquiler, id_reserva FK, id_vehiculo FK, id_sucursal_devolucion FK, estado)
        +mantenimiento(id_mantenimiento, id_vehiculo FK, id_taller FK, ...)
        +factura(id_factura, id_alquiler FK, numero_factura, total, ...)
        +historial_estado_vehiculo(...)
        +ubicacion_vehiculo(...)
    }

    class Catalogos {
        <<schema public>>
        +estado_vehiculo(id_estado, codigo, descripcion)
        +tipo_vehiculo(id_tipo, codigo, descripcion)
        +tipo_reserva(id_tipo_reserva, codigo, requiere_garantia, ...)
        +tarifa(id_tarifa, id_tipo_vehiculo FK, id_sucursal FK, precio_por_dia, porcentaje_recargo)
    }

    class Funciones_Negocio {
        <<plpgsql>>
        +fn_check_vehiculo_overlap() RETURNS trigger
        +fn_alquiler_lifecycle() RETURNS trigger
        +fn_mantenimiento_lifecycle() RETURNS trigger
        +fn_calcular_factura(p_id_alquiler bigint) RETURNS factura
        +pa_finalizar_alquiler(p_id_alquiler, p_km_fin, p_id_sucursal_devolucion) PROCEDURE
    }

    class Triggers_Invariantes {
        <<auto-fire>>
        +trg_reserva_no_overlap BEFORE INSERT/UPDATE ON reserva
        +trg_alquiler_no_overlap BEFORE INSERT/UPDATE ON alquiler
        +trg_alquiler_start AFTER INSERT ON alquiler
        +trg_alquiler_set_cerrado BEFORE UPDATE ON alquiler
        +trg_alquiler_close AFTER UPDATE ON alquiler
        +trg_mantenimiento_envio AFTER INSERT ON mantenimiento
        +trg_mantenimiento_devolucion AFTER UPDATE ON mantenimiento
    }

    class Policies_RLS {
        <<ROW LEVEL SECURITY>>
        +cliente_self_read ON cliente USING auth.uid()
        +reserva_owner_crud ON reserva USING auth.uid()
        +vehiculo_public_read ON vehiculo FOR SELECT
        +staff_all ON * TO authenticated WHERE jwt->>role = 'staff'
    }

    class Roles {
        <<cluster-level>>
        +postgres (owner, apply.sh)
        +authenticator (PostgREST switches roles)
        +anon (no JWT)
        +authenticated (JWT valido)
        +service_role (bypass RLS)
        +quique (evaluacion docente, full grants)
    }

    Tablas_Dominio --> Catalogos : FK
    Triggers_Invariantes --> Funciones_Negocio : invoca
    Triggers_Invariantes ..> Tablas_Dominio : modifica
    Funciones_Negocio ..> Tablas_Dominio : lee/escribe
    Policies_RLS ..> Tablas_Dominio : filtra rows
    Roles ..> Policies_RLS : evaluado por
```

### Convenciones del schema

- **PK**: `BIGSERIAL` en todas las tablas (`id_<entidad>`)
- **Dinero**: `NUMERIC(12,2)`
- **Estados de máquina de estado**: catálogo FK (no `VARCHAR` enum), excepto enums simples (`alquiler.estado`, `reserva.estado`)
- **Snapshots de tarifa**: `factura.precio_por_dia_aplicado` y `porcentaje_recargo_aplicado` se persisten en la factura para que cambios futuros de tarifa no alteren históricos
- **Idempotencia**: `apply.sh` ejecuta `DROP SCHEMA public CASCADE; CREATE SCHEMA public;` y reaplica todo desde el repo. La base es **stateless por diseño** — toda la verdad vive en el repo

---

## 4. Supabase Platform — diagrama de clases internas

```mermaid
classDiagram
    direction TB

    class GoTrue {
        <<service>>
        +signUp(email, password) Session
        +signInWithPassword(email, password) Session
        +signInWithOtp(email) magic_link
        +refreshSession(refresh_token) Session
        +signOut() void
        -jwt_secret: string
        -issuer: "supabase"
    }

    class JWT {
        <<token>>
        +sub uuid
        +email string
        +role anon_or_authenticated_or_service_role
        +app_metadata object
        +user_metadata object
        +exp timestamp
    }

    class PostgREST {
        <<service>>
        +GET    /rest/v1/:table
        +POST   /rest/v1/:table
        +PATCH  /rest/v1/:table
        +DELETE /rest/v1/:table
        +POST   /rest/v1/rpc/:function_name
        -db_anon_role anon
        -db_authenticator_role authenticator
        -schema public
    }

    class Realtime {
        <<service>>
        +subscribe(channel, event, callback)
        +unsubscribe(channel)
        -replication_slot: "supabase_realtime"
    }

    class Storage {
        <<service>>
        +upload(bucket, path, file)
        +getPublicUrl(bucket, path) string
        +createSignedUrl(bucket, path, expiresIn) string
        -metadata_schema: "storage"
    }

    class KongGateway {
        <<gateway>>
        +route(path) Service
        +rateLimit(ip, key)
        +injectAuthHeader(jwt)
    }

    GoTrue ..> JWT : emite
    PostgREST ..> JWT : valida + SET LOCAL role
    Realtime ..> JWT : valida
    Storage ..> JWT : valida
    KongGateway --> GoTrue : /auth/v1/*
    KongGateway --> PostgREST : /rest/v1/*
    KongGateway --> Realtime : /realtime/v1/*
    KongGateway --> Storage : /storage/v1/*
```

### Mecánica PostgREST + RLS

1. Cliente manda `Authorization: Bearer <JWT>`
2. PostgREST decodifica JWT, extrae `role` y `sub`
3. Abre conexión como `authenticator`, ejecuta `SET LOCAL ROLE <role_del_jwt>` y `SET LOCAL request.jwt.claims = '<json>'`
4. Postgres ejecuta query con identidad del usuario; `auth.uid()` retorna el `sub`
5. RLS policies filtran filas según `auth.uid()` o `auth.jwt() ->> 'role'`

**Implicación arquitectónica:** PostgREST no es un ORM ni un mapper — es un *traductor sintáctico*. Toda la autorización es responsabilidad de Postgres vía RLS.

---

## 5. Frontend — diagrama de clases internas (agnóstico de framework)

```mermaid
classDiagram
    direction TB

    class SupabaseClient {
        <<sdk>>
        +auth: AuthApi
        +from(table) PostgrestQueryBuilder
        +rpc(fn, params) PromiseResponse
        +channel(name) RealtimeChannel
        +storage: StorageApi
        -url: string
        -anon_key: string
    }

    class AuthSessionStore {
        <<state>>
        +session: Session | null
        +user: User | null
        +signIn(email, pwd)
        +signUp(email, pwd)
        +signOut()
        -persistTo: localStorage
        -onAuthStateChange(callback)
    }

    class DataHook {
        <<composable>>
        +useVehiculosDisponibles() : Vehiculo[]
        +useReservasDelCliente() : Reserva[]
        +useAlquileresActivos() : Alquiler[]
        +useFacturasDelCliente() : Factura[]
    }

    class MutationHook {
        <<composable>>
        +useCrearReserva() : (dto) => Promise
        +useCancelarReserva() : (id) => Promise
        +useFinalizarAlquiler() : (params) => Promise
    }

    class RouteGuard {
        <<middleware>>
        +requireAuth() redirect_or_pass
        +requireRole(role) redirect_or_pass
    }

    class UIComponents {
        <<presentational>>
        +VehiculoCard(v: Vehiculo)
        +ReservaForm(onSubmit)
        +AlquilerDetalle(a: Alquiler)
        +FacturaImpresa(f: Factura)
        +AdminPanelLayout()
        +ClientePanelLayout()
    }

    AuthSessionStore --> SupabaseClient : auth.*
    DataHook --> SupabaseClient : from().select()
    MutationHook --> SupabaseClient : from().insert() / rpc()
    RouteGuard --> AuthSessionStore : lee session
    UIComponents --> DataHook : consume data
    UIComponents --> MutationHook : invoca mutations
```

### Capas del frontend

| Capa | Rol | Equivalente en frameworks comunes |
|------|-----|-----------------------------------|
| **SDK** | Singleton `createClient(URL, ANON_KEY)`. Único punto de contacto con Supabase. | `lib/supabase.ts` |
| **AuthSessionStore** | Estado global de sesión. Listener de `onAuthStateChange`. | Context React / Pinia / Svelte store |
| **DataHook** | Suscripción declarativa a queries. Cache, refetch, loading state. | `useSWR`, `useQuery`, `createResource` |
| **MutationHook** | Disparador imperativo de cambios + invalidación de cache. | `useMutation` |
| **RouteGuard** | Middleware de ruteo según `session` y `role`. | Middleware Next.js, navigation guards |
| **UI** | Componentes puros, sin acceso directo a SDK. | React/Vue/Svelte components |

---

## 6. Casos de uso — diagramas de secuencia

### 6.1. Cliente reserva un vehículo online

```mermaid
sequenceDiagram
    autonumber
    actor C as Cliente
    participant FE as Frontend SPA
    participant GW as Kong
    participant GT as GoTrue
    participant PR as PostgREST
    participant DB as PostgreSQL

    Note over C,DB: Pre-condicion: cliente ya registrado, sesion activa con JWT

    C->>FE: Click "Reservar v3 Gol Trend"
    FE->>FE: Construye dto: {id_vehiculo, fecha_inicio, fecha_fin, id_tipo_reserva}

    FE->>GW: POST /rest/v1/reserva (Authorization Bearer JWT, body dto)
    GW->>PR: forward

    PR->>PR: Decodifica JWT, extrae role=authenticated, sub=uuid
    PR->>DB: BEGIN, SET LOCAL ROLE authenticated, SET LOCAL request.jwt.claims

    PR->>DB: INSERT INTO reserva VALUES (dto) RETURNING row

    Note over DB: RLS policy reserva_owner_crud<br/>WITH CHECK id_cliente = cliente_del_jwt()

    DB->>DB: trg_reserva_no_overlap BEFORE INSERT<br/>llama fn_check_vehiculo_overlap
    DB->>DB: SELECT contra reservas+alquileres del mismo vehiculo

    alt Hay solapamiento
        DB-->>PR: RAISE EXCEPTION overlap detectado
        PR-->>GW: 409 Conflict + mensaje
        GW-->>FE: 409
        FE-->>C: Toast Vehiculo ya reservado en esas fechas
    else Sin solapamiento
        DB->>DB: INSERT OK, reserva.estado=pendiente
        DB-->>PR: row insertada
        PR->>DB: COMMIT
        PR-->>GW: 201 Created + reserva
        GW-->>FE: 201 + reserva
        FE->>FE: Invalida cache useReservasDelCliente
        FE-->>C: UI muestra Reserva confirmada
    end
```

### 6.2. Empleado finaliza un alquiler (RPC + cascada de triggers)

Este caso ejercita la pieza central del sistema: una única invocación RPC dispara la procedure `pa_finalizar_alquiler`, que delega en triggers para cerrar el alquiler, abrir/cerrar ubicaciones, mirrorear el estado del vehículo y emitir factura.

```mermaid
sequenceDiagram
    autonumber
    actor E as Empleado (staff)
    participant FE as Frontend SPA
    participant GW as Kong
    participant PR as PostgREST
    participant DB as PostgreSQL
    participant PA as pa_finalizar_alquiler
    participant T1 as trg_alquiler_set_cerrado<br/>(BEFORE UPDATE)
    participant T2 as trg_alquiler_close<br/>(AFTER UPDATE)
    participant FC as fn_calcular_factura

    E->>FE: Form Cerrar alquiler 5 (km_fin=12000, sucursal_devolucion=3)

    FE->>GW: POST /rest/v1/rpc/pa_finalizar_alquiler<br/>Bearer JWT_staff, params p_id_alquiler=5 p_km_fin=12000 p_id_sucursal_devolucion=3
    GW->>PR: forward
    PR->>DB: BEGIN, SET LOCAL ROLE authenticated,<br/>SELECT pa_finalizar_alquiler(5, 12000, 3)

    Note over DB: RLS policy staff_all permite invocacion<br/>(claim role staff)

    DB->>PA: CALL pa_finalizar_alquiler(5, 12000, 3)

    PA->>DB: SELECT alquiler WHERE id=5 FOR UPDATE
    PA->>DB: validaciones: alquiler.estado=activo, km_fin mayor que km_inicio

    PA->>DB: UPDATE alquiler SET fecha_devolucion_real=NOW(), km_fin=12000, id_sucursal_devolucion=3 WHERE id_alquiler=5

    DB->>T1: dispara BEFORE UPDATE
    T1->>T1: NEW.estado asignar cerrado
    T1-->>DB: NEW row modificada

    DB->>DB: aplica UPDATE
    DB->>T2: dispara AFTER UPDATE
    T2->>DB: UPDATE vehiculo SET id_estado=disponible, km_actuales=12000
    T2->>DB: UPDATE historial_estado_vehiculo SET fecha_hasta=NOW()<br/>WHERE id_vehiculo=v AND fecha_hasta IS NULL
    T2->>DB: INSERT historial_estado_vehiculo (id_vehiculo, id_estado=disponible, fecha_desde=NOW)
    T2->>DB: UPDATE ubicacion_vehiculo SET fecha_hasta=NOW WHERE fecha_hasta IS NULL
    T2->>DB: INSERT ubicacion_vehiculo (id_vehiculo, id_sucursal=3, fecha_desde=NOW)
    T2-->>DB: ok

    PA->>FC: SELECT fn_calcular_factura(5)
    FC->>DB: lee alquiler, tarifa, snapshot precio + recargo
    FC->>DB: calcula dias_pactados, horas_excedidas (CEIL EPOCH/3600),<br/>costo_base, recargo_excedente, total
    FC->>DB: INSERT INTO factura (id_alquiler, numero_factura) RETURNING row
    FC-->>PA: factura row

    PA-->>DB: ok
    DB-->>PR: factura
    PR->>DB: COMMIT
    PR-->>GW: 200 OK + factura
    GW-->>FE: 200 + factura
    FE->>FE: invalida cache useAlquileresActivos, useFacturasDelCliente
    FE-->>E: Pantalla Alquiler 5 cerrado, Factura FAC-000004, Total X
```

**Observación arquitectónica:** El frontend hace **una sola llamada HTTP**. Todo lo que ocurre dentro de la DB (UPDATE → trigger BEFORE → trigger AFTER → INSERTs en 4 tablas → cálculo de factura) sucede en una **única transacción**. Si cualquier paso falla, la transacción revierte y el frontend recibe el error con rollback completo. Esto es el equivalente arquitectónico de un "endpoint transaccional de backend" sin que exista backend.

---

## 7. Recomendación de stack frontend

Criterios: **simple de levantar**, **template oficial con Supabase**, **TypeScript end-to-end**, **deploy gratis**, **CRUD fluido**.

### Recomendación primaria: **Next.js 14 + Supabase Starter**

```bash
npx create-next-app@latest tbd-tfi-frontend -e with-supabase
cd tbd-tfi-frontend
# Editar .env.local con NEXT_PUBLIC_SUPABASE_URL y NEXT_PUBLIC_SUPABASE_ANON_KEY
bun install
bun dev
```

| Aspecto | Por qué |
|---------|---------|
| Template oficial Supabase | Auth flow (signup, login, magic link, reset password) ya cableado |
| App Router | Server components leen Supabase con cookies HttpOnly (más seguro que solo client) |
| TypeScript | `supabase gen types typescript --linked > types/database.ts` regenera types desde el schema |
| Tailwind + shadcn/ui | `npx shadcn-ui@latest add table form button` da componentes copy-paste sin engordar el bundle |
| Deploy | `vercel deploy` gratis, integra con git |
| Ecosistema | TanStack Query / SWR / Zustand encajan bien |

### Alternativas evaluadas

| Stack | Cuándo conviene | Trade-off |
|-------|-----------------|-----------|
| **Refine.dev + Supabase data provider** | Si querés panel admin instantáneo (CRUD scaffolded por schema) y poco custom UX | Menos flexible para UX a medida del cliente final |
| **SvelteKit + Supabase** | Equipo más cómodo con Svelte; bundle más chico | Comunidad y ejemplos más chicos que Next |
| **Nuxt 3 + @nuxtjs/supabase** | Equipo Vue | Mismo nivel de soporte que Next, pero menos templates listos |
| **Astro + supabase-js** | Sitios principalmente estáticos con CRUD esporádico | El alquiler tiene mucha interactividad → menos buen fit |
| **Vite + React + supabase-js** | Máxima simpleza, sin SSR | Tenés que cablear auth, ruteo, types manualmente |

**Conclusión:** Next.js 14 + template `with-supabase` es el mejor punto de entrada. Cubre auth, ruteo, SSR, types generados y deploy en una sola decisión.

---

## 8. Vista de despliegue

```mermaid
flowchart TB
    subgraph Dev["Desarrollo local"]
        REPO["GitHub repo<br/>schema/ + scripts/"]
        DEV_FE["Frontend dev<br/>localhost:3000"]
        DEV_DB["Docker postgres:16<br/>localhost:5432"]
        DEV_FE -. supabase-local .-> DEV_DB
    end

    subgraph CI["GitHub Actions"]
        WF[".github/workflows/deploy.yml<br/>path filter: schema/**"]
    end

    subgraph Prod["Produccion"]
        VERCEL["Vercel<br/>frontend SPA"]
        SUPABASE["Supabase Cloud<br/>Free tier"]
        PG_PROD[("PostgreSQL 16<br/>managed")]

        VERCEL -- HTTPS + JWT --> SUPABASE
        SUPABASE --> PG_PROD
    end

    REPO --> WF
    WF -- "psql apply.sh<br/>via DATABASE_URL" --> PG_PROD
    REPO -. push main .-> VERCEL
```

### Flujo de entrega

1. Cualquier cambio en `schema/**` que llega a `main` dispara `deploy.yml`
2. CI ejecuta `scripts/apply.sh` contra Supabase Cloud usando `DATABASE_URL` secret → `DROP SCHEMA public CASCADE; CREATE SCHEMA public;` + reaplicación completa
3. En caso de fallo, `scripts/notify-discord.sh` notifica
4. Frontend en Vercel se redeploya en cada push (independiente del schema)

### Entornos

| Entorno | Postgres | Frontend | Auth |
|---------|----------|----------|------|
| Local dev | Docker `postgres:16` + Supabase CLI (`supabase start`) | `bun dev` en localhost:3000 | GoTrue local |
| Producción | Supabase Cloud (free tier) | Vercel | GoTrue managed |

---

## 9. Decisiones arquitectónicas registradas (ADRs cortos)

| # | Decisión | Razón |
|---|----------|-------|
| 1 | BaaS puro, sin backend propio | El alcance del TPI cabe entero en PostgREST + RLS + RPC. Reduce código a mantener. |
| 2 | Sin Edge Functions | No hay integraciones con terceros (pagos, mail) en el alcance. Si más adelante hicieran falta, se agregan sin tocar lo demás. |
| 3 | Autorización 100% en Postgres (RLS) | Una sola fuente de verdad para permisos. El frontend no puede saltarla. |
| 4 | Lógica transaccional en SQL (procedures + triggers) | Atomicidad nativa, sin orquestador externo. Caso `pa_finalizar_alquiler` demuestra el patrón. |
| 5 | Schema idempotente, repo como source-of-truth | `apply.sh` recrea desde cero. Reproducibilidad total entre dev y producción. |
| 6 | Frontend Next.js + template oficial Supabase | Tiempo a primer demo más corto del ecosistema. Types auto-generados. |
| 7 | Imágenes vía URLs públicas (GitHub raw) | Suficiente para demo. Migración a Supabase Storage es trivial cuando haga falta. |

---

## 10. Referencias

- Documento de diseño Etapa 1: `TFI-2026 - Alquiler de Vehículos.pdf`
- Schema SQL: `schema/` (tablas, constraints, indexes, functions, seeds, permissions)
- Procedure central: `schema/04_functions/06_pa_finalizar_alquiler.sql`
- Función de facturación: `schema/04_functions/05_fn_calcular_factura.sql`
- Rol de evaluación docente: `schema/06_permissions/01_profesor_quique.sql`
- Documentación Supabase: https://supabase.com/docs
- PostgREST: https://postgrest.org
