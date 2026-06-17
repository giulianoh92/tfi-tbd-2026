import { createClient } from '@/lib/supabase/server'
import Link from 'next/link'
import { ArrowLeft } from 'lucide-react'
import type { ResumenMensualSucursal, Sucursal } from '@/types/database'
import { Card } from '@/components/ui/Card'
import { cn } from '@/lib/cn'
import { formatARS, formatDateTimeAR } from '@/lib/format'
import { ReporteExportButtons, type ReporteFila } from '@/components/ReporteExportButtons'

type ResumenConSucursal = ResumenMensualSucursal & {
  sucursal: Pick<Sucursal, 'nombre'> | null
}

interface Props {
  params: Promise<{ periodo: string }>
}

const PERIODO_FORMATTER = new Intl.DateTimeFormat('es-AR', {
  month: 'long',
  year: 'numeric',
})

/** "Mayo de 2026" a partir del primer dia del mes (DATE). Parse local, no UTC. */
function formatPeriodo(periodo: string): string {
  const [y, m, d] = periodo.split('-').map((n) => parseInt(n, 10))
  if (!y || !m) return periodo
  const date = new Date(y, m - 1, d || 1)
  if (Number.isNaN(date.getTime())) return periodo
  const label = PERIODO_FORMATTER.format(date)
  return label.charAt(0).toUpperCase() + label.slice(1)
}

function formatKm(km: number | null | undefined): string {
  if (km === null || km === undefined) return '—'
  if (Number.isNaN(km)) return '—'
  return `${km.toLocaleString('es-AR')} km`
}

/**
 * Detalle del cierre contable de un mes (Sprint 4 - R13).
 * Z-report / libro mayor: tiles KPI + tabla por sucursal con fila TOTAL de
 * reconciliacion. Export CSV/PDF en la cabecera.
 * RLS: `resumen_mensual_sucursal_staff_read` exige fn_es_staff().
 */
