# TBD - Trabajo Final Integrador

Base de datos PostgreSQL con entorno local en Docker, cliente SQL en el navegador (pgweb) y deploy automatico a Supabase via GitHub Actions.

---

## Stack

| Herramienta | Que es |
|---|---|
| **PostgreSQL** | Motor de base de datos relacional. |
| **Docker** | Corre la base local en un contenedor aislado. |
| **pgweb** | Cliente SQL en el navegador (`localhost:8081`). |
| **Supabase** | PostgreSQL en la nube (entorno compartido del equipo). |
| **Git + GitHub** | Control de versiones y revision via PRs. |
| **GitHub Actions** | Deploy automatico a Supabase al mergear a `main`. |
| **GitHub Desktop** | (Opcional) GUI para Git. |

---

## Inicio rapido

### Opcion A: terminal

```bash
git clone https://github.com/giulianoh92/tfi-tbd-2026.git
cd tfi-tbd-2026
./scripts/setup.sh
```

### Opcion B: GitHub Desktop

1. **File > Clone Repository** > pega la URL del repo.
2. **Repository > Open in Terminal** y ejecuta `./scripts/setup.sh`.

Al terminar, abri **http://localhost:8081** en el navegador.

> `setup.sh` crea el `.env`, levanta Docker y aplica el schema completo.

---

## Requisitos previos

