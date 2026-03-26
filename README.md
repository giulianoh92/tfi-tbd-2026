# TBD - Trabajo Final Integrador

Base de datos PostgreSQL con entorno local en Docker y plataforma colaborativa en Supabase.

---

## Estructura del proyecto

```
TBD_TFI/
├── migrations/     # Archivos SQL de migracion (esquema, tablas, constraints)
├── seeds/          # Datos de prueba / seed data
├── scripts/        # Scripts utilitarios (reset, migrate, seed)
├── tests/          # Tests de base de datos (pgTAP o similar)
├── docker-compose.yml
├── .env.example    # Template de variables de entorno
└── README.md
```

| Carpeta | Que va ahi |
|---------|-----------|
| `migrations/` | Archivos `.sql` numerados que definen el esquema. Se ejecutan en orden alfabetico. Nunca modificar una migracion ya commiteada. |
| `seeds/` | Archivos `.sql` con datos de prueba para desarrollo local. |
| `scripts/` | Scripts de shell para automatizar tareas comunes (resetear la base, correr migraciones, etc.). |
| `tests/` | Tests automatizados sobre la base de datos. |

---

## Requisitos previos

- **Docker** y **Docker Compose** (v2+)
- **Git**
- (Opcional) **Supabase CLI** -- `npm install -g supabase`
- (Opcional) **psql** -- cliente de linea de comandos de PostgreSQL

### Windows (WSL2 + Docker Desktop)

Si estas en Windows, todo se corre desde una terminal WSL2 (Ubuntu). **No uses PowerShell ni CMD** para ejecutar los scripts.

