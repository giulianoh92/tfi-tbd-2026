import { createClient } from '@/lib/supabase/server'
import type { ResumenMensualSucursal, Sucursal } from '@/types/database'
import { Card } from '@/components/ui/Card'
import { cn } from '@/lib/cn'
import { formatARS, formatDateTimeAR } from '@/lib/format'

type ResumenConSucursal = ResumenMensualSucursal & {
  sucursal: Pick<Sucursal, 'nombre'> | null
}

const PERIODO_FORMATTER = new Intl.DateTimeFormat('es-AR', {
  month: 'long',
  year: 'numeric',
})

/** "junio de 2026" a partir del primer dia del mes (DATE). */
function formatPeriodo(periodo: string): string {
  // `periodo` viene como 'yyyy-mm-dd'. Parseo en local para no correr el mes por UTC.
  const [y, m, d] = periodo.split('-').map((n) => parseInt(n, 10))
  if (!y || !m) return periodo
  const date = new Date(y, m - 1, d || 1)
  if (Number.isNaN(date.getTime())) return periodo
  const label = PERIODO_FORMATTER.format(date)
  return label.charAt(0).toUpperCase() + label.slice(1)
}

function formatKm(km: number | string | null | undefined): string {
  if (km === null || km === undefined || km === '') return '—'
  const n = typeof km === 'string' ? Number(km) : km
  if (Number.isNaN(n)) return '—'
  return `${n.toLocaleString('es-AR')} km`
}

/**
 * Vista staff del cierre contable mensual (Sprint 4 - R13).
 * Materializa el output del cron `cerrar-facturacion-mensual` (tabla resumen_mensual_sucursal).
 * RLS: `resumen_mensual_sucursal_staff_read` exige fn_es_staff().
 */
export default async function ReportesMensualesPage() {
  const supabase = await createClient()

  const { data, error } = await supabase
    .from('resumen_mensual_sucursal')
    .select('*, sucursal ( nombre )')
    .order('periodo', { ascending: false })
    .order('id_sucursal')

  if (error) {
    return (
      <div role="alert" className="rounded-lg bg-danger-bg border border-danger-border p-6">
        <p className="text-danger-fg font-medium">Error al cargar los reportes mensuales</p>
        <p className="text-danger-fg/80 text-sm mt-1">{error.message}</p>
      </div>
    )
  }

  const filas = (data ?? []) as ResumenConSucursal[]

  // Agrupo por periodo conservando el orden (ya viene ordenado por periodo desc, sucursal asc).
  const grupos: { periodo: string; filas: ResumenConSucursal[] }[] = []
  for (const fila of filas) {
    const ultimo = grupos[grupos.length - 1]
    if (ultimo && ultimo.periodo === fila.periodo) {
      ultimo.filas.push(fila)
    } else {
      grupos.push({ periodo: fila.periodo, filas: [fila] })
    }
  }

  return (
    <div>
      <div className="mb-6">
        <h1 className="font-display text-3xl font-bold text-slate-900">Reportes mensuales</h1>
        <p className="text-muted-fg mt-1 text-sm">
          {grupos.length.toLocaleString('es-AR')} período{grupos.length !== 1 ? 's' : ''}{' '}
          consolidado{grupos.length !== 1 ? 's' : ''}, {filas.length.toLocaleString('es-AR')}{' '}
          fila{filas.length !== 1 ? 's' : ''} por sucursal.
        </p>
        <p className="text-muted-fg/80 mt-1 text-xs">
          El cierre lo consolida el job <code className="font-mono">cerrar-facturacion-mensual</code>{' '}
          (pg_cron) el día 1 de cada mes.
        </p>
      </div>

      {filas.length === 0 ? (
        <Card variant="raised" className="text-center py-16">
          <p className="text-muted-fg text-lg">Aún no hay cierres consolidados.</p>
        </Card>
      ) : (
        <Card variant="raised" className="overflow-hidden p-0">
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-slate-200">
              <thead className="bg-slate-50">
                <tr>
                  <Th>Mes</Th>
                  <Th>Sucursal</Th>
                  <Th align="right">Facturas emitidas</Th>
                  <Th align="right">Costo base</Th>
                  <Th align="right">Recargos</Th>
                  <Th align="right">Total facturado</Th>
                  <Th align="right">Km recorridos</Th>
                  <Th>Fecha de cierre</Th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {grupos.map((grupo) => (
                  grupo.filas.map((row, idx) => (
                    <tr key={row.id_resumen} className="hover:bg-slate-50 transition-colors">
                      <td className="px-4 py-3 text-sm whitespace-nowrap">
                        {idx === 0 ? (
                          <span className="font-medium text-slate-900">
                            {formatPeriodo(grupo.periodo)}
                          </span>
                        ) : (
                          <span className="text-muted-fg/40" aria-hidden="true">↳</span>
                        )}
                      </td>
                      <td className="px-4 py-3 text-sm text-slate-900">
                        {row.sucursal?.nombre ?? `Sucursal #${row.id_sucursal}`}
                      </td>
                      <td className="px-4 py-3 text-right text-sm text-slate-900 font-mono tabular-nums">
                        {row.facturas_emitidas.toLocaleString('es-AR')}
                      </td>
                      <td className="px-4 py-3 text-right text-sm text-slate-700 font-mono tabular-nums">
                        {formatARS(row.total_costo_base)}
                      </td>
                      <td className="px-4 py-3 text-right text-sm text-slate-700 font-mono tabular-nums">
                        {formatARS(row.total_recargos)}
                      </td>
                      <td className="px-4 py-3 text-right text-sm text-slate-900 font-mono font-medium tabular-nums">
                        {formatARS(row.total_facturado)}
                      </td>
                      <td className="px-4 py-3 text-right text-sm text-slate-700 font-mono tabular-nums">
                        {formatKm(row.km_recorridos)}
                      </td>
                      <td className="px-4 py-3 text-sm text-muted-fg whitespace-nowrap tabular-nums">
                        {formatDateTimeAR(row.fecha_cierre)}
                      </td>
                    </tr>
                  ))
                ))}
              </tbody>
            </table>
          </div>
        </Card>
      )}
    </div>
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
