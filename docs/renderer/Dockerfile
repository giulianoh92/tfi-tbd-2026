# Imagen oficial de Playwright: trae Chromium + libs del SO preinstaladas.
# El tag DEBE coincidir con la version de "playwright" en package.json (1.59.1).
FROM mcr.microsoft.com/playwright:v1.59.1-jammy

WORKDIR /app

# Deps de Node (Chromium ya viene en la imagen base, no se descarga).
COPY package.json ./
RUN npm install --no-audit --no-fund

# Script + assets del renderer (marked vendorizado incluido).
COPY render.mjs template.html ./
COPY vendor ./vendor

# El .md y sus assets se montan en /work al ejecutar el contenedor.
#
#   docker build -t tfi-render docs/renderer
#   docker run --rm -v "$PWD/docs:/work" tfi-render "/work/TFI-2026 - Alquiler de Vehículos.md"
#
# El PDF se escribe junto al .md (en el volumen montado).
ENTRYPOINT ["node", "render.mjs"]
