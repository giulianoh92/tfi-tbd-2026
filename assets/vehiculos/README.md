# Imágenes de la flota

Este directorio contiene las imágenes de stock que la base de datos referencia desde la tabla `imagen_vehiculo`. La columna `url_imagen` apunta a `https://raw.githubusercontent.com/giulianoh92/tfi-tbd-2026/main/assets/vehiculos/<carpeta>/<archivo>`, así que **las imágenes se sirven directamente desde el repo público** sin necesidad de hosting externo.

Si alguien clona el repo y aplica el schema, los URLs se resuelven automáticamente al subirse las imágenes acá.

## Estructura esperada

Una carpeta por vehículo, **5 archivos** cada una (3 exteriores + 2 interiores). El seed `schema/05_seeds/09_imagen_vehiculo.sql` ya inserta exactamente esas URLs.

```
assets/vehiculos/
├── v01-fiat-cronos/
│   ├── exterior-01.jpg
│   ├── exterior-02.jpg
│   ├── exterior-03.jpg
│   ├── interior-01.jpg
│   └── interior-02.jpg
├── v02-toyota-corolla/
│   └── (mismo patrón)
... (10 vehículos)
```

## Tabla de archivos requeridos

| Vehículo (id) | Marca + modelo | Año | Sucursal de origen | Carpeta | Archivos esperados |
|---|---|---|---|---|---|
| 1  | Fiat Cronos Drive 1.3       | 2023 | Posadas      | `v01-fiat-cronos/`      | exterior-01..03.jpg + interior-01..02.jpg |
| 2  | Toyota Corolla XEi 2.0      | 2024 | Posadas      | `v02-toyota-corolla/`   | exterior-01..03.jpg + interior-01..02.jpg |
| 3  | Volkswagen Gol Trend 1.6    | 2021 | Oberá        | `v03-vw-gol-trend/`     | exterior-01..03.jpg + interior-01..02.jpg |
| 4  | Chevrolet Onix LT 1.2       | 2022 | Oberá        | `v04-chevrolet-onix/`   | exterior-01..03.jpg + interior-01..02.jpg |
| 5  | Toyota Hilux SRX 4x4        | 2024 | Oberá        | `v05-toyota-hilux/`     | exterior-01..03.jpg + interior-01..02.jpg |
| 6  | Jeep Renegade Sport         | 2023 | Iguazú       | `v06-jeep-renegade/`    | exterior-01..03.jpg + interior-01..02.jpg |
| 7  | Toyota SW4 SRX 4x4          | 2024 | Iguazú       | `v07-toyota-sw4/`       | exterior-01..03.jpg + interior-01..02.jpg |
| 8  | Renault Kangoo Express      | 2022 | Corrientes   | `v08-renault-kangoo/`   | exterior-01..03.jpg + interior-01..02.jpg |
| 9  | Ford Ranger XLT 4x4         | 2023 | Corrientes   | `v09-ford-ranger/`      | exterior-01..03.jpg + interior-01..02.jpg |
| 10 | Volkswagen T-Cross Highline | 2024 | Resistencia  | `v10-vw-tcross/`        | exterior-01..03.jpg + interior-01..02.jpg |

Total: **50 imágenes** (10 vehículos × 5 archivos).

## Convención de naming

- **Minúsculas**, separación con guiones medios (`-`), sin acentos ni espacios.
- Extensión `.jpg` para todos (uniformidad). Si solo conseguís `.png` o `.webp`, ajustá también la URL en `09_imagen_vehiculo.sql` para que coincida.
- Numeración con cero a la izquierda (`exterior-01.jpg`, no `exterior-1.jpg`) para que el orden lexicográfico coincida con el orden lógico.

## Fuentes recomendadas (en orden de preferencia)

### 1. Wikimedia Commons → https://commons.wikimedia.org/

Mejor opción para modelos específicos. Tiene fotos de prácticamente todos los modelos populares de Argentina con licencia compatible (CC BY-SA, CC0, Public Domain).

**Cómo usar:**
1. Buscá el modelo exacto, ej. `Fiat Cronos 2023`.
2. Verificá la licencia en la página del archivo (debe decir CC BY, CC BY-SA, CC0 o Public Domain).
3. Descargá el archivo en su mayor resolución.
4. **Atribuí al autor**: agregá una línea en este README al final con: `<archivo>: foto por <autor>, licencia <CC...>, fuente <URL Wikimedia>`.

