# Convenciones del equipo

Guia rapida de como trabajamos en este repo. Leela una vez y consultala cuando tengas dudas.

---

## Branches

Siempre trabaja en un branch propio. **Nunca commitees directo a `main`.**

### Formato de nombres

```
feat/descripcion-corta
fix/descripcion-corta
```

Ejemplos:

- `feat/crear-tabla-pedidos`
- `feat/agregar-index-clientes-email`
- `fix/corregir-fk-pedidos-clientes`

Usa guiones (`-`) para separar palabras. Todo en minusculas. Sin espacios.

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

2. **Un archivo por tabla en `01_tables/`.** Mantiene todo organizado y facilita los code reviews.

3. **Foreign keys en `02_constraints/`, no en `01_tables/`.** Asi evitas problemas de dependencias circulares entre tablas.

4. **Usa `IF NOT EXISTS` / `CREATE OR REPLACE` donde sea posible** como red de seguridad adicional, aunque el schema siempre se recrea desde cero.

5. **Seeds usan `INSERT INTO ... VALUES` simple.** No hace falta `ON CONFLICT` ni `UPSERT` porque el schema siempre esta fresco.

6. **Prefijos numericos obligatorios en archivos SQL.** Los archivos dentro de cada carpeta se ejecutan en orden alfabetico, asi que **todo `.sql` debe arrancar con prefijo de dos digitos** (`01_`, `02_`, ...). No es opcional ni "solo si hace falta": el orden de ejecucion siempre importa (FKs, seeds que dependen de otras tablas, indices sobre columnas que existen, etc.). Dejar huecos entre numeros (ej: `01_`, `05_`, `10_`) es buena idea para poder insertar archivos despues sin renumerar todo.

7. **Proba localmente antes de pushear.** Ejecuta `./scripts/deploy.sh` para verificar que todo funciona.

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
- `WIP` (si no esta listo, no lo pushees)

No hace falta seguir ningun formato tipo "Conventional Commits". Lo importante es que cualquiera pueda leer el mensaje y entender que hiciste.

---

## Pull Requests

### Reglas

- Todo cambio a `main` pasa por Pull Request. No se mergea sin review.
- Necesitas **al menos 1 aprobacion** de otro miembro del equipo.
- El titulo del PR tiene que ser descriptivo (ej: "Crear tabla pedidos con FK a clientes").
- Si tu cambio depende de otro PR que todavia no fue mergeado, aclara eso en la descripcion del PR.

### Como abrir un PR

**Desde GitHub Desktop:** despues de hacer push, aparece el boton **Create Pull Request**.

**Desde la terminal:** cuando haces `git push`, la salida te muestra un link para crear el PR.

**Desde el navegador:** anda al repo en GitHub > **Pull Requests > New Pull Request** > selecciona tu branch.

### Review

Cuando te pidan review:

- Mira el SQL. Verifica que tenga sentido, que los tipos de datos sean correctos, que las FK apunten bien.
- Si tenes dudas, pregunta en el PR (deja un comentario).
- Si esta todo bien, aprobalo.

---

## Resumen rapido

| Que | Como |
|-----|------|
| Nombre de branch | `feat/descripcion` o `fix/descripcion` |
| Archivos de schema | Editar directamente en `schema/` (ese es el punto) |
| Prefijos numericos | Obligatorios en carpetas **y** en archivos `.sql` (ej: `01_clientes.sql`) |
| Tablas | Un archivo por tabla en `schema/01_tables/`, con prefijo numerico |
| FKs y constraints | En `schema/02_constraints/`, con prefijo numerico |
| Commits | En espanol, descriptivos, sin formato rigido |
| PRs | Titulo descriptivo, 1 aprobacion minima |
| Antes de pushear | `./scripts/deploy.sh` |
