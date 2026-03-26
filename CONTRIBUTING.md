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

## Migraciones

### Nombre del archivo

```
NNN_descripcion.sql
```

El numero `NNN` es secuencial y de tres digitos. Ejemplos:

- `000_extensions.sql`
- `001_create_tabla_clientes.sql`
- `002_create_tabla_pedidos.sql`

### Reglas de oro

1. **NUNCA modifiques una migracion que ya fue mergeada a `main`.** Si necesitas cambiar algo, crea una migracion nueva (ej: `005_alter_tabla_clientes_add_email.sql`).

2. **Coordina el numero con el equipo.** Antes de crear una migracion, revisa cual es el proximo numero libre en `main`. Si dos personas eligen el mismo numero, una va a tener que renumerar. Avisale al grupo antes de empezar.

3. **Proba localmente antes de pushear.** Ejecuta `./scripts/migrate.sh` para verificar que tu SQL anda. Si queres empezar de cero, usa `./scripts/reset-db.sh`.

4. **Cada migracion debe ser idempotente cuando sea posible.** Usa `CREATE TABLE IF NOT EXISTS`, `DROP TABLE IF EXISTS`, etc. Asi se puede re-ejecutar sin romper nada.

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
- Si tu migracion depende de otra que todavia no fue mergeada, aclara eso en la descripcion del PR.

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
| Nombre de migracion | `NNN_descripcion.sql` |
| Commits | En espanol, descriptivos, sin formato rigido |
| PRs | Titulo descriptivo, 1 aprobacion minima |
| Migracion ya mergeada | NUNCA se modifica, crear una nueva |
| Numero de migracion | Coordinar con el equipo |
| Antes de pushear | `./scripts/migrate.sh` o `./scripts/reset-db.sh` |
