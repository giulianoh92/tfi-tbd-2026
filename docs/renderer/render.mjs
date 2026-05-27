#!/usr/bin/env node
// Script unico: renderiza .md → .pdf en un solo paso (md → html → pdf).
// Genera HTML desde template.html (CSS del vault + marked vendorizado inline),
// lo abre en Chromium via Playwright y emite el PDF: portada, TOC con numeros de
// pagina dinamicos, paginas apaisadas para los DER y numeracion al pie.
// El HTML intermedio se genera en un directorio temporal y se borra.
//
// Uso:
//   node render.mjs <archivo.md> [archivo.md ...] [-o <out-dir>] [--zip <salida.zip>] [--keep-html]
//
// Flags:
//   -o, --out <dir>     Directorio de salida para los PDFs. Default: junto al .md.
//   --zip <ruta.zip>    Empaqueta los PDFs generados en un .zip.
//   --keep-html         No borra los HTML intermedios (los deja junto al .md).

import { readFile, writeFile, mkdir, mkdtemp, rm, copyFile } from 'node:fs/promises';
import { dirname, basename, join, resolve, extname } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { tmpdir } from 'node:os';
import { spawn } from 'node:child_process';
import { chromium } from 'playwright';
import { PDFDocument, PDFName, StandardFonts, rgb } from 'pdf-lib';

const __dirname = dirname(fileURLToPath(import.meta.url));
const TEMPLATE_PATH = join(__dirname, 'template.html');
const MARKED_PATH = join(__dirname, 'vendor', 'marked.min.js');

function parseFrontmatter(md) {
  if (!md.startsWith('---\n')) return { meta: {}, body: md };
  const end = md.indexOf('\n---\n', 4);
  if (end === -1) return { meta: {}, body: md };
  const yaml = md.slice(4, end);
  const body = md.slice(end + 5);
  const meta = {};
  let currentList = null;
  for (const line of yaml.split('\n')) {
    if (!line.trim()) continue;
    if (line.startsWith('  - ') && currentList) {
      currentList.push(line.slice(4).trim());
      continue;
    }
    const m = line.match(/^([\w-]+):\s*(.*)$/);
    if (!m) continue;
    const [, key, value] = m;
    if (value === '') {
      meta[key] = [];
      currentList = meta[key];
    } else {
      meta[key] = value;
      currentList = null;
    }
  }
  return { meta, body };
}

function escapeHtml(s) {
  return String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
}

function buildMetaItems(meta) {
  const labels = { fecha: 'Fecha', unidad: 'Unidad', tipo: 'Tipo' };
  const items = [];
  for (const key of ['fecha', 'unidad', 'tipo']) {
    if (meta[key] != null && meta[key] !== '') {
      items.push(`<li><strong>${labels[key]}:</strong> ${escapeHtml(meta[key])}</li>`);
    }
  }
  if (Array.isArray(meta.tags) && meta.tags.length) {
    items.push(`<li><strong>Tags:</strong> ${meta.tags.map(escapeHtml).join(', ')}</li>`);
  }
  return items.join('\n      ');
}

function deriveTitle(meta, body, fallback) {
  const m = body.match(/^#\s+(.+)$/m);
  return m ? m[1].trim() : fallback;
}

function resolveRelativeAssetPaths(body, mdDir) {
  // Convierte rutas relativas en ![alt](path) y <img src="path"> a file:// absolutas
  // para que se resuelvan correctamente cuando el HTML vive en /tmp.
  const isRelative = p => !/^(https?:|file:|data:|\/)/i.test(p);
  let out = body.replace(/!\[([^\]]*)\]\(([^)\s]+)(\s+"[^"]*")?\)/g, (m, alt, path, title) => {
    if (!isRelative(path)) return m;
    const abs = pathToFileURL(resolve(mdDir, path)).href;
    return `![${alt}](${abs}${title || ''})`;
  });
  out = out.replace(/<img\s+([^>]*?)src=["']([^"']+)["']([^>]*?)>/gi, (m, pre, path, post) => {
    if (!isRelative(path)) return m;
    const abs = pathToFileURL(resolve(mdDir, path)).href;
    return `<img ${pre}src="${abs}"${post}>`;
  });
  return out;
}

