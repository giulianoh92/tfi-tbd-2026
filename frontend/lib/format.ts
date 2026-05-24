/**
 * Utilities de formato compartidas para la app.
 *
 * Reglas:
 *  - formatARS: Intl.NumberFormat 'es-AR' con currency ARS.
 *  - formatDateAR / formatDateTimeAR: locale 'es-AR'.
 *  - isoLocal: yyyy-mm-dd en zona local (NO UTC). Critico para inputs type="date"
 *    de modo que "hoy" en Argentina no se corra un dia por el offset UTC.
 *  - diasHasta: dias enteros entre hoy y la fecha dada (negativos si pasada).
 */

const ARS_FORMATTER = new Intl.NumberFormat('es-AR', {
  style: 'currency',
  currency: 'ARS',
  maximumFractionDigits: 0,
})

const DATE_FORMATTER = new Intl.DateTimeFormat('es-AR', {
  day: '2-digit',
  month: '2-digit',
  year: 'numeric',
})

const DATE_TIME_FORMATTER = new Intl.DateTimeFormat('es-AR', {
  day: '2-digit',
  month: '2-digit',
  year: 'numeric',
  hour: '2-digit',
  minute: '2-digit',
})

/** Formatea importe en pesos argentinos. Acepta number o string numerico. */
export function formatARS(amount: number | string | null | undefined): string {
  if (amount === null || amount === undefined || amount === '') return '—'
  const n = typeof amount === 'string' ? Number(amount) : amount
  if (Number.isNaN(n)) return '—'
  return ARS_FORMATTER.format(n)
}

/** dd/mm/yyyy en es-AR. Acepta Date, string ISO o null. */
export function formatDateAR(d: Date | string | null | undefined): string {
  if (!d) return '—'
  const date = typeof d === 'string' ? new Date(d) : d
  if (Number.isNaN(date.getTime())) return '—'
  return DATE_FORMATTER.format(date)
}

/** dd/mm/yyyy HH:MM en es-AR. */
export function formatDateTimeAR(d: Date | string | null | undefined): string {
  if (!d) return '—'
  const date = typeof d === 'string' ? new Date(d) : d
  if (Number.isNaN(date.getTime())) return '—'
  return DATE_TIME_FORMATTER.format(date)
}

/**
 * Devuelve `yyyy-mm-dd` en la zona local del cliente.
 * NO usar `toISOString().split('T')[0]` — eso convierte a UTC y puede correr
 * un dia (caso clasico en Argentina UTC-3 cuando es despues de las 21:00 local).
 */
export function isoLocal(d: Date = new Date()): string {
  const y = d.getFullYear()
  const m = String(d.getMonth() + 1).padStart(2, '0')
  const day = String(d.getDate()).padStart(2, '0')
  return `${y}-${m}-${day}`
}

/**
 * Dias enteros entre `hoy` (00:00 local) y la fecha objetivo.
 * Positivo si la fecha es futura, 0 si es hoy, negativo si pasada.
 */
export function diasHasta(target: Date | string): number {
  const t = typeof target === 'string' ? new Date(target) : target
  if (Number.isNaN(t.getTime())) return 0

  const now = new Date()
  // Normalizo ambos a 00:00 local para evitar bias por horas.
  const a = new Date(now.getFullYear(), now.getMonth(), now.getDate()).getTime()
  const b = new Date(t.getFullYear(), t.getMonth(), t.getDate()).getTime()
  const MS_PER_DAY = 86_400_000
  return Math.round((b - a) / MS_PER_DAY)
}
