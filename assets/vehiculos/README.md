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

Todas las imágenes fueron obtenidas de Wikimedia Commons. Licencias compatibles con uso público en repositorio académico abierto.

### v01-fiat-cronos

- `v01-fiat-cronos/exterior-01.jpg`: foto por **Maxi-Napo-99** (subida por Just a Man), licencia **CC BY 4.0**, fuente <https://commons.wikimedia.org/wiki/File:2023_Fiat_Cronos_1.3_Drive_(Argentina).jpg>
- `v01-fiat-cronos/exterior-02.jpg`: foto por **Just a Man**, licencia **CC BY 4.0**, fuente <https://commons.wikimedia.org/wiki/File:2022_Fiat_Cronos_1.3_Drive_GSE_(front_view).jpg>
- `v01-fiat-cronos/exterior-03.jpg`: foto por **Just a Man**, licencia **CC BY 4.0**, fuente <https://commons.wikimedia.org/wiki/File:2022_Fiat_Cronos_1.3_Drive_GSE_(rear_view).jpg>
- `v01-fiat-cronos/interior-01.jpg`: foto por **Just a Man**, licencia **CC BY 4.0**, fuente <https://commons.wikimedia.org/wiki/File:2024_Fiat_Cronos_Precision_interior.jpg>
- `v01-fiat-cronos/interior-02.jpg`: foto por **Just a Man**, licencia **CC BY 4.0**, fuente <https://commons.wikimedia.org/wiki/File:2022_Fiat_Cronos_1.3_Drive_GSE_(side_view).jpg>

### v02-toyota-corolla

- `v02-toyota-corolla/exterior-01.jpg`: foto por **AIMHO'S REBELLION 8490s**, licencia **CC BY-SA 4.0**, fuente <https://commons.wikimedia.org/wiki/File:2020_Toyota_Corolla_Altis_1.6_front_view_in_Brunei.jpg>
- `v02-toyota-corolla/exterior-02.jpg`: foto por **AIMHO'S REBELLION 8490s**, licencia **CC BY-SA 4.0**, fuente <https://commons.wikimedia.org/wiki/File:2020_Toyota_Corolla_Altis_1.6_rear_view_in_Brunei.jpg>
- `v02-toyota-corolla/exterior-03.jpg`: foto por **LuvsMG481**, licencia **CC BY-SA 4.0**, fuente <https://commons.wikimedia.org/wiki/File:2022_Toyota_Corolla_Altis_1.8G_Prestige_front.jpg>
- `v02-toyota-corolla/interior-01.jpg`: foto por **AIMHO'S REBELLION 8490s**, licencia **CC BY-SA 4.0**, fuente <https://commons.wikimedia.org/wiki/File:2020_Toyota_Corolla_Altis_1.6_interior_view_in_Brunei.jpg>
- `v02-toyota-corolla/interior-02.jpg`: foto por **AIMHO'S REBELLION 8490s**, licencia **CC BY-SA 4.0**, fuente <https://commons.wikimedia.org/wiki/File:2020-21_Toyota_Corolla_(Corolla_Altis)_1.8_Auto_interior_in_Brunei.jpg>

### v03-vw-gol-trend

- `v03-vw-gol-trend/exterior-01.jpg`: foto por **Maxi-carp-99** (subida por Just a Man), licencia **CC BY-SA 4.0**, fuente <https://commons.wikimedia.org/wiki/File:VW_Gol_Trend_Sportline_1.6_(2016).jpg>
- `v03-vw-gol-trend/exterior-02.jpg`: foto por **Maxi-Napo-99** (subida por Just a Man), licencia **CC BY 4.0**, fuente <https://commons.wikimedia.org/wiki/File:2013_Volkswagen_Gol_1.4_Power,_front.jpg>
- `v03-vw-gol-trend/exterior-03.jpg`: foto por **Maxi-Napo-99** (subida por Just a Man), licencia **CC BY 4.0**, fuente <https://commons.wikimedia.org/wiki/File:2013_Volkswagen_Gol_1.4_Power,_rear.jpg>
- `v03-vw-gol-trend/interior-01.jpg`: foto por **Esmihel Muhammed**, licencia **Pexels License** (uso libre, atribucion opcional), fuente <https://www.pexels.com/photo/the-interior-of-a-volkswagen-passat-15223421/>. Nota: foto generica de tablero VW (Passat) usada como referencia visual; Wikimedia Commons no dispone de fotos del interior del Gol Trend.
- `v03-vw-gol-trend/interior-02.jpg`: foto por **Nicklas** (daslebendesnicklas), licencia **Pexels License** (uso libre, atribucion opcional), fuente <https://www.pexels.com/photo/a-black-steering-wheel-11537268/>. Nota: foto generica de cabina VW moderna usada como referencia visual; Wikimedia Commons no dispone de fotos del interior del Gol Trend.

### v04-chevrolet-onix

