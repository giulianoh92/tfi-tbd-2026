# Convenciones del equipo

Reglas tecnicas para el contenido del repo. Si lo que necesitas saber es **como trabajar dia a dia**, esta en el [README](./README.md) — leelo primero.

---

## Que va en cada carpeta

| Carpeta | Que va | Convencion de nombre |
|---|---|---|
| `schema/01_tables/` | `CREATE TABLE` | Un archivo por tabla, con prefijo: `01_clientes.sql`, `02_pedidos.sql` |
| `schema/02_constraints/` | Foreign keys y constraints multi-columna | Con prefijo: `01_fk_pedidos.sql` |
| `schema/03_indexes/` | Indices | `01_idx_clientes_email.sql` |
| `schema/04_functions/` | Funciones, triggers, vistas | `01_fn_calcular_total.sql`, `02_vw_listado_xxx.sql` |
| `schema/05_seeds/` | Datos de prueba (`INSERT INTO`) | `01_clientes.sql`, `02_pedidos.sql` |
| `schema/06_permissions/` | Roles, GRANT, REVOKE | `01_roles.sql`, `02_grants.sql` |

> [!important]
> **Prefijos numericos obligatorios.** Tanto las carpetas (`01_tables/`, `02_constraints/`, ...) como los archivos `.sql` dentro de ellas arrancan con dos digitos. La carpeta define el orden entre etapas; el prefijo del archivo, el orden dentro de la etapa. Sin el prefijo, el deploy puede romper por dependencias resueltas en orden incorrecto.

---

## Reglas para escribir SQL

1. **Edita el archivo directamente.** Si necesitas agregar una columna, modificas el `CREATE TABLE` que ya existe. **No crees archivos tipo "alter table"** — el esquema se reconstruye desde cero en cada deploy, asi que no hay migraciones incrementales.

2. **Foreign keys en `02_constraints/`, no en `01_tables/`.** Asi se evitan dependencias circulares entre tablas y el orden de creacion no importa.

3. **Usa `IF NOT EXISTS` y `CREATE OR REPLACE`** donde se pueda. Es red de seguridad adicional.

4. **Seeds usan `INSERT INTO ... VALUES` simple.** Sin `ON CONFLICT` ni `UPSERT` — la base esta siempre fresca.

5. **Deja huecos en los prefijos** (ej: `01_`, `05_`, `10_` en vez de `01_`, `02_`, `03_`). Asi podes insertar archivos despues sin renumerar todo.

---

## Commits

Mensajes simples y descriptivos. **En espanol esta bien.**

**Buenos:**
- `crear tabla pedidos con FK a clientes`
- `agregar index en pedidos.fecha`
- `corregir tipo de dato en clientes.telefono`
- `agregar seed data para tabla productos`

**Malos:**
- `cambios` (no dice nada)
- `WIP` (si no esta listo, no lo pushees)
- `asdasd`

No usamos Conventional Commits ni ningun formato rigido. Lo unico que importa es que cualquiera lo lea y entienda que hiciste.

---

## Branches: opcionales

Trabajamos directo sobre `main`. **No hace falta abrir branches ni Pull Requests** — la red de seguridad es el CI, no la revision humana.

Las branches solo tienen sentido en casos especificos:
- Cambios grandes que querras discutir antes de mergear.
- Trabajo en progreso que no querras que toque Supabase todavia.
- Experimentos que probablemente revertas.

Si abris un branch, usa el formato `feat/descripcion-corta` o `fix/descripcion-corta`, en minusculas, con guiones.

---

## Que hago si el deploy falla

1. **Mira la pestana [Actions](https://github.com/giulianoh92/tfi-tbd-2026/actions) o el canal de Discord** del equipo. Vas a tener el job que fallo y la cola del log con el error.

2. **Si fallo `validate`:** Supabase no se toco. Solo arregla el `.sql` y vuelve a pushear. La proxima corrida deberia pasar.

3. **Si fallo `deploy` (raro):** Supabase puede haber quedado con el esquema parcialmente aplicado. Pushea otro commit (aunque sea trivial) o re-disparas el workflow desde la pestana Actions con **Run workflow** — el `drop + recreate` deja todo limpio de nuevo.

---

## Resumen rapido

| Que | Como |
|---|---|
| Editar archivos | github.dev (apretas `.` en el repo) |
| Push | Directo a `main` |
| Validacion | Automatica en CI (Postgres efimero) antes de tocar Supabase |
| Branches y PRs | Opcionales, solo para experimentos o trabajo en progreso |
| Prefijos en archivos `.sql` | Obligatorios, dos digitos |
| FKs y constraints | En `schema/02_constraints/`, no en `01_tables/` |
| Commits | Espanol, descriptivos, sin formato rigido |
| Si rompo el deploy | Lo arreglo y pusheo de nuevo, miro Actions y Discord |
