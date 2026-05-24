# Sprint 6 — Frontend / UX-UI

**Origen**: review Senior UX/UI Designer (frontend-design skill).
**Scope**: solo `frontend/`. NO toca `schema/`, `scripts/`, ni la firma de los RPC.
**Ejecutable en paralelo con**: `SPRINT_6_BACKEND.md` (desacoplado).
**Branch sugerida**: `sprint-6-frontend`.
**Stack**: Next.js 14 + TS + Tailwind + Supabase. Sin cambios de stack.

## Reglas

- NO modificar firmas de RPC ni asumir nuevos campos del backend; el sprint backend corre en paralelo y se merge separado.
- Componentes nuevos van en `frontend/components/ui/`.
- Tokens en `frontend/tailwind.config.ts`. Cero color hardcoded en componentes finales.
- Tildes correctas en strings visibles. Comentarios JSX/TSX sin emojis salvo asset visual.
- Cada checkbox marca al terminar.

---

## Bloque F1 — Design system minimo (CRITICO base)

> Objetivo: eliminar la repeticion de `border-gray-300 focus:ring-2 focus:ring-blue-500` esparcida en 15+ archivos y dar identidad visual real.

- [ ] F1.1 Llenar `frontend/tailwind.config.ts` con paleta semantica:
  ```ts
  colors: {
    brand:   { 50, 100, 200, 500, 600, 700 },   // elegir un color que NO sea blue-600 tailwind default
    surface: { default, raised, elevated, paper },
    success: { bg, fg, border },
    danger:  { bg, fg, border },
    warning: { bg, fg, border },
    info:    { bg, fg, border },
    muted:   { fg, bg },
  }
  ```
- [ ] F1.2 Agregar `fontFamily.display` distinta a Inter para H1/H2 de pagina (Inter Tight / Geist / Outfit via next/font).
- [ ] F1.3 Crear `frontend/components/ui/Button.tsx` con CVA: variants `primary | secondary | ghost | destructive | link`, sizes `sm | md | lg`. Estados focus-visible / disabled / loading.
- [ ] F1.4 Crear `frontend/components/ui/Input.tsx`, `Select.tsx`, `Textarea.tsx`, `Label.tsx` con focus ring brand-500 y border error rojo via prop `aria-invalid`.
- [ ] F1.5 Crear `frontend/components/ui/Card.tsx` con variants `flat | raised | elevated | paper` (jerarquia visual).
- [ ] F1.6 Crear `frontend/components/ui/Badge.tsx` con variants semanticos (success/danger/warning/info/muted).
- [ ] F1.7 Crear `frontend/lib/cn.ts` con `clsx + tailwind-merge`.
- [ ] F1.8 Migrar `app/login/page.tsx` como prueba piloto (form completo usando UI primitives).

**Commit**: `feat(ui): design system minimo (tokens semanticos, Button/Input/Card/Badge)`

---

## Bloque F2 — Modales accesibles con Radix (CRITICO a11y)

> Hoy `VehiculoFormModal`, `CancelarReservaButton`, `BajaVehiculoButton` son `<div fixed>` a mano. Sin focus trap, sin Escape, sin `role="dialog"`. Lector de pantalla queda ciego.

- [ ] F2.1 `bun add @radix-ui/react-dialog`.
- [ ] F2.2 Crear `frontend/components/ui/Dialog.tsx` wrapper sobre Radix con estilos del design system (overlay, content, close button accesible).
- [ ] F2.3 Migrar `frontend/components/VehiculoFormModal.tsx` a Dialog.
- [ ] F2.4 Migrar `frontend/components/CancelarReservaButton.tsx` a Dialog. Variant destructive.
- [ ] F2.5 Migrar `frontend/components/BajaVehiculoButton.tsx` a Dialog. Variant destructive. Boton trigger con icono + texto claro.
- [ ] F2.6 Verificar manualmente: Tab no escapa del modal, Escape cierra, focus vuelve al trigger al cerrar, lector de pantalla anuncia "dialog".

**Commit**: `fix(a11y): modales con Radix Dialog (focus trap, escape, aria)`

---

## Bloque F3 — Iconografia profesional

> Emojis 🚗🧾🗂️🔧⏰➕ en `app/admin/page.tsx` son el sello del PoC AI-generated. Lucide-react cuesta nada y eleva muchisimo la percepcion.