1. Instala [Docker Desktop](https://www.docker.com/products/docker-desktop/) y activa la integracion con WSL2 en **Settings > Resources > WSL Integration**.
2. Instala una distro WSL2 (ej: Ubuntu) desde la Microsoft Store si no tenes una.
3. Abri una terminal WSL2 (`wsl` desde PowerShell o busca "Ubuntu" en el menu inicio).
4. Desde ahi segui el setup normal de abajo.

> Los scripts `.sh`, `docker compose`, y `localhost` funcionan igual desde WSL2. El `.gitattributes` del repo garantiza que los archivos mantengan line endings Unix (LF) aunque Git este configurado en Windows.

---

## Setup local con Docker

### 1. Clonar el repo

```bash
git clone <url-del-repo>
cd TBD_TFI
```

### 2. Configurar variables de entorno

```bash
cp .env.example .env
```

Edita `.env` y pone tu password. Para desarrollo local con los valores por defecto alcanza, solo cambia `POSTGRES_PASSWORD`.

### 3. Levantar la base de datos

```bash
docker compose up -d
```

Espera unos segundos a que PostgreSQL termine de iniciar. Podes verificar el estado con:

```bash
docker compose ps
```

### 4. Aplicar migraciones

```bash
./scripts/migrate.sh
```

### 5. Cargar datos de prueba

```bash
./scripts/seed.sh
```

### 6. Abrir el cliente web (pgweb)

Una vez levantado Docker, pgweb esta disponible en:

```
http://localhost:8081
```

Desde ahi podes explorar tablas, ejecutar queries y ver resultados sin instalar nada extra.

### 7. Conectarse por terminal (opcional)

```bash
psql -h localhost -p 5432 -U postgres -d tbd_tfi
```

Te va a pedir la password que configuraste en `.env`.

---

## Trabajar con migraciones

### Convencion de nombres

```
NNN_descripcion.sql
```

Ejemplos:
- `000_extensions.sql`
- `001_create_tabla_clientes.sql`
- `002_create_tabla_pedidos.sql`
- `003_add_index_pedidos_fecha.sql`

### Reglas

1. **Nunca modifiques una migracion que ya fue commiteada.** Si necesitas cambiar algo, crea una nueva migracion.
2. **Numera las migraciones en orden.** Esto garantiza que se ejecuten siempre en la misma secuencia.
3. **Cada migracion debe ser idempotente cuando sea posible** (usa `IF NOT EXISTS`, `IF EXISTS`, etc.).
4. Para empezar de cero, usa:

```bash
./scripts/reset-db.sh
```

Esto elimina la base, la recrea, corre todas las migraciones y los seeds.

---

## Conectar GitHub con Supabase

### 1. Crear un proyecto en Supabase

Anda a [supabase.co](https://supabase.co), crea una cuenta (si no tenes) y crea un nuevo proyecto. Anota el **Project ID** y las keys que te da.

### 2. Conectar el repo de GitHub

1. En el Dashboard de Supabase, anda a **Project Settings > Integrations > GitHub**.
2. Conecta tu cuenta de GitHub y selecciona este repositorio.
3. Esto permite que Supabase vea los cambios del repo.

### 3. Configurar Supabase CLI

Si todavia no inicializaste Supabase en el repo:

```bash
supabase init
```

Despues vincula el proyecto remoto:

```bash
supabase link --project-ref <tu-project-id>
```

Para aplicar las migraciones al proyecto de Supabase:

```bash
supabase db push
```

### 4. (Opcional) CI/CD con GitHub Actions

Podes configurar un workflow de GitHub Actions que corra `supabase db push` automaticamente al mergear a `main`. Supabase tiene documentacion oficial sobre esto: [Supabase CI/CD](https://supabase.com/docs/guides/cli/managing-environments).

---

## Flujo de trabajo del equipo

```
1. Clonar repo + levantar Docker local
2. Crear una branch para tu cambio
3. Escribir migraciones y probar localmente
4. Commit + push a tu branch
5. Abrir un PR para que el equipo revise
6. Mergear a main
7. Aplicar migraciones a Supabase (manual con `supabase db push` o automatico con CI)
```

### En detalle:

1. **Cada miembro** clona el repo y levanta su entorno local con Docker. Esto les da una base PostgreSQL propia para desarrollo.
2. **Para hacer cambios en el esquema**, crea un archivo nuevo en `migrations/` con el proximo numero disponible. Probalo localmente con `./scripts/migrate.sh` o `./scripts/reset-db.sh`.
3. **Commit y push** a una branch con nombre descriptivo (ej: `feat/create-tabla-clientes`).
4. **Abrir un Pull Request** en GitHub para que al menos otro miembro revise los cambios.
5. **Al mergear a `main`**, las migraciones se aplican al Supabase compartido (manualmente o via CI/CD).

---

## Conexion a Supabase remoto

Para conectarte a la instancia compartida de Supabase desde cualquier cliente SQL (psql, DBeaver, DataGrip, etc.):

1. Anda al Dashboard de Supabase > **Project Settings > Database**.
2. Copia el **Connection String** (URI format).
3. Conectate:

```bash
psql "postgresql://postgres:<password>@<host>:5432/postgres"
```

El host, password y demas datos los encontras en el Dashboard. No los commitees al repo -- usa `.env` para guardarlos localmente.

---

## Comandos utiles

| Comando | Que hace |
|---------|----------|
| `docker compose up -d` | Levanta la base de datos en background |
| `docker compose down` | Para y elimina los containers (los datos persisten en el volumen) |
| `docker compose down -v` | Para containers Y elimina el volumen (borra todos los datos) |
| `docker compose logs db` | Ver logs de PostgreSQL |
| `./scripts/migrate.sh` | Ejecuta todas las migraciones pendientes |
| `./scripts/seed.sh` | Carga los datos de prueba |
| `./scripts/reset-db.sh` | Resetea la base completa (drop + create + migrate + seed) |
| `psql -h localhost -p 5432 -U postgres -d tbd_tfi` | Conectarse a la base local |
| `http://localhost:8081` | pgweb -- cliente SQL en el navegador |
| `supabase db push` | Aplicar migraciones al proyecto Supabase remoto |
| `supabase db diff` | Ver diferencias entre el esquema local y remoto |