async function renderHtml(mdPath, htmlOutPath, template, markedSrc) {
  const raw = await readFile(mdPath, 'utf8');
  const { meta, body } = parseFrontmatter(raw);
  const fileBase = basename(mdPath, '.md');
  const title = deriveTitle(meta, body, fileBase);
  const materia = meta.materia || 'Sin materia';

  const resolvedBody = resolveRelativeAssetPaths(body, dirname(mdPath));

  const out = template
    .replaceAll('{{TITLE}}', escapeHtml(title))
    .replaceAll('{{MATERIA_LABEL}}', 'Materia')
    .replaceAll('{{MATERIA}}', escapeHtml(materia))
    .replace('{{MARKED_JS}}', () => markedSrc)
    .replace('{{META_ITEMS}}', () => buildMetaItems(meta))
    .replace('{{MARKDOWN}}', () => resolvedBody);

  await writeFile(htmlOutPath, out, 'utf8');
}

// Stampea números de página en el footer-center: skipea la primera página
// (portada) y arranca en "1" en la siguiente. Modifica el PDF en su path.
// Se hace post-render porque Chromium no honra `counter-reset/set: page` sobre
// el page counter especial de Paged Media.
async function stampFooterNumbers(pdfPath) {
  const bytes = await readFile(pdfPath);
  const doc = await PDFDocument.load(bytes);
  const pages = doc.getPages();
  if (pages.length < 2) return; // doc sin páginas más allá de la portada
  const font = await doc.embedFont(StandardFonts.Helvetica);
  const fontSize = 9;
  const color = rgb(0x57 / 255, 0x60 / 255, 0x6a / 255);
  const yPt = 12 * 2.83464567; // 12mm desde el borde inferior, en puntos
  pages.forEach((page, i) => {
    if (i === 0) return; // sin número en la portada
    const label = String(i); // página 2 física → "1", página 3 → "2", etc.
    const { width } = page.getSize();
    const textWidth = font.widthOfTextAtSize(label, fontSize);
    page.drawText(label, {
      x: (width - textWidth) / 2,
      y: yPt,
      size: fontSize,
      font,
      color,
    });
  });
  const newBytes = await doc.save();
  await writeFile(pdfPath, newBytes);
}

// Lee /Catalog/Dests de un PDF (Buffer) y devuelve un mapa { destName -> pageNumber (1-indexed) }.
// Usado para resolver page numbers dinámicos en el TOC.
async function extractDestsMap(buf) {
  const doc = await PDFDocument.load(buf);
  const pages = doc.getPages();
  const refToIdx = new Map();
  pages.forEach((p, i) => refToIdx.set(p.ref.tag, i + 1));
  const dests = doc.catalog.lookup(PDFName.of('Dests'));
  const map = {};
  if (dests && typeof dests.entries === 'function') {
    for (const [k, v] of dests.entries()) {
      const arr = v.asArray ? v.asArray() : null;
      if (arr && arr[0] && arr[0].tag) {
        const idx = refToIdx.get(arr[0].tag);
        if (idx) map[k.encodedName.slice(1)] = idx;
      }
    }
  }
  return map;
}