- `v04-chevrolet-onix/exterior-01.jpg`: foto por **Chevrolet México** (subida por Andra Febrian), licencia **CC BY 3.0**, fuente <https://commons.wikimedia.org/wiki/File:Chevrolet_Onix_(second_generation,_front_view).jpg>
- `v04-chevrolet-onix/exterior-02.jpg`: foto por **Just a Man**, licencia **CC BY 4.0**, fuente <https://commons.wikimedia.org/wiki/File:2022_Chevrolet_Onix_Plus_1.0_Premier_(side).jpg>
- `v04-chevrolet-onix/exterior-03.jpg`: foto por **NaBUru38**, licencia **CC BY-SA 4.0**, fuente <https://commons.wikimedia.org/wiki/File:Chevrolet_Onix_Mk2_RS_2020_in_Maldonado_-_front.jpg>
- `v04-chevrolet-onix/interior-01.jpg`: foto por **RL GNZLZ** (subida por Andra Febrian), licencia **CC BY-SA 2.0**, fuente <https://commons.wikimedia.org/wiki/File:2021_Chevrolet_Onix_1.0T_Premier_(Chile)_front_view.jpg>
- `v04-chevrolet-onix/interior-02.jpg`: foto por **Chevrolet México** (subida por Andra Febrian), licencia **CC BY 3.0**, fuente <https://commons.wikimedia.org/wiki/File:Chevrolet_Onix_(second_generation,_rear_view).jpg>

### v05-toyota-hilux

- `v05-toyota-hilux/exterior-01.jpg`: foto por **Vauxford**, licencia **CC BY-SA 4.0**, fuente <https://commons.wikimedia.org/wiki/File:2016_Toyota_HiLux_Invincible_D-4D_4WD_2.4_Front.jpg>
- `v05-toyota-hilux/exterior-02.jpg`: foto por **Vauxford**, licencia **CC BY-SA 4.0**, fuente <https://commons.wikimedia.org/wiki/File:2016_Toyota_HiLux_Invincible_D-4D_4WD_2.4_Side.jpg>
- `v05-toyota-hilux/exterior-03.jpg`: foto por **Vauxford**, licencia **CC BY-SA 4.0**, fuente <https://commons.wikimedia.org/wiki/File:2016_Toyota_HiLux_Invincible_D-4D_4WD_2.4_Rear.jpg>
- `v05-toyota-hilux/interior-01.jpg`: foto por **Vauxford**, licencia **CC BY-SA 4.0**, fuente <https://commons.wikimedia.org/wiki/File:2018_Toyota_HiLux_Invincible_X_facelift_Interior.jpg>
- `v05-toyota-hilux/interior-02.jpg`: foto por **Ethan Llamas**, licencia **CC BY-SA 4.0**, fuente <https://commons.wikimedia.org/wiki/File:Toyota_Hilux_GUN126_2.8_GR_Sport_-_interior_view.jpg>

### v06-jeep-renegade

- `v06-jeep-renegade/exterior-01.jpg`: foto por **Elise240SX**, licencia **CC BY-SA 4.0**, fuente <https://commons.wikimedia.org/wiki/File:2022_Jeep_Renegade_Trailhawk_in_Bikini_Pearl,_front_right,_2025-09-06.jpg>
- `v06-jeep-renegade/exterior-02.jpg`: foto por **Calreyn88**, licencia **CC BY-SA 4.0**, fuente <https://commons.wikimedia.org/wiki/File:2022_Jeep_Renegade.jpg>
- `v06-jeep-renegade/exterior-03.jpg`: foto por **Elise240SX**, licencia **CC BY-SA 4.0**, fuente <https://commons.wikimedia.org/wiki/File:2022_Jeep_Renegade_Trailhawk_in_Bikini_Pearl,_rear_right,_2025-09-06.jpg>
- `v06-jeep-renegade/interior-01.jpg`: foto por **Gzen92**, licencia **CC BY-SA 4.0**, fuente <https://commons.wikimedia.org/wiki/File:Jeep_Renegade_-_int%C3%A9rieur.jpg>
- `v06-jeep-renegade/interior-02.jpg`: foto por **Jakub "Flyz1" Maciejewski** (Wikigrant WG 2016-10), licencia **CC BY-SA 4.0**, fuente <https://commons.wikimedia.org/wiki/File:Jeep_Renegade_-_wn%C4%99trze_(MSP16).jpg>

### v07-toyota-sw4

*Nota: Toyota SW4 se comercializa internacionalmente como Toyota Fortuner. Las fotos corresponden al Fortuner AN150/AN160 2024, que es el mismo vehículo.*