- **Docker** y **Docker Compose** v2+ -- [Descargar](https://www.docker.com/products/docker-desktop/)
- **Git** -- [Descargar](https://git-scm.com/downloads)
- (Opcional) **psql**, **GitHub Desktop**

### Windows (WSL2 + Docker Desktop)

Si estas en Windows, todo se corre desde una terminal WSL2 (Ubuntu). **No uses PowerShell ni CMD** para ejecutar los scripts.

#### 1. Instalar WSL2

Abri **PowerShell como administrador** (click derecho > "Ejecutar como administrador") y ejecuta:

```powershell
wsl --install
```

Esto instala WSL2 con Ubuntu por defecto. **Reinicia la PC** cuando te lo pida. Al reiniciar, se abre una ventana de Ubuntu que te pide crear un usuario y contraseña (son para Linux, no para Windows).

> Si ya tenes WSL pero no es version 2, ejecuta `wsl --set-default-version 2` para actualizar.

#### 2. Instalar Docker Desktop

Descarga e instala [Docker Desktop](https://www.docker.com/products/docker-desktop/). Despues de instalar:

1. Abri Docker Desktop.
2. Anda a **Settings > Resources > WSL Integration**.
3. Activa la integracion con tu distro Ubuntu.
4. Hace click en **Apply & Restart**.

#### 3. Instalar Git dentro de WSL

Abri la terminal de Ubuntu (busca "Ubuntu" en el menu inicio) y ejecuta:

```bash
sudo apt update && sudo apt install -y git
```

#### 4. Seguir el setup normal

Desde la misma terminal de Ubuntu, segui las instrucciones de [Inicio rapido](#inicio-rapido) de arriba.

> Los scripts `.sh`, `docker compose`, y `localhost` funcionan igual desde WSL2. El `.gitattributes` del repo garantiza que los archivos mantengan line endings Unix (LF) aunque Git este configurado en Windows.

---

## Uso diario

```bash
docker compose up -d              # levantar entorno
# editar archivos en schema/
./scripts/deploy.sh               # drop + recreate local
git checkout -b feat/mi-cambio    # branch nuevo
# commit, push, abrir PR
docker compose down               # al terminar
```

`deploy.sh` borra el schema public, lo recrea y aplica todos los `.sql` en orden. Se puede ejecutar todas las veces que quieras.

Ver [`CONTRIBUTING.md`](./CONTRIBUTING.md) para convenciones de branches, commits y PRs.

---

## Estructura del schema

Enfoque **drop + recreate**: cada deploy borra el schema public y lo reconstruye desde los archivos. Sin migraciones incrementales -- editas el archivo directamente.

```
tfi-tbd-2026/
├── schema/
│   ├── 00_extensions.sql      # Extensiones de PostgreSQL
│   ├── 01_tables/             # CREATE TABLE (un archivo por tabla)
│   ├── 02_constraints/        # Foreign keys y constraints
│   ├── 03_indexes/            # Indices
│   ├── 04_functions/          # Funciones, triggers, vistas
│   ├── 05_seeds/              # Datos de prueba
│   └── 06_permissions/        # Roles, GRANT, REVOKE
├── scripts/                   # setup.sh, deploy.sh
├── tests/
├── docker-compose.yml
└── .env.example
```

### Orden de ejecucion

Los archivos se aplican en el orden numerico de las carpetas (`00_` -> `06_`) y, dentro de cada carpeta, alfabeticamente. Por eso los archivos `.sql` tambien llevan prefijo numerico (ej: `01_clientes.sql`, `02_pedidos.sql`). Detalle completo en [`CONTRIBUTING.md`](./CONTRIBUTING.md).

---

## Deploy a Supabase

Al mergear a `main` con cambios en `schema/`, GitHub Actions corre el mismo `drop + recreate` contra Supabase.

### Setup del CI (una vez, lo hace el admin)

1. Supabase Dashboard > **Project Settings > Database** > copia el **Connection String** (URI).
2. GitHub > **Settings > Secrets and variables > Actions** > crea el secret `SUPABASE_DB_URL`.

### Conectarse a Supabase remoto

Desde cualquier cliente SQL (psql, DBeaver, DataGrip) usando el connection string del Dashboard. **No commitees credenciales** -- guardalas en `.env`.

---

## Comandos utiles

| Comando | Que hace |
|---------|----------|
| `docker compose up -d` | Levanta base de datos y pgweb |
| `docker compose down` | Para containers (datos persisten) |
| `docker compose down -v` | Para containers Y borra los datos |
| `docker compose ps` | Estado de los containers |
| `docker compose logs db` | Ver logs de PostgreSQL |
| `./scripts/setup.sh` | Setup completo (primera vez) |
| `./scripts/deploy.sh` | Drop + recreate del schema |
| `psql -h localhost -p 5432 -U postgres -d tbd_tfi` | Conectarse por terminal |

### Equivalencias terminal / GitHub Desktop

| Accion | Terminal | GitHub Desktop |
|--------|----------|---------------|
| Crear branch | `git checkout -b feat/...` | Barra superior > New Branch |
| Commitear | `git add ... && git commit -m "..."` | Seleccionar archivos + mensaje + Commit |
| Subir cambios | `git push -u origin feat/...` | Push origin / Publish branch |
| Abrir PR | Link del push | Boton "Create Pull Request" |
| Traer cambios | `git pull origin main` | Fetch origin > Pull origin |
| Actualizar branch | `git merge main` | Branch > Update from main |

---

## Troubleshooting

**Puerto ocupado.** Cambia `POSTGRES_PORT` o `PGWEB_PORT` en `.env` y volve a `docker compose up -d`.

**pgweb no carga.** Espera unos segundos (arranca despues de PostgreSQL). Verifica con `docker compose ps` y `docker compose logs pgweb`.

**Permission denied en scripts.** `chmod +x scripts/*.sh`.

**Windows: scripts no corren.** Asegurate de estar en una terminal **WSL2 (Ubuntu)**, no PowerShell ni CMD. Si clonaste desde Windows, los line endings pueden estar mal -- borra y volve a clonar desde WSL2.

**Falla por orden de dependencias.** Revisa los prefijos numericos de los `.sql`. Las FKs van en `02_constraints/`, no dentro del `CREATE TABLE`.

**Setup manual (si `setup.sh` falla):**

```bash
cp .env.example .env
docker compose up -d
./scripts/deploy.sh
```
