# TBD - Trabajo Final Integrador

Base de datos PostgreSQL con entorno local en Docker, cliente SQL en el navegador (pgweb) y deploy automatico a Supabase via GitHub Actions.

---

## Inicio rapido

Tres pasos para tener todo funcionando:

### Opcion A: desde la terminal

```bash
git clone <url-del-repo>
cd TBD_TFI
./scripts/setup.sh
```

### Opcion B: desde GitHub Desktop

1. Abri GitHub Desktop > **File > Clone Repository** > pega la URL del repo.
2. Abri una terminal en la carpeta del proyecto (en GitHub Desktop: **Repository > Open in Terminal**).
3. Ejecuta `./scripts/setup.sh`

---

Al terminar, abri el navegador en **http://localhost:8081** y ya tenes pgweb listo para escribir SQL.

> El script `setup.sh` crea el `.env`, levanta Docker, aplica migraciones y carga datos de prueba. Todo automatico.

---

## Requisitos previos

- **Docker** y **Docker Compose** (v2+) -- [Descargar Docker Desktop](https://www.docker.com/products/docker-desktop/)
- **Git** -- [Descargar Git](https://git-scm.com/downloads)
- (Opcional) **psql** -- cliente de linea de comandos de PostgreSQL
- (Opcional) **GitHub Desktop** -- [Descargar GitHub Desktop](https://desktop.github.com/)

### Windows (WSL2 + Docker Desktop)

Si estas en Windows, todo se corre desde una terminal WSL2 (Ubuntu). **No uses PowerShell ni CMD** para ejecutar los scripts.

1. Instala [Docker Desktop](https://www.docker.com/products/docker-desktop/) y activa la integracion con WSL2 en **Settings > Resources > WSL Integration**.
2. Instala una distro WSL2 (ej: Ubuntu) desde la Microsoft Store si no tenes una.
3. Abri una terminal WSL2 (`wsl` desde PowerShell o busca "Ubuntu" en el menu inicio).
4. Desde ahi segui el setup normal de arriba.

> Los scripts `.sh`, `docker compose`, y `localhost` funcionan igual desde WSL2. El `.gitattributes` del repo garantiza que los archivos mantengan line endings Unix (LF) aunque Git este configurado en Windows.

---

## Uso diario

### 1. Levantar el entorno

Si Docker no esta corriendo, abrilo primero (Docker Desktop). Despues:

```bash
docker compose up -d
```

### 2. Abrir pgweb

Anda a **http://localhost:8081** en el navegador. Desde ahi podes explorar tablas, ejecutar queries y ver resultados sin instalar nada extra.

### 3. Escribir SQL y probar queries

Usa pgweb para experimentar. Cuando tengas un cambio de esquema listo (tabla nueva, indice, constraint, etc.), guardalo como archivo SQL.

### 4. Guardar la migracion

Crea un archivo nuevo en `migrations/` con el proximo numero disponible:

```
migrations/003_create_tabla_pedidos.sql
```

> Ver la seccion [Trabajar con migraciones](#trabajar-con-migraciones) para la convencion de nombres y reglas.

### 5. Probar localmente

```bash
./scripts/migrate.sh          # aplica migraciones pendientes
# o si queres empezar de cero:
./scripts/reset-db.sh         # borra todo + recrea + migra + seeds
```

### 6. Subir los cambios

**Desde la terminal:**

```bash
git checkout -b feat/nombre-descriptivo
git add migrations/003_create_tabla_pedidos.sql
git commit -m "crear tabla pedidos"
git push -u origin feat/nombre-descriptivo
```

**Desde GitHub Desktop:**

1. Crea un branch nuevo (ver [Guia de GitHub Desktop](#guia-de-github-desktop) abajo).
2. Los archivos modificados aparecen automaticamente en el panel izquierdo.
3. Marca los archivos que queres incluir, escribi un mensaje de commit, y hace click en **Commit**.
4. Hace click en **Push origin** (o **Publish branch** si es la primera vez).

### 7. Abrir un Pull Request

- Desde GitHub Desktop: hace click en **Create Pull Request** (te abre el navegador).
- Desde la terminal: el link aparece en la salida del `git push`.
- Pedi review a al menos un companero.

### 8. Mergear

Una vez aprobado, mergea el PR desde GitHub. **GitHub Actions aplica automaticamente las migraciones a Supabase.**

### 9. Al terminar la sesion

```bash
docker compose down
```

---

## Guia de GitHub Desktop

Si no estas familiarizado con Git por terminal, GitHub Desktop es una alternativa visual que hace lo mismo.

### Instalar y clonar el repo

1. Descarga [GitHub Desktop](https://desktop.github.com/) e instala.
2. Inicia sesion con tu cuenta de GitHub.
3. **File > Clone Repository** > busca el repo o pega la URL > elegí la carpeta destino > **Clone**.

### Crear un branch

Antes de hacer cambios, **siempre crea un branch nuevo**:

1. En la barra superior, hace click en el nombre del branch actual (probablemente `main`).
2. Hace click en **New Branch**.
3. Ponele un nombre descriptivo: `feat/crear-tabla-pedidos`, `fix/corregir-constraint-clientes`.
4. Asegurate de que dice "Create branch based on **main**" > **Create Branch**.

### Ver cambios y commitear

1. Despues de guardar archivos en la carpeta del proyecto, los cambios aparecen en el panel izquierdo de GitHub Desktop.
2. Revisa que los archivos listados sean los correctos (marca/desmarca los checkboxes).
3. Abajo a la izquierda, escribi un **titulo de commit** corto y descriptivo (ej: "crear tabla pedidos").
4. Hace click en **Commit to feat/crear-tabla-pedidos**.

### Push (subir al remoto)

Despues de commitear, hace click en **Push origin** en la barra superior. Si es un branch nuevo, dice **Publish branch**.

### Abrir un Pull Request

Despues de hacer push, GitHub Desktop muestra un boton **Create Pull Request**. Hace click y te lleva al navegador donde podes:

1. Escribir un titulo descriptivo.
2. Agregar una descripcion si es necesario.
3. Pedir review a un companero.

### Sincronizar cambios (pull)

Para traer los ultimos cambios de `main`:

1. Cambia al branch `main` (barra superior > selecciona `main`).
2. Hace click en **Fetch origin** > **Pull origin**.
3. Volve a tu branch de trabajo y hace click en **Update from main** (o **Branch > Update from main** en el menu).

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

1. **Nunca modifiques una migracion que ya fue mergeada a main.** Si necesitas cambiar algo, crea una nueva migracion.
2. **Coordina los numeros con el equipo** antes de crear una migracion nueva, para evitar conflictos. Si dos personas usan el mismo numero, una va a tener que renumerar.
3. **Cada migracion debe ser idempotente cuando sea posible** (usa `IF NOT EXISTS`, `IF EXISTS`, etc.).
4. **Proba localmente antes de pushear.** Usa `./scripts/migrate.sh` o `./scripts/reset-db.sh`.

### Estructura del proyecto

```
TBD_TFI/
├── migrations/     # Archivos SQL de migracion (esquema, tablas, constraints)
├── seeds/          # Datos de prueba / seed data
├── scripts/        # Scripts utilitarios (reset, migrate, seed, setup)
├── tests/          # Tests de base de datos
├── docker-compose.yml
├── .env.example    # Template de variables de entorno
└── README.md
```

| Carpeta | Que va ahi |
|---------|-----------|
| `migrations/` | Archivos `.sql` numerados que definen el esquema. Se ejecutan en orden. Nunca modificar una migracion ya mergeada. |
| `seeds/` | Archivos `.sql` con datos de prueba para desarrollo local. |
| `scripts/` | Scripts de shell para automatizar tareas comunes (resetear la base, correr migraciones, etc.). |
| `tests/` | Tests automatizados sobre la base de datos. |

---

## CI/CD: Migraciones automaticas a Supabase

Al mergear a `main`, un workflow de GitHub Actions aplica automaticamente las migraciones nuevas a la base de Supabase. No hace falta instalar nada ni correr comandos manuales.

El workflow solo se dispara cuando hay cambios en `migrations/`.

### Setup del CI (una sola vez, lo hace el admin del repo)

1. En el Dashboard de Supabase, anda a **Project Settings > Database** y copia el **Connection String** (URI). Reemplaza `[YOUR-PASSWORD]` con la password del proyecto.
2. En GitHub, anda a **Settings > Secrets and variables > Actions**.
3. Crea un secret llamado `SUPABASE_DB_URL` con el connection string como valor.

Listo. A partir de ahora, cada push a `main` que incluya cambios en `migrations/` dispara el workflow automaticamente.

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

### Terminal

| Comando | Que hace |
|---------|----------|
| `docker compose up -d` | Levanta la base de datos y pgweb en background |
| `docker compose down` | Para y elimina los containers (los datos persisten en el volumen) |
| `docker compose down -v` | Para containers Y elimina el volumen (borra todos los datos) |
| `docker compose ps` | Muestra el estado de los containers |
| `docker compose logs db` | Ver logs de PostgreSQL |
| `./scripts/setup.sh` | Setup completo (primera vez) |
| `./scripts/migrate.sh` | Ejecuta todas las migraciones |
| `./scripts/seed.sh` | Carga los datos de prueba |
| `./scripts/reset-db.sh` | Resetea la base completa (drop + create + migrate + seed) |
| `psql -h localhost -p 5432 -U postgres -d tbd_tfi` | Conectarse a la base local por terminal |

### GitHub Desktop (equivalencias)

| Accion | Terminal | GitHub Desktop |
|--------|----------|---------------|
| Clonar repo | `git clone <url>` | File > Clone Repository |
| Crear branch | `git checkout -b feat/...` | Barra superior > New Branch |
| Ver cambios | `git status` / `git diff` | Panel izquierdo (automatico) |
| Commitear | `git add ... && git commit -m "..."` | Seleccionar archivos + mensaje + Commit |
| Subir cambios | `git push -u origin feat/...` | Push origin / Publish branch |
| Abrir PR | Link del push en terminal | Boton "Create Pull Request" |
| Traer cambios | `git pull origin main` | Fetch origin > Pull origin |
| Actualizar branch | `git merge main` | Branch > Update from main |

### pgweb

Abri **http://localhost:8081** en el navegador. Desde ahi podes:

- Explorar tablas y ver su estructura
- Ejecutar queries SQL
- Exportar resultados a CSV

---

## Troubleshooting

### Docker no levanta

- Verifica que **Docker Desktop este abierto y corriendo** (icono en la barra de tareas).
- En Windows: asegurate de que WSL2 este habilitado y la integracion activa en Docker Desktop.

### Puerto ocupado

Si ves un error como `port is already allocated`:

- Cambia el puerto en `.env` (ej: `POSTGRES_PORT=5433` o `PGWEB_PORT=8082`).
- Volve a levantar con `docker compose up -d`.

### Conflicto de numeros de migracion

Si dos personas crearon migraciones con el mismo numero:

- Hablen antes de numerar. Revisen cual es el proximo numero libre en `main`.
- La persona que pusheo despues renumera su archivo y vuelve a commitear.

### pgweb no carga

- Espera unos segundos despues de `docker compose up -d` -- pgweb arranca despues de que PostgreSQL este listo.
- Verifica que los containers esten corriendo: `docker compose ps`.
- Revisa los logs: `docker compose logs pgweb`.

### Permission denied en scripts

```bash
chmod +x scripts/*.sh
```

### Windows: los scripts no corren

- Asegurate de estar en una **terminal WSL2** (Ubuntu), **no en PowerShell ni CMD**.
- Si clonaste el repo desde Windows (no desde WSL2), los line endings pueden estar mal. Borra la carpeta y clona de nuevo desde WSL2.

### Paso a paso manual (si `setup.sh` falla)

```bash
cp .env.example .env              # crear .env
docker compose up -d               # levantar containers
# esperar unos segundos a que PostgreSQL arranque
./scripts/migrate.sh               # aplicar migraciones
./scripts/seed.sh                  # cargar datos de prueba
```