export default async function CierreMensualPage({ params }: Props) {
  const { periodo } = await params
  const supabase = await createClient()

  const { data, error } = await supabase
    .from('resumen_mensual_sucursal')
    .select('*, sucursal ( nombre )')
    .eq('periodo', periodo)

  if (error) {
    return (
      <div role="alert" className="rounded-lg bg-danger-bg border border-danger-border p-6">
        <p className="text-danger-fg font-medium">Error al cargar el cierre mensual</p>
        <p className="text-danger-fg/80 text-sm mt-1">{error.message}</p>
      </div>
    )
  }

  const filas = (data ?? []) as ResumenConSucursal[]

  if (filas.length === 0) {
    return (
      <Card variant="raised" className="text-center py-16">
        <p className="text-muted-fg text-lg">No hay cierre consolidado para este período.</p>
        <Link
          href="/admin/reportes-mensuales"
          className="mt-4 inline-flex items-center gap-1 text-sm font-medium text-brand-700 hover:underline focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand-500 rounded"
        >
          <ArrowLeft className="w-3.5 h-3.5" aria-hidden="true" />
          Volver a reportes mensuales
        </Link>
      </Card>
    )
  }

  const mesLabel = formatPeriodo(periodo)

  // Ordeno por total facturado DESC (la sucursal que mas factura, arriba).
  const ordenadas = [...filas].sort((a, b) => b.total_facturado - a.total_facturado)

  // Sumas del periodo (reconciliacion del cierre).
  const totales = filas.reduce(
    (acc, f) => ({
      facturas: acc.facturas + f.facturas_emitidas,
      costoBase: acc.costoBase + f.total_costo_base,
      recargos: acc.recargos + f.total_recargos,
      facturado: acc.facturado + f.total_facturado,
      km: acc.km + f.km_recorridos,
    }),
    { facturas: 0, costoBase: 0, recargos: 0, facturado: 0, km: 0 }
  )

  const fechaCierre = filas.reduce<string | null>(
    (max, f) => (!max || f.fecha_cierre > max ? f.fecha_cierre : max),
    null
  )

  // Filas serializables para el client component de export.
  const filasExport: ReporteFila[] = ordenadas.map((f) => ({
    sucursal: f.sucursal?.nombre ?? `Sucursal #${f.id_sucursal}`,
    facturas_emitidas: f.facturas_emitidas,
    total_costo_base: f.total_costo_base,
    total_recargos: f.total_recargos,
    total_facturado: f.total_facturado,
    km_recorridos: f.km_recorridos,
  }))

  return (
    <div>
      {/* Cabecera */}
      <div className="mb-6 flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
        <div>
          <Link
            href="/admin/reportes-mensuales"
            className="print:hidden inline-flex items-center gap-1 text-sm text-muted-fg hover:text-slate-900 transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand-500 rounded mb-2"
          >
            <ArrowLeft className="w-3.5 h-3.5" aria-hidden="true" />
            Reportes mensuales
          </Link>
          <h1 className="font-display text-3xl font-bold text-slate-900">{mesLabel}</h1>
          <p className="text-muted-fg mt-1 text-sm tabular-nums">
            Cerrado {formatDateTimeAR(fechaCierre)} · job{' '}
            <code className="font-mono">cerrar-facturacion-mensual</code>
          </p>
        </div>
        <ReporteExportButtons filas={filasExport} periodo={periodo} mesLabel={mesLabel} />
      </div>

      {/* Tiles KPI — sumas del periodo */}
      <div className="mb-6 grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-5">
        <KpiTile label="Total facturado" value={formatARS(totales.facturado)} dominante />
        <KpiTile label="Costo base" value={formatARS(totales.costoBase)} />
        <KpiTile label="Recargos" value={formatARS(totales.recargos)} />
        <KpiTile label="Facturas" value={totales.facturas.toLocaleString('es-AR')} />
        <KpiTile label="Km recorridos" value={formatKm(totales.km)} />
      </div>

      {/* Tabla de sucursales */}
      <Card variant="raised" className="overflow-hidden p-0 print:shadow-none print:border-0">
        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-slate-200">
            <thead className="bg-slate-50">
              <tr>
                <Th>Sucursal</Th>
                <Th align="right">Facturas</Th>
                <Th align="right">Costo base</Th>
                <Th align="right">Recargos</Th>
                <Th align="right">Total</Th>
                <Th align="right">Km</Th>
                <Th align="right">%</Th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {ordenadas.map((row) => {
                const pct =
                  totales.facturado > 0
                    ? (row.total_facturado / totales.facturado) * 100
                    : 0
                return (
                  <tr key={row.id_resumen} className="hover:bg-slate-50 transition-colors">
                    <td className="px-4 py-3 text-sm text-slate-900">
                      {row.sucursal?.nombre ?? `Sucursal #${row.id_sucursal}`}
                    </td>
                    <td className="px-4 py-3 text-right text-sm text-slate-900 tabular-nums">
                      {row.facturas_emitidas.toLocaleString('es-AR')}
                    </td>
                    <td className="px-4 py-3 text-right text-sm text-muted-fg tabular-nums">
                      {formatARS(row.total_costo_base)}
                    </td>
                    <td
                      className={cn(
                        'px-4 py-3 text-right text-sm tabular-nums',
                        row.total_recargos > 0 ? 'text-amber-600 font-medium' : 'text-slate-400'
                      )}
                    >
                      {row.total_recargos > 0 ? formatARS(row.total_recargos) : '—'}
                    </td>
                    <td className="px-4 py-3 text-right text-sm font-semibold text-slate-900 tabular-nums">
                      {formatARS(row.total_facturado)}
                    </td>
                    <td className="px-4 py-3 text-right text-sm text-muted-fg tabular-nums">
                      {formatKm(row.km_recorridos)}
                    </td>
                    <td className="px-4 py-3 text-right text-sm text-slate-700 tabular-nums">
                      <div className="flex items-center justify-end gap-2">
                        <span>
                          {pct.toLocaleString('es-AR', { maximumFractionDigits: 1 })}%
                        </span>
                        <span
                          className="hidden sm:block h-1.5 w-12 rounded-full bg-slate-100 overflow-hidden"
                          aria-hidden="true"
                        >
                          <span
                            className="block h-full bg-brand-500"
                            style={{ width: `${Math.min(100, pct)}%` }}
                          />
                        </span>
                      </div>
                    </td>
                  </tr>
                )
              })}
            </tbody>
            <tfoot>
              <tr className="border-t-2 border-slate-300 bg-slate-50 font-semibold text-slate-900">
                <td className="px-4 py-3 text-sm">TOTAL</td>
                <td className="px-4 py-3 text-right text-sm tabular-nums">
                  {totales.facturas.toLocaleString('es-AR')}
                </td>
                <td className="px-4 py-3 text-right text-sm tabular-nums">
                  {formatARS(totales.costoBase)}
                </td>
                <td className="px-4 py-3 text-right text-sm tabular-nums">
                  {formatARS(totales.recargos)}
                </td>
                <td className="px-4 py-3 text-right text-sm tabular-nums">
                  {formatARS(totales.facturado)}
                </td>
                <td className="px-4 py-3 text-right text-sm tabular-nums">
                  {formatKm(totales.km)}
                </td>
                <td className="px-4 py-3 text-right text-sm tabular-nums">100%</td>
              </tr>
            </tfoot>
          </table>
        </div>
      </Card>
    </div>
  )
}

function KpiTile({
  label,
  value,
  dominante = false,
}: {
  label: string
  value: string
  dominante?: boolean
}) {
  return (
    <Card variant="flat" className="p-4 print:shadow-none">
      <p className="text-[11px] text-muted-fg uppercase tracking-wider">{label}</p>
      <p
        className={cn(
          'mt-1 tabular-nums',
          dominante
            ? 'text-xl font-bold text-slate-900'
            : 'text-base font-semibold text-slate-700'
        )}
      >
        {value}
      </p>
    </Card>
  )
}

function Th({
  children,
  align = 'left',
}: {
  children: React.ReactNode
  align?: 'left' | 'right' | 'center'
}) {
  return (
    <th
      className={cn(
        'px-4 py-3 text-xs font-semibold text-muted-fg uppercase tracking-wider',
        align === 'right' && 'text-right',
        align === 'center' && 'text-center'
      )}
    >
      {children}
    </th>
  )
}