### 2. Sitios de prensa oficiales de las marcas

Las automotrices suelen tener salas de prensa con imágenes de uso libre para fines editoriales/educativos:

- Toyota: https://www.toyota.com.ar/prensa
- Ford: https://www.ford.com.ar/prensa
- Volkswagen: https://www.vw.com.ar/prensa
- Fiat: https://www.fiat.com.ar/prensa
- Chevrolet, Jeep, Renault: equivalentes en sus sitios `.com.ar`

**Cuidado**: muchos sitios piden registro como periodista. Para un TFI académico, suele bastar con identificar el uso educativo en el README. Si la marca exige atribución explícita, agregala acá.

### 3. Unsplash / Pexels → https://unsplash.com/, https://pexels.com/

Licencia CC0 (uso libre, sin atribución requerida). El problema es que **rara vez tienen fotos del modelo exacto** — vas a encontrar "un Toyota SUV blanco" pero no necesariamente el SW4 SRX 4x4 2024. Sirve si querés imágenes lindas sacrificando fidelidad al modelo.

### 4. Página de cada concesionaria

Última opción, **riesgosa por copyright**. Las fotos del catálogo de un concesionario suelen ser del fabricante y bajarlas viola TOS. No recomendado.

## Calidad mínima sugerida

- **Resolución**: mínimo 1200×800 px para exteriores, 1000×700 px para interiores. La UI de Etapa 3 va a renderizar a varios tamaños y necesita una fuente con suficiente detalle.
- **Formato**: JPG con calidad 80-90% para balancear tamaño/calidad. Evitá PNG salvo que tengas transparencias (que no necesitás acá).
- **Peso por archivo**: idealmente <500 KB. GitHub permite hasta 100 MB por archivo, pero el repo se vuelve pesado de clonar si te excedés. Si las imágenes pesan mucho, optimizá con `https://squoosh.app/` o `mozjpeg`.
- **Orientación**: paisaje (más ancho que alto) para los exteriores. Interiores pueden ser paisaje o vertical según el plano (vista de tablero suele ser paisaje, vista de asientos puede ser vertical).
- **Encuadre exteriores**:
  - `exterior-01.jpg`: vista frontal 3/4 (clásico catálogo)
  - `exterior-02.jpg`: lateral completo
  - `exterior-03.jpg`: trasera 3/4
- **Encuadre interiores**:
  - `interior-01.jpg`: tablero + volante + multimedia
  - `interior-02.jpg`: asientos / vista cabina

## Atribuciones

> A medida que vayan agregando imágenes con licencia que lo requiera, dejen una línea acá. Formato:
> `vXX/<archivo>.jpg`: foto por **<autor>**, licencia **<CC...>**, fuente **<URL>**.

*(Sin entradas todavía — completar al subir cada imagen)*

## Workflow recomendado

1. Tomar la tabla de "archivos requeridos" arriba como checklist.
2. Para cada vehículo, buscar 5 imágenes que respeten el encuadre sugerido.
3. Renombrar siguiendo la convención (`exterior-01.jpg` etc.).
4. Soltar en la carpeta `vNN-marca-modelo/` correspondiente.
5. Si la licencia exige atribución, completar la sección "Atribuciones".
6. Borrar el `.gitkeep` de cada carpeta cuando tenga las 5 imágenes (opcional).
7. Commit + push. El CI de schema ignora completamente estos archivos — solo el schema corre en GitHub Actions.

## ¿Y si no llegamos a conseguir las 50 imágenes a tiempo?

Sin problema: la base de datos guarda las URLs y el constraint sólo exige entre 1 y 5 imágenes por vehículo. Los URLs ya están en el seed apuntando a archivos que pueden no existir todavía — el `apply.sh` no verifica HTTP. Cuando la UI de Etapa 3 quiera mostrar la imagen y el archivo no exista, `raw.githubusercontent.com` devolverá 404 y se mostrará un placeholder.

Estrategia mínima viable: 1 imagen exterior por vehículo (10 imágenes total) y dejar las otras 4 por vehículo apuntando a URLs que retornen 404. La cátedra ve el modelo de datos correcto y el equipo completa las imágenes después.