async function renderPdf(browser, htmlPath, pdfPath) {
  const page = await browser.newPage();
  page.on('pageerror', err => console.warn(`  page error: ${err.message}`));
  await page.goto(pathToFileURL(htmlPath).href, { waitUntil: 'networkidle' });
  await page.waitForFunction(() => window.__renderState && window.__renderState.mermaidDone, {
    timeout: 30000,
  });
  await page.waitForTimeout(300);

  // Detectar segmentos: cada landscape-page parte el doc en bloques portrait/landscape.
  const segmentPlan = await page.evaluate(() => {
    const article = document.querySelector('.article');
    if (!article) return [];
    const children = Array.from(article.children);
    children.forEach((el, i) => { el.dataset.segIndex = String(i); });
    const segments = [];
    let buffer = [];
    for (const el of children) {
      if (el.matches('.landscape-page')) {
        if (buffer.length) segments.push({ type: 'portrait', indices: buffer });
        segments.push({ type: 'landscape', indices: [Number(el.dataset.segIndex)] });
        buffer = [];
      } else {
        buffer.push(Number(el.dataset.segIndex));
      }
    }
    if (buffer.length) segments.push({ type: 'portrait', indices: buffer });
    return segments;
  });

  // Caso simple: ningún landscape, render directo.
  if (!segmentPlan.some(s => s.type === 'landscape')) {
    const pdfOpts = { format: 'A4', printBackground: true, preferCSSPageSize: true };

    // Si el documento tiene un TOC con slots `.pn` vacíos o con placeholders,
    // resolver los números de página dinámicamente: render → leer /Catalog/Dests
    // → inyectar números en el DOM → repetir hasta estabilizar.
    const hasDynamicToc = await page.evaluate(() => {
      return document.querySelectorAll('.toc a[href^="#"] .pn').length > 0;
    });

    if (hasDynamicToc) {
      let prevSig = null;
      for (let iter = 0; iter < 5; iter++) {
        const buf = await page.pdf(pdfOpts);
        const map = await extractDestsMap(buf);
        const sig = JSON.stringify(map);
        if (sig === prevSig) break;
        await page.evaluate(m => {
          document.querySelectorAll('.toc a[href^="#"]').forEach(a => {
            const hash = (a.getAttribute('href') || '').replace(/^#/, '');
            const id = decodeURIComponent(hash);
            const pn = a.querySelector('.pn');
            // Restar 1: la portada (página física 1) no cuenta en la numeración.
            if (pn && m[id] != null && m[id] > 1) pn.textContent = String(m[id] - 1);
          });
        }, map);
        prevSig = sig;
      }
    }

    await page.pdf({ path: pdfPath, ...pdfOpts });
    await page.close();
    await stampFooterNumbers(pdfPath);
    return;
  }

  // Render segmentado: re-renderizar todos los segmentos + merge cada iteración
  // si hay TOC dinámico (los números de página globales solo se conocen post-merge).
  const hasDynamicTocSeg = await page.evaluate(() => {
    return document.querySelectorAll('.toc a[href^="#"] .pn').length > 0;
  });

  let mergedBytes;
  if (hasDynamicTocSeg) {
    let prevSig = null;
    for (let iter = 0; iter < 5; iter++) {
      mergedBytes = await renderAllSegmentsAndMerge(page, segmentPlan);
      const map = await extractDestsMap(mergedBytes);
      const sig = JSON.stringify(map);
      if (sig === prevSig) break;
      await page.evaluate(m => {
        document.querySelectorAll('.toc a[href^="#"]').forEach(a => {
          const hash = (a.getAttribute('href') || '').replace(/^#/, '');
          const id = decodeURIComponent(hash);
          const pn = a.querySelector('.pn');
          if (pn && m[id] != null && m[id] > 1) pn.textContent = String(m[id] - 1);
        });
      }, map);
      prevSig = sig;
    }
  } else {
    mergedBytes = await renderAllSegmentsAndMerge(page, segmentPlan);
  }

  await page.close();
  await writeFile(pdfPath, mergedBytes);
  await stampFooterNumbers(pdfPath);
}

// Renderiza todos los segmentos definidos en `segmentPlan` (alternancia
// portrait/landscape) y devuelve el PDF mergeado preservando `/Catalog/Dests`.
async function renderAllSegmentsAndMerge(page, segmentPlan) {
  const segmentBuffers = [];
  for (const seg of segmentPlan) {
    await page.evaluate(activeIndices => {
      document.body.classList.add('segment-render-mode');
      const article = document.querySelector('.article');
      Array.from(article.children).forEach(el => el.classList.remove('render-active'));
      activeIndices.forEach(i => {
        const el = article.children[i];
        if (el) el.classList.add('render-active');
      });
    }, seg.indices);

    const isLandscape = seg.type === 'landscape';
    const bytes = await page.pdf({
      format: 'A4',
      landscape: isLandscape,
      printBackground: true,
      margin: isLandscape
        ? { top: '8mm', right: '10mm', bottom: '8mm', left: '10mm' }
        : { top: '18mm', right: '16mm', bottom: '22mm', left: '16mm' },
    });
    segmentBuffers.push(bytes);
  }
  return await mergeSegmentsPreservingDests(segmentBuffers);
}

// Mergea PDFs preservando `/Catalog/Dests` con page refs remapeados al
// nuevo documento. pdf-lib's `copyPages` solo copia las páginas (con sus
// annotations), pero NO el dict `/Dests` del catálogo. Sin esto, los
// hyperlinks internos quedan apuntando a destinos inexistentes en el merge.
async function mergeSegmentsPreservingDests(buffers) {
  const out = await PDFDocument.create();
  let outDests = null; // se crea perezosamente al primer dest

  for (const bytes of buffers) {
    const src = await PDFDocument.load(bytes);
    const srcPages = src.getPages();
    const newPages = await out.copyPages(src, src.getPageIndices());
    // Map: tag de la old page ref → new PDFRef
    const refMap = new Map();
    srcPages.forEach((p, i) => refMap.set(p.ref.tag, newPages[i].ref));
    newPages.forEach(p => out.addPage(p));

    const srcDests = src.catalog.lookup(PDFName.of('Dests'));
    if (!srcDests || typeof srcDests.entries !== 'function') continue;

    if (!outDests) {
      outDests = out.context.obj({});
      out.catalog.set(PDFName.of('Dests'), outDests);
    }
    for (const [k, v] of srcDests.entries()) {
      const arr = v.asArray ? v.asArray() : null;
      if (!arr || arr.length === 0) continue;
      const oldRef = arr[0];
      if (!oldRef || !oldRef.tag) continue;
      const newRef = refMap.get(oldRef.tag);
      if (!newRef) continue;
      // Construir nuevo dest array en el contexto de `out`. Los items
      // restantes (PDFName /XYZ, PDFNumber x/y/zoom) no son context-bound,
      // se pueden reutilizar tal cual.
      const newArr = out.context.obj([newRef, ...arr.slice(1)]);
      outDests.set(k, newArr);
    }
  }

  return out.save();
}

function parseArgs(argv) {
  const inputs = [];
  let outDir = null;
  let zipPath = null;
  let keepHtml = false;
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === '-o' || a === '--out') { outDir = argv[++i]; continue; }
    if (a === '--zip') { zipPath = argv[++i]; continue; }
    if (a === '--keep-html') { keepHtml = true; continue; }
    if (a === '-h' || a === '--help') { return { help: true }; }
    inputs.push(a);
  }
  return { inputs, outDir, zipPath, keepHtml };
}