- [ ] F3.1 `bun add lucide-react`.
- [ ] F3.2 Reemplazar emojis del dashboard `app/admin/page.tsx` (6 cards) por `<Car />`, `<Receipt />`, `<History />`, `<Wrench />`, `<AlarmClock />`, `<Plus />`.
- [ ] F3.3 Auditar y reemplazar todos los emojis visibles en `frontend/**/*.tsx` y `frontend/**/*.ts`.
- [ ] F3.4 Convencion: tamanio default `w-4 h-4`, color heredado via `text-current`. NO usar emojis Unicode en UI a partir de este sprint.

**Commit**: `style(ui): emojis a lucide-react en panel admin y resto del frontend`

---

## Bloque F4 — Navegacion admin (sidebar + breadcrumbs)

> "← Panel" en cada subpagina no escala. Falta sidebar persistente.

- [ ] F4.1 Crear `frontend/components/admin/AdminSidebar.tsx` con secciones: Dashboard / Alquileres / Facturas / Auditoria / Flota / Devoluciones vencidas. Item activo destacado.
- [ ] F4.2 Crear `frontend/components/admin/Breadcrumbs.tsx` con segmentos dinamicos de la ruta.
- [ ] F4.3 Modificar `frontend/app/admin/layout.tsx` para incluir sidebar + breadcrumbs + main content area.
- [ ] F4.4 Remover los links "← Panel" / "← Volver" de cada subpagina (ahora redundantes).
- [ ] F4.5 Banner "STAFF activo" del layout: cambiar color de `amber` a un token brand-staff (slate / indigo) para no colisionar con "pendiente" y "vencido".

**Commit**: `feat(admin): sidebar persistente + breadcrumbs y banner staff con color dedicado`

---

## Bloque F5 — Home publica: filtros y disponibilidad

> Hoy `app/page.tsx` muestra vehiculos sin filtrar por estado. Usuario ve un auto "alquilado" y se frustra al llegar al detalle.

- [ ] F5.1 Filtrar la query de home por `id_estado` correspondiente a "disponible" via JOIN con `estado_vehiculo`.
- [ ] F5.2 Agregar barra de filtros (Server Component + searchParams): tipo de vehiculo (select), sucursal (select), rango de precio (inputs min/max).
- [ ] F5.3 Paginacion server-side (preservar querystring tipo `auditoria/page.tsx`).
- [ ] F5.4 Empty state con ilustracion SVG inline + microcopy ("No encontramos vehiculos con esos filtros. Probá ampliar el rango.").
- [ ] F5.5 Card de vehiculo: agregar microinteraccion `hover:-translate-y-0.5` + sombra animada al hover.

**Commit**: `feat(home): filtros, paginacion, estado disponible y polish de cards`

---

## Bloque F6 — Accesibilidad y contraste

- [ ] F6.1 Auditar usos de `text-gray-400` sobre fondo blanco/claro y reemplazar por `text-gray-600` (token `muted-fg`) cuando es texto informativo, no placeholder.
  - Archivos a revisar (no exhaustivo): `app/page.tsx`, `app/admin/page.tsx`, `app/mis-reservas/page.tsx`, `components/VehiculoCard.tsx`, `app/admin/auditoria/[id]/page.tsx`, `components/CerrarAlquilerForm.tsx`.
- [ ] F6.2 En `app/vehiculos/[id_vehiculo]/page.tsx:124-135`: cuando no hay disponibilidad, renderizar `<button disabled>` en vez de `<Link aria-disabled tabIndex=-1>`.
- [ ] F6.3 Convertir botones "Editar" / "Dar de baja" en `VehiculosAdminClient.tsx:114-127` a `<Button variant="ghost" size="sm">` con icono. "Dar de baja" usa `variant="destructive"` para distinguir.
- [ ] F6.4 Form errors inline por campo (no solo summary). Agregar `aria-invalid` y mensaje `<p id="..-error">` con `aria-describedby` desde el input. Aplicar al menos en `ReservaForm`, `NuevoAlquilerForm`, `VehiculoFormModal`, `CerrarAlquilerForm`.

**Commit**: `fix(a11y): contraste, button disabled, variantes destructive y errores inline`

---

## Bloque F7 — Combobox para selects largos

> `<select>` nativo con 500 clientes/vehiculos es inutilizable.

