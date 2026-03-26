# TBD - Trabajo Final Integrador

Base de datos PostgreSQL con entorno local en Docker, cliente SQL en el navegador (pgweb) y deploy automatico a Supabase via GitHub Actions.

---

## Por que trabajamos asi

La materia no exige ninguna herramienta particular para el TFI. Elegimos este stack porque nos permite trabajar en paralelo con entornos locales independientes, tener historial completo de cambios con Git, revisar el trabajo entre pares via Pull Requests, y automatizar el deploy a una base compartida en la nube. El setup se hace una sola vez; despues el dia a dia es escribir SQL en el browser, guardar el archivo y hacer commit.

---

## Herramientas del proyecto

| Herramienta | Que es | Por que la usamos |
|---|---|---|
| **PostgreSQL** | Motor de base de datos relacional open-source. Uno de los mas usados en la industria junto con MySQL y Oracle. | La materia recomienda Oracle, pero elegimos PostgreSQL para el TFI porque es open-source (no requiere licencias ni cuentas corporativas), corre en Docker sin instalacion, tiene soporte nativo en Supabase para colaborar en la nube, y cubre todo lo que necesitamos: funciones, triggers, vistas materializadas, procedimientos almacenados y permisos. La sintaxis SQL es practicamente la misma y los conceptos son transferibles a cualquier motor. |
| **Docker** | Plataforma que permite correr aplicaciones en contenedores aislados, sin instalar nada directamente en tu sistema. | Cada integrante levanta su propia base de datos local con un solo comando, sin instalar PostgreSQL ni configurar nada. Todos trabajan con el mismo entorno. |
| **pgweb** | Cliente SQL web liviano. Se abre en el navegador y permite ejecutar queries, explorar tablas y ver resultados. | Elimina la necesidad de instalar un cliente de base de datos. Se levanta junto con Docker y esta listo para usar en `localhost:8081`. |
| **Supabase** | Plataforma cloud que ofrece una base de datos PostgreSQL accesible desde internet, con dashboard y API. | Funciona como entorno compartido del equipo. Todos pueden ver el estado actual del schema sin levantar nada en local. El profesor tambien puede acceder. |
| **Git** | Sistema de control de versiones. Registra cada cambio que se hace al codigo y permite trabajar en paralelo sin pisarse. | Permite que varios integrantes trabajen al mismo tiempo en archivos distintos, con historial completo de quien cambio que y cuando. |
| **GitHub** | Plataforma web que aloja repositorios Git y agrega herramientas de colaboracion (Pull Requests, Issues, Actions). | Es donde vive el repo del equipo. Los PRs permiten revisar cambios antes de aplicarlos, y GitHub Actions automatiza el deploy a Supabase. |
| **GitHub Desktop** | Aplicacion de escritorio que ofrece una interfaz grafica para Git, sin necesidad de usar la terminal. | Alternativa visual para los integrantes que no estan familiarizados con la linea de comandos. Permite clonar, commitear, pushear y abrir PRs con clicks. |
| **GitHub Actions** | Sistema de CI/CD integrado en GitHub. Ejecuta tareas automaticas cuando ocurren eventos en el repositorio (ej: push a main). | Al mergear un PR a main, aplica automaticamente los cambios del schema a Supabase. Nadie tiene que correr nada manual. |

---

## Inicio rapido

Tres pasos para tener todo funcionando:

### Opcion A: desde la terminal

```bash
git clone https://github.com/giulianoh92/tfi-tbd-2026.git
cd tfi-tbd-2026
./scripts/setup.sh
```

### Opcion B: desde GitHub Desktop

1. Abri GitHub Desktop > **File > Clone Repository** > pega la URL del repo.
2. Abri una terminal en la carpeta del proyecto (en GitHub Desktop: **Repository > Open in Terminal**).
3. Ejecuta `./scripts/setup.sh`

---

Al terminar, abri el navegador en **http://localhost:8081** y ya tenes pgweb listo para escribir SQL.

> El script `setup.sh` crea el `.env`, levanta Docker y despliega el schema completo (drop + recreate). Todo automatico.

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

Usa pgweb para experimentar. Cuando tengas un cambio de esquema listo (tabla nueva, indice, constraint, etc.), guardalo como archivo SQL en la carpeta correspondiente de `schema/`.

### 4. Editar o crear archivos en schema/

Agrega o edita el archivo SQL en la subcarpeta que corresponda:

```
schema/01_tables/clientes.sql          # tabla nueva
schema/02_constraints/fk_pedidos.sql   # foreign key nueva
schema/03_indexes/idx_clientes_email.sql  # indice nuevo
```

