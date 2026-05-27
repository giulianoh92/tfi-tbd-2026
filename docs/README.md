# Documento del TFI

Documento principal del Trabajo Final Integrador y la herramienta para renderizarlo a PDF.

```
docs/
├── TFI-2026 - Alquiler de Vehículos.md   # fuente editable (Markdown)
├── assets/                               # imágenes referenciadas por el .md (DER, logo, casos de uso)
└── renderer/                             # script único Markdown → PDF
    ├── render.mjs                        # el único script que se ejecuta
    ├── template.html                     # estilo del vault (CSS) + lógica de render
    ├── vendor/marked.min.js              # parser Markdown vendorizado (sin CDN)
    ├── package.json                      # deps: playwright + pdf-lib
    └── Dockerfile                        # render sin instalar nada en el host
```

El `.md` es la **fuente de verdad**. El PDF es un artefacto generado: editás el `.md`, volvés a renderizar y obtenés el PDF actualizado (junto al `.md`).

## Opción A — Docker (no instala nada en el host)

Solo requiere Docker. La imagen base de Playwright ya trae Chromium.

```bash
# build (una sola vez)
docker build -t tfi-render docs/renderer

# render (desde la raíz del repo)
docker run --rm -v "$PWD/docs:/work" tfi-render "/work/TFI-2026 - Alquiler de Vehículos.md"
```

El PDF queda en `docs/TFI-2026 - Alquiler de Vehículos.pdf`.

> El archivo generado dentro del contenedor puede quedar como `root`. Para que sea de tu usuario:
> `docker run --rm --user "$(id -u):$(id -g)" -v "$PWD/docs:/work" tfi-render "/work/TFI-2026 - Alquiler de Vehículos.md"`

## Opción B — Node local

Requiere Node ≥ 18.

```bash
cd docs/renderer
npm install                 # baja playwright + pdf-lib y descarga Chromium
node render.mjs "../TFI-2026 - Alquiler de Vehículos.md"
```

> `node_modules/` está en `.gitignore`. Si Chromium no se bajó solo: `npx playwright install chromium`.

### Flags

- `-o <dir>` — directorio de salida alternativo.
- `--keep-html` — conserva el HTML intermedio (debug).
- `--zip <ruta.zip>` — empaqueta el PDF en un `.zip`.

## Notas

- **Un solo script**: `render.mjs` hace `.md → html → pdf` en un paso. Arma portada, TOC con números de página dinámicos, rota a landscape las páginas marcadas con `class="landscape-page"` (los DER) y numera al pie.
- **Sin red**: `marked` está vendorizado e inyectado inline en el HTML. No se descarga nada al renderizar.
- **Solo este documento**: se quitaron Mermaid, KaTeX y la ejecución de `run-python` porque el doc no los usa. Si más adelante agregás diagramas Mermaid o fórmulas LaTeX, hay que volver a sumar esas librerías al `template.html`.
- Las rutas de imagen en el `.md` son relativas (`assets/...`) y se resuelven contra la ubicación del `.md`. Si movés el `.md`, llevá `assets/` con él.
- El toolchain original vive en `Vault/.tools/clase-html-renderer/`. Esta es una versión recortada y autocontenida para que el repo sea reproducible sin el vault.
