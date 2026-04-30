# Convenciones del equipo

Guia rapida de como trabajamos en este repo. Leela una vez y consultala cuando tengas dudas.

---

## Como contribuir

El repo esta pensado para que **cualquiera pueda aportar sin instalar nada**: github.dev (`.` en cualquier URL del repo) abre un VS Code en el navegador. Editas, commiteas y pusheas todo desde ahi.

### Push directo a `main`

**No usamos Pull Requests.** Pushea directo a `main`. La validacion ocurre en CI:

1. Push dispara el workflow `Deploy Schema to Supabase`.
2. Job **`validate`**: levanta un Postgres efimero en GitHub y aplica el schema completo. Si algun `.sql` esta roto (sintaxis, FK invalida, constraint violado por un seed), falla aca.
3. Solo si `validate` pasa, corre el job **`deploy`** contra Supabase.

Si rompes `validate`, Supabase **nunca se entera**. Quedate tranquilo: el peor caso es ver una corrida en rojo en la pestana Actions y empujar otro commit con la correccion.

### Cuando si abrir un branch + PR

Aunque `main` esta abierto, hay casos donde abrir un branch tiene sentido:

- Cambios grandes que queres discutir antes de mergear.
- Trabajo en progreso que no querras que toque Supabase todavia.
- Experimentos que probablemente revertas.

Para esos casos: branch nuevo, push, abris PR si queres feedback. Una vez listo, mergeas vos mismo.

### Formato de nombres de branch (cuando uses)

```
feat/descripcion-corta
fix/descripcion-corta
```

Guiones, minusculas, sin espacios.

---

## Archivos de schema

Usamos un enfoque de **drop + recreate**: cada deploy borra el schema public y lo reconstruye completo. Esto significa que podes **editar los archivos directamente** -- ese es el punto. No hay migraciones incrementales.

### Donde va cada cosa

| Carpeta | Que va | Convencion de nombre |
|---------|--------|---------------------|
| `schema/01_tables/` | `CREATE TABLE` | Un archivo por tabla con prefijo numerico: `01_clientes.sql`, `02_pedidos.sql` |
| `schema/02_constraints/` | Foreign keys y constraints | Un archivo por FK o agrupados, con prefijo: `01_fk_pedidos.sql` |
| `schema/03_indexes/` | Indices | Con prefijo: `01_idx_clientes_email.sql` |
| `schema/04_functions/` | Funciones, triggers, vistas | Con prefijo: `01_fn_calcular_total.sql` |
| `schema/05_seeds/` | Datos de prueba | Con prefijo, mismo orden que las tablas: `01_clientes.sql`, `02_pedidos.sql` |
| `schema/06_permissions/` | Roles, GRANT, REVOKE | Con prefijo: `01_roles.sql`, `02_grants.sql` |

> **Importante:** tanto las carpetas (`01_tables/`, `02_constraints/`, ...) **como los archivos SQL dentro de ellas** llevan prefijo numerico de dos digitos. La carpeta define el orden entre etapas; el prefijo del archivo define el orden dentro de la etapa. Sin el prefijo, el deploy puede romper por dependencias resueltas en orden incorrecto.

### Reglas

1. **Edita el archivo directamente.** Si necesitas agregar una columna a la tabla `clientes`, editas `schema/01_tables/clientes.sql`. No crees un archivo separado tipo "alter table". Ese es el punto del enfoque drop + recreate.

2. **Un archivo por tabla en `01_tables/`.** Mantiene todo organizado y facilita revisar diffs.

3. **Foreign keys en `02_constraints/`, no en `01_tables/`.** Asi evitas problemas de dependencias circulares entre tablas.

4. **Usa `IF NOT EXISTS` / `CREATE OR REPLACE` donde sea posible** como red de seguridad adicional, aunque el schema siempre se recrea desde cero.

5. **Seeds usan `INSERT INTO ... VALUES` simple.** No hace falta `ON CONFLICT` ni `UPSERT` porque el schema siempre esta fresco.

6. **Prefijos numericos obligatorios en archivos SQL.** Los archivos dentro de cada carpeta se ejecutan en orden alfabetico, asi que **todo `.sql` debe arrancar con prefijo de dos digitos** (`01_`, `02_`, ...). No es opcional ni "solo si hace falta": el orden de ejecucion siempre importa (FKs, seeds que dependen de otras tablas, indices sobre columnas que existen, etc.). Dejar huecos entre numeros (ej: `01_`, `05_`, `10_`) es buena idea para poder insertar archivos despues sin renumerar todo.

7. **Si tenes entorno local, proba antes de pushear.** `./scripts/deploy.sh` aplica el schema contra Docker. Si no tenes entorno local (trabajas desde github.dev), no es obligatorio: el CI hace la misma validacion en su Postgres efimero.

---

## Commits

Manten los mensajes simples y descriptivos. En espanol esta bien.

**Buenos ejemplos:**

- `crear tabla pedidos con FK a clientes`
- `agregar index en pedidos.fecha`
- `corregir tipo de dato en clientes.telefono`
- `agregar seed data para tabla productos`

**Malos ejemplos:**

- `cambios` (no dice nada)
- `asdasd` (no)
- `WIP` (si no esta listo, no lo pushees a main)

No hace falta seguir ningun formato tipo "Conventional Commits". Lo importante es que cualquiera pueda leer el mensaje y entender que hiciste.

---

## Que pasa si rompo el deploy

1. Mira la pestana **Actions** del repo en GitHub. La corrida en rojo te muestra el job que fallo.
2. Si fallo `validate`: Supabase no se toco. Solo arregla el `.sql`, push, y la proxima corrida deberia pasar.
3. Si fallo `deploy` (raro, porque ya paso validate): Supabase puede haber quedado en estado parcial. Pushea otro commit (aunque sea trivial) o re-disparas el workflow desde Actions con **Run workflow** -- el `drop + recreate` deja todo limpio de nuevo.
4. **Tambien llega un mensaje al canal de Discord** del equipo con el motivo del error y un link a la corrida.

---

## Resumen rapido

| Que | Como |
|-----|------|
| Editar sin entorno local | github.dev (apretas `.` en el repo) |
| Push | Directo a `main` |
| Validacion | Automatica en CI antes de tocar Supabase |
| Branches | Solo si queres aislar trabajo en progreso |
| Archivos de schema | Editar directamente en `schema/` (ese es el punto) |
| Prefijos numericos | Obligatorios en carpetas **y** en archivos `.sql` |
| Tablas | Un archivo por tabla en `schema/01_tables/` |
| FKs y constraints | En `schema/02_constraints/` |
| Commits | En espanol, descriptivos, sin formato rigido |
| Si rompo el deploy | Lo arreglo y vuelvo a pushear, miro Actions y Discord |