- [ ] F7.1 `bun add cmdk` (o `@radix-ui/react-popover` + composicion manual).
- [ ] F7.2 Crear `frontend/components/ui/Combobox.tsx` con busqueda fuzzy, soporte de teclado, y prop `items: { value, label, hint? }[]`.
- [ ] F7.3 Migrar selects de `NuevoAlquilerForm.tsx` (clientes, vehiculos, tarifas).
- [ ] F7.4 Migrar select de cliente en `VehiculoFormModal` si aplica.

**Commit**: `feat(ui): Combobox con busqueda y migracion de selects largos en NuevoAlquilerForm`

---

## Bloque F8 — Loading / error boundaries

- [ ] F8.1 Crear `frontend/app/loading.tsx` global con skeleton minimo.
- [ ] F8.2 Crear `frontend/app/error.tsx` global con boundary + retry button + log a `console.error`.
- [ ] F8.3 Crear `frontend/app/admin/loading.tsx` con skeleton que matchee layout admin (sidebar + main grid).
- [ ] F8.4 Crear `frontend/app/admin/error.tsx`.
- [ ] F8.5 Crear `loading.tsx` por subruta pesada al menos en: `admin/auditoria/`, `admin/alquileres/`, `mis-reservas/`.
- [ ] F8.6 Suspense boundaries en componentes que disparen queries lentas (galeria de fotos, listados grandes).

**Commit**: `feat(app): loading skeletons y error boundaries por ruta`

---

## Bloque F9 — Formato y utilities compartidas

- [ ] F9.1 Crear `frontend/lib/format.ts` con: `formatARS(amount)`, `formatDateAR(d)`, `formatDateTimeAR(d)`, `isoLocal(d)`, `diasHasta(d)`.
- [ ] F9.2 Migrar `ReservaForm.tsx:25-26` (bug UTC `toISOString().split('T')[0]`) para usar `isoLocal`. Verificar que el "today" calcula en zona local del cliente, no UTC.
- [ ] F9.3 Reemplazar todos los `new Intl.NumberFormat('es-AR', ...)` esparcidos por la app por `formatARS`.
- [ ] F9.4 Reemplazar todos los `toLocaleDateString('es-AR', ...)` por `formatDateAR` / `formatDateTimeAR`.

**Commit**: `refactor(lib): utilities de formato compartidas y fix de bug UTC en ReservaForm`

---

## Bloque F10 — Polish y microcopy

- [ ] F10.1 Cambiar microcopy "CRUD de vehiculos via stored procedures." (en `app/admin/vehiculos/page.tsx:72`) por algo legible: "Gestiona altas, ediciones y bajas de la flota."
- [ ] F10.2 Auditar strings visibles sin tildes y corregir ("valido" → "valido" no, "Seleccioná" si, "vehiculo" → "vehiculo" si en frontend cliente; en admin tecnico OK sin tildes pero consistente).
  > Nota: convencion final → strings visibles del cliente final con tildes correctas en rioplatense; admin tecnico interno puede mantener sin tildes si ya es asi, pero consistente dentro de cada pagina.
- [ ] F10.3 Densidad de tablas: agregar toggle `comfortable | compact` en panel admin (preferencia persistida en localStorage).
- [ ] F10.4 Vista factura `app/admin/facturas/[id_factura]`: pulir como documento real (header con datos del emisor, tabular-nums en montos, footer con condicion IVA / CUIT).
- [ ] F10.5 Tabla de alquileres activos: agregar columna "dias restantes" con badge color (rojo <24h, amber 1-3d, verde >3d).

**Commit**: `polish(ui): microcopy, densidad de tablas, factura como documento y dias restantes`

---

## Validacion final

- [ ] V1. `cd frontend && bun install && bun run build` sin errores nuevos (TS warnings tolerados como antes).
- [ ] V2. `bun run dev` y verificar manualmente flujo cliente (home → detalle → reservar → mis-reservas).
- [ ] V3. Flujo staff: login → admin → crear vehiculo → crear alquiler walk-in → finalizar → ver factura.
- [ ] V4. Lighthouse Accessibility >= 90 en `/`, `/admin`, `/login`.
- [ ] V5. Verificar lector de pantalla manualmente sobre modales (Mac VoiceOver / NVDA en Win): anuncia dialog, lee titulo, focus correcto.
- [ ] V6. Vercel preview verde con todos los cambios.

---

## Out of scope (Sprint 7+)

- Theme dark mode.
- Animaciones complejas (framer-motion) — por ahora microinteracciones CSS.
- i18n multilenguaje.
- Mobile PWA / offline.
- Tests E2E con Playwright (cubierto por otro sprint si se decide).