- `v07-toyota-sw4/exterior-01.jpg`: foto por **Ethan Llamas**, licencia **CC BY-SA 4.0**, fuente <https://commons.wikimedia.org/wiki/File:2024_Toyota_Fortuner_2.4_G_4x2_in_Gray_Metallic,_front_right,_06-27-2024.jpg>
- `v07-toyota-sw4/exterior-02.jpg`: foto por **Ethan Llamas**, licencia **CC BY-SA 4.0**, fuente <https://commons.wikimedia.org/wiki/File:2024_Toyota_Fortuner_2.4_G_4x2_in_Gray_Metallic,_rear_right,_06-27-2024.jpg>
- `v07-toyota-sw4/exterior-03.jpg`: foto por **Ethan Llamas**, licencia **CC BY-SA 4.0**, fuente <https://commons.wikimedia.org/wiki/File:2024_Toyota_Fortuner_2.4_G_4x2_in_Gray_Metallic,_front_right,_06-27-2024.jpg>
- `v07-toyota-sw4/interior-01.jpg`: foto por **Ethan Llamas**, licencia **CC BY-SA 4.0**, fuente <https://commons.wikimedia.org/wiki/File:Toyota_Fortuner_GUN165_2.4_G_4x2_MT_-_interior_view.jpg>
- `v07-toyota-sw4/interior-02.jpg`: foto por **Ethan Llamas**, licencia **CC BY-SA 4.0**, fuente <https://commons.wikimedia.org/wiki/File:2024_Toyota_Fortuner_2.4_G_4x2_in_Gray_Metallic,_front_right,_06-27-2024.jpg>

### v08-renault-kangoo

- `v08-renault-kangoo/exterior-01.jpg`: foto por **Mr.choppers**, licencia **CC BY-SA 3.0**, fuente <https://commons.wikimedia.org/wiki/File:Renault_Kangoo_II_facelift_van_(Sweden),_front_right.jpg>
- `v08-renault-kangoo/exterior-02.jpg`: foto por **Mr.choppers**, licencia **CC BY-SA 3.0**, fuente <https://commons.wikimedia.org/wiki/File:Renault_Kangoo_II_facelift_van_(Sweden),_rear_right.jpg>
- `v08-renault-kangoo/exterior-03.jpg`: foto por **EurovisionNim**, licencia **CC BY-SA 4.0**, fuente <https://commons.wikimedia.org/wiki/File:2016_Renault_Kangoo_(X61_Series_II)_van_(2017-01-30)_01.jpg>
- `v08-renault-kangoo/interior-01.jpg`: foto por **TTTNIS**, licencia **dominio público**, fuente <https://commons.wikimedia.org/wiki/File:Renault_Kangoo_II_interior.jpg>
- `v08-renault-kangoo/interior-02.jpg`: foto por **M 93**, licencia **CC BY 3.0**, fuente <https://commons.wikimedia.org/wiki/File:Renault_Kangoo_II_rear_20100529.jpg>

### v09-ford-ranger

- `v09-ford-ranger/exterior-01.jpg`: foto por **Chanokchon**, licencia **CC BY-SA 4.0**, fuente <https://commons.wikimedia.org/wiki/File:2023_Ford_Ranger_Stormtrak_Double-Cab_2.0L_Bi-Turbo_4x4.jpg>
- `v09-ford-ranger/exterior-02.jpg`: foto por **Chanokchon**, licencia **CC BY-SA 4.0**, fuente <https://commons.wikimedia.org/wiki/File:2022_Ford_Ranger_Wildtrak_Double-Cab_2.0L_Bi-Turbo_4x4.jpg>
- `v09-ford-ranger/exterior-03.jpg`: foto por **Calreyn88**, licencia **CC BY-SA 4.0**, fuente <https://commons.wikimedia.org/wiki/File:2023_Ford_Ranger_Wildtrak_EcoBlue_4x4_Auto.jpg>
- `v09-ford-ranger/interior-01.jpg`: foto por **Deathpallie325**, licencia **CC BY 4.0**, fuente <https://commons.wikimedia.org/wiki/File:2024_Ford_Ranger_interior.jpg>
- `v09-ford-ranger/interior-02.jpg`: foto por **Ethan Llamas**, licencia **CC BY-SA 4.0**, fuente <https://commons.wikimedia.org/wiki/File:Ford_Ranger_P703_2.0_Bi-Turbo_Wildtrak_Special_Edition_4x4_interior.jpg>

### v10-vw-tcross

- `v10-vw-tcross/exterior-01.jpg`: foto por **Alexander-93**, licencia **CC BY-SA 4.0**, fuente <https://commons.wikimedia.org/wiki/File:Volkswagen_T-Cross_(2023)_1X7A1967.jpg>
- `v10-vw-tcross/exterior-02.jpg`: foto por **Alexander-93**, licencia **CC BY-SA 4.0**, fuente <https://commons.wikimedia.org/wiki/File:Volkswagen_T-Cross_(2023)_1X7A2499.jpg>
- `v10-vw-tcross/exterior-03.jpg`: foto por **Alexander-93**, licencia **CC BY-SA 4.0**, fuente <https://commons.wikimedia.org/wiki/File:Volkswagen_T-Cross_(2023)_1X7A2500.jpg>
- `v10-vw-tcross/interior-01.jpg`: foto por **Tokumeigakarinoaoshima**, licencia **CC0 1.0 (dominio público)**, fuente <https://commons.wikimedia.org/wiki/File:Volkswagen_T-Cross_TSI_R-Line_(3BA-C1DKR)_interior.jpg>
- `v10-vw-tcross/interior-02.jpg`: foto por **Tokumeigakarinoaoshima**, licencia **CC0 1.0 (dominio público)**, fuente <https://commons.wikimedia.org/wiki/File:Volkswagen_T-Cross_TSI_R-Line_(3BA-C1DKR)_front.jpg>

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