function usage() {
  console.log(`Uso: node render.mjs <archivo.md> [archivo.md ...] [-o <out-dir>] [--zip <salida.zip>] [--keep-html]`);
}

async function zipFiles(zipPath, files) {
  await mkdir(dirname(resolve(zipPath)), { recursive: true });
  await new Promise((res, rej) => {
    const args = ['-j', resolve(zipPath), ...files];
    const p = spawn('zip', args, { stdio: 'inherit' });
    p.on('exit', code => code === 0 ? res() : rej(new Error(`zip exit ${code}`)));
    p.on('error', rej);
  });
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  if (args.help || !args.inputs || args.inputs.length === 0) {
    usage();
    process.exit(args.help ? 0 : 1);
  }

  const template = await readFile(TEMPLATE_PATH, 'utf8');
  const markedSrc = await readFile(MARKED_PATH, 'utf8');
  const tmp = await mkdtemp(join(tmpdir(), 'clase-render-'));
  const browser = await chromium.launch();
  const generated = [];

  try {
    if (args.outDir) await mkdir(resolve(args.outDir), { recursive: true });

    for (const arg of args.inputs) {
      const mdPath = resolve(arg);
      const fileBase = basename(mdPath, '.md');
      const htmlIntermediate = join(tmp, `${fileBase}.html`);
      const pdfPath = args.outDir
        ? join(resolve(args.outDir), `${fileBase}.pdf`)
        : join(dirname(mdPath), `${fileBase}.pdf`);

      await renderHtml(mdPath, htmlIntermediate, template, markedSrc);
      await renderPdf(browser, htmlIntermediate, pdfPath);
      console.log(`pdf: ${pdfPath}`);
      generated.push(pdfPath);

      if (args.keepHtml) {
        const htmlKept = join(dirname(mdPath), `${fileBase}.html`);
        await copyFile(htmlIntermediate, htmlKept);
        console.log(`html: ${htmlKept}`);
      }
    }

    if (args.zipPath) {
      await zipFiles(args.zipPath, generated);
      console.log(`zip: ${resolve(args.zipPath)}`);
    }
  } finally {
    await browser.close();
    await rm(tmp, { recursive: true, force: true });
  }
}

main().catch(err => {
  console.error(err);
  process.exit(1);
});
