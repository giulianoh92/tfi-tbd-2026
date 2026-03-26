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

### Inicio rapido (un solo comando)

```bash
git clone <url-del-repo>
cd TBD_TFI
./scripts/setup.sh
```

Esto crea el `.env`, levanta Docker, aplica migraciones y carga seeds. Al terminar te muestra la URL de pgweb.

### Paso a paso (si preferis hacerlo manual)

```bash
git clone <url-del-repo>
cd TBD_TFI
cp .env.example .env              # editar password si queres
docker compose up -d               # levanta PostgreSQL + pgweb
./scripts/migrate.sh               # aplica migraciones
./scripts/seed.sh                  # carga datos de prueba
```

### Usar pgweb (cliente SQL en el navegador)

Una vez levantado Docker, abri en el navegador:

```
http://localhost:8081
```

Desde ahi podes explorar tablas, ejecutar queries y ver resultados sin instalar nada extra.

### Conectarse por terminal (opcional)

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

## CI/CD: Migraciones automaticas a Supabase

Al mergear a `main`, un workflow de GitHub Actions aplica automaticamente las migraciones nuevas a la base de Supabase. No hace falta instalar nada ni correr comandos manuales.

### Setup (una sola vez, lo hace el admin del repo)

1. En el Dashboard de Supabase, anda a **Project Settings > Database** y copia el **Connection String** (URI). Reemplaza `[YOUR-PASSWORD]` con la password del proyecto.
2. En GitHub, anda a **Settings > Secrets and variables > Actions**.
3. Crea un secret llamado `SUPABASE_DB_URL` con el connection string como valor.

Listo. A partir de ahora, cada push a `main` que incluya cambios en `migrations/` dispara el workflow automaticamente.

---

## Flujo de trabajo del equipo

### Setup inicial (una sola vez por persona)

```bash
git clone <url-del-repo>
cd TBD_TFI
./scripts/setup.sh
```

### Dia a dia

1. **Levantar el entorno** (si no esta corriendo): `docker compose up -d`
2. **Abrir pgweb** en `http://localhost:8081` para explorar y probar queries.
3. **Cuando tengas un cambio de esquema listo**, guardalo en un archivo nuevo en `migrations/` con el proximo numero (ej: `001_create_tabla_x.sql`).
4. **Probar localmente**: `./scripts/migrate.sh` (o `./scripts/reset-db.sh` para empezar de cero).
5. **Subir los cambios**:
   ```bash
   git checkout -b feat/nombre-descriptivo
   git add migrations/001_create_tabla_x.sql
   git commit -m "feat: crear tabla X"
   git push -u origin feat/nombre-descriptivo
   ```
6. **Abrir un Pull Request** en GitHub para que al menos otro miembro revise.
7. **Al mergear a `main`**, GitHub Actions aplica las migraciones a Supabase automaticamente.

### Al terminar la sesion

```bash
docker compose down
```

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
| `./scripts/setup.sh` | Setup completo (primera vez) |
| `./scripts/migrate.sh` | Ejecuta todas las migraciones pendientes |
| `./scripts/seed.sh` | Carga los datos de prueba |
| `./scripts/reset-db.sh` | Resetea la base completa (drop + create + migrate + seed) |
| `psql -h localhost -p 5432 -U postgres -d tbd_tfi` | Conectarse a la base local |
| `http://localhost:8081` | pgweb -- cliente SQL en el navegador |
| Push a `main` con cambios en `migrations/` | GitHub Actions aplica migraciones a Supabase |