> Ver la seccion [Estructura del schema](#estructura-del-schema) para las convenciones de cada carpeta.

### 5. Probar localmente

```bash
./scripts/deploy.sh          # drop + recreate completo del schema
```

El script borra el schema public, lo recrea, y aplica todos los archivos SQL en orden. Es seguro ejecutarlo todas las veces que quieras -- siempre te deja la base en un estado limpio y consistente.

### 6. Subir los cambios

**Desde la terminal:**

```bash
git checkout -b feat/nombre-descriptivo
git add schema/01_tables/pedidos.sql
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

Una vez aprobado, mergea el PR desde GitHub. **GitHub Actions despliega automaticamente el schema completo a Supabase** (drop + recreate, igual que en local).

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

## Estructura del schema

El enfoque es **drop + recreate**: cada deploy borra el schema public y lo reconstruye completo desde los archivos SQL. Esto es posible porque es una base de datos academica/de prueba donde perder datos en deploy es aceptable.

### Estructura del proyecto

```
tfi-tbd-2026/
├── schema/
│   ├── 00_extensions.sql      # Extensiones de PostgreSQL (uuid-ossp, pgcrypto)
│   ├── 01_tables/             # CREATE TABLE (un archivo por tabla)
│   ├── 02_constraints/        # Foreign keys y constraints
│   ├── 03_indexes/            # Indices
│   ├── 04_functions/          # Funciones, triggers y vistas
│   ├── 05_seeds/              # Datos de prueba (INSERT INTO)
│   └── 06_permissions/        # Roles, GRANT, REVOKE
├── scripts/                   # Scripts utilitarios (deploy, setup)
├── tests/                     # Tests de base de datos
├── docker-compose.yml
├── .env.example               # Template de variables de entorno
└── README.md
```

| Carpeta | Que va ahi |
|---------|-----------|
| `schema/00_extensions.sql` | Extensiones de PostgreSQL. Se ejecuta primero. |
| `schema/01_tables/` | Un archivo `.sql` por tabla (ej: `clientes.sql`, `pedidos.sql`). Solo `CREATE TABLE`. |
| `schema/02_constraints/` | Foreign keys y constraints que dependen de multiples tablas. |
| `schema/03_indexes/` | Indices para optimizar queries. |
| `schema/04_functions/` | Funciones, triggers y vistas. |
| `schema/05_seeds/` | Datos de prueba para desarrollo local. `INSERT INTO ... VALUES`. |
| `schema/06_permissions/` | Roles, permisos (`GRANT`, `REVOKE`). Se ejecuta al final. |
| `scripts/` | Scripts de shell para automatizar tareas comunes. |
| `tests/` | Tests automatizados sobre la base de datos. |

### Orden de ejecucion

El script `deploy.sh` (y el CI) aplican los archivos en este orden estricto:

1. `schema/00_extensions.sql`
2. `schema/01_tables/*.sql` (ordenados alfabeticamente)
3. `schema/02_constraints/*.sql` (ordenados alfabeticamente)
4. `schema/03_indexes/*.sql` (ordenados alfabeticamente)
5. `schema/04_functions/*.sql` (ordenados alfabeticamente)
6. `schema/05_seeds/*.sql` (ordenados alfabeticamente)
7. `schema/06_permissions/*.sql` (ordenados alfabeticamente)

Si necesitas que un archivo se ejecute antes que otro dentro de la misma carpeta, usa un prefijo numerico en el nombre (ej: `01_clientes.sql`, `02_pedidos.sql`).

---

## CI/CD: Deploy automatico a Supabase

Al mergear a `main`, un workflow de GitHub Actions hace un **drop + recreate completo** del schema en Supabase. Es el mismo proceso que `deploy.sh` en local: borra el schema public, lo recrea, y aplica todos los archivos SQL en orden.

El workflow solo se dispara cuando hay cambios en `schema/`.

### Setup del CI (una sola vez, lo hace el admin del repo)

1. En el Dashboard de Supabase, anda a **Project Settings > Database** y copia el **Connection String** (URI). Reemplaza `[YOUR-PASSWORD]` con la password del proyecto.
2. En GitHub, anda a **Settings > Secrets and variables > Actions**.
3. Crea un secret llamado `SUPABASE_DB_URL` con el connection string como valor.

Listo. A partir de ahora, cada push a `main` que incluya cambios en `schema/` dispara el workflow automaticamente.

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
| `./scripts/deploy.sh` | Drop + recreate del schema completo |
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

### Orden de dependencias en el schema

Si un archivo SQL falla porque referencia una tabla que todavia no existe, revisa el orden de ejecucion:

- Las tablas se crean en `01_tables/` y se ordenan alfabeticamente. Si `pedidos` depende de `clientes`, asegurate de que `clientes.sql` se ejecute primero (ej: usa `01_clientes.sql` y `02_pedidos.sql`).
- Las foreign keys van en `02_constraints/`, que se ejecuta despues de todas las tablas. Asi evitas problemas de dependencia circular.

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
./scripts/deploy.sh                # desplegar schema completo
```

---

## Limpieza / Desinstalacion

Si terminaste el proyecto y queres borrar todo, no queda nada repartido por el sistema. Todo vive dentro de Docker y la carpeta del repo.

### Borrar el entorno local

```bash
cd tfi-tbd-2026
docker compose down -v             # para containers y borra los datos
cd ..
rm -rf tfi-tbd-2026                # borra el repo local
```

### Borrar las imagenes de Docker (opcional)

Desde Docker Desktop: **Images** > borrar `postgres:16` y `sosedoff/pgweb`. O por terminal:

```bash
docker rmi postgres:16 sosedoff/pgweb
```

### Desinstalar todo (opcional)

Si instalaste Docker o WSL solo para este proyecto:

- **Docker Desktop:** desinstalar desde el panel de aplicaciones del sistema. Arrastra todo: containers, imagenes, volumenes.
- **WSL2 (Windows):** Settings > Apps > Ubuntu (o la distro que hayas instalado) > Desinstalar.
- **GitHub Desktop:** desinstalar desde el panel de aplicaciones.
