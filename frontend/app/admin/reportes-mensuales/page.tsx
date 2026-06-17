import { createClient } from '@/lib/supabase/server'
import Link from 'next/link'
import { ArrowRight, ArrowUpRight, ArrowDownRight } from 'lucide-react'
import type { ResumenMensualSucursal, Sucursal } from '@/types/database'
import { Card } from '@/components/ui/Card'
import { formatARS, formatDateTimeAR } from '@/lib/format'

type ResumenConSucursal = ResumenMensualSucursal & {
  sucursal: Pick<Sucursal, 'nombre'> | null
}

const PERIODO_FORMATTER = new Intl.DateTimeFormat('es-AR', {
  month: 'long',
  year: 'numeric',
})

/** "Mayo de 2026" a partir del primer dia del mes (DATE). */
function formatPeriodo(periodo: string): string {
  // `periodo` viene como 'yyyy-mm-dd'. Parseo en local para no correr el mes por UTC.
  const [y, m, d] = periodo.split('-').map((n) => parseInt(n, 10))
  if (!y || !m) return periodo
  const date = new Date(y, m - 1, d || 1)
  if (Number.isNaN(date.getTime())) return periodo
  const label = PERIODO_FORMATTER.format(date)
  return label.charAt(0).toUpperCase() + label.slice(1)
}

type Cierre = {
  periodo: string
  sucursales: number
  facturas: number
  recargos: number
  totalFacturado: number
  fechaCierre: string | null
}

/**
 * Indice del cierre contable mensual (Sprint 4 - R13).
 * Grid master de un Z-report por mes; el detalle vive en `[periodo]`.
 * Materializa el output del cron `cerrar-facturacion-mensual`.
 * RLS: `resumen_mensual_sucursal_staff_read` exige fn_es_staff().
 */
export default async function ReportesMensualesPage() {
  const supabase = await createClient()

  const { data, error } = await supabase
    .from('resumen_mensual_sucursal')
    .select('*, sucursal ( nombre )')
    .order('periodo', { ascending: false })

  if (error) {
    return (
      <div role="alert" className="rounded-lg bg-danger-bg border border-danger-border p-6">
        <p className="text-danger-fg font-medium">Error al cargar los reportes mensuales</p>
        <p className="text-danger-fg/80 text-sm mt-1">{error.message}</p>
      </div>
    )
  }

  const filas = (data ?? []) as ResumenConSucursal[]

  // Agrupo por periodo y consolido los KPIs del cierre.
  const mapa = new Map<string, Cierre>()
  for (const fila of filas) {
    const actual = mapa.get(fila.periodo) ?? {
      periodo: fila.periodo,
      sucursales: 0,
      facturas: 0,
      recargos: 0,
      totalFacturado: 0,
      fechaCierre: null as string | null,
    }
    actual.sucursales += 1
    actual.facturas += fila.facturas_emitidas
    actual.recargos += fila.total_recargos
    actual.totalFacturado += fila.total_facturado
    if (!actual.fechaCierre || fila.fecha_cierre > actual.fechaCierre) {
      actual.fechaCierre = fila.fecha_cierre
    }
    mapa.set(fila.periodo, actual)
  }

  // Newest first (la query ya viene desc, pero el Map no garantiza orden cruzado).
  const cierres = [...mapa.values()].sort((a, b) =>
    a.periodo < b.periodo ? 1 : a.periodo > b.periodo ? -1 : 0
  )

  return (
    <div>
      <div className="mb-6">
        <h1 className="font-display text-3xl font-bold text-slate-900">Reportes mensuales</h1>
        <p className="text-muted-fg mt-1 text-sm">
          {cierres.length.toLocaleString('es-AR')} período{cierres.length !== 1 ? 's' : ''}{' '}
          consolidado{cierres.length !== 1 ? 's' : ''}, {filas.length.toLocaleString('es-AR')}{' '}
          fila{filas.length !== 1 ? 's' : ''} por sucursal.
        </p>
        <p className="text-muted-fg/80 mt-1 text-xs">
          El cierre lo consolida el job <code className="font-mono">cerrar-facturacion-mensual</code>{' '}
          (pg_cron) el día 1 de cada mes.
        </p>
      </div>

      {cierres.length === 0 ? (
        <Card variant="raised" className="text-center py-16">
          <p className="text-muted-fg text-lg">Aún no hay cierres consolidados.</p>
        </Card>
      ) : (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
          {cierres.map((c, idx) => {
            // El "mes anterior cronologico" es el siguiente en la lista (orden desc).
            const previo = cierres[idx + 1]
            const delta =
              previo && previo.totalFacturado > 0
                ? ((c.totalFacturado - previo.totalFacturado) / previo.totalFacturado) * 100
                : null

            return (
              <Link
                key={c.periodo}
                href={`/admin/reportes-mensuales/${c.periodo}`}
                className="group focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand-500 rounded-xl"
              >
                <Card
                  variant="raised"
                  className="p-5 flex flex-col gap-4 h-full hover:-translate-y-0.5 hover:shadow-md transition-all"
                >
                  <div className="flex items-start justify-between gap-2">
                    <div>
                      <p className="text-xs text-muted-fg uppercase tracking-wider">Cierre</p>
                      <p className="font-display text-xl font-semibold text-slate-900">
                        {formatPeriodo(c.periodo)}
                      </p>
                    </div>
                    <ArrowRight
                      className="w-4 h-4 text-muted-fg/40 group-hover:text-brand-600 transition-colors mt-1 shrink-0"
                      aria-hidden="true"
                    />
                  </div>

                  <div>
                    <p className="text-xs text-muted-fg uppercase tracking-wider">Total facturado</p>
                    <div className="flex items-baseline gap-2 flex-wrap">
                      <p className="text-2xl font-bold text-slate-900 tabular-nums">
                        {formatARS(c.totalFacturado)}
                      </p>
                      {delta !== null && (
                        <span
                          className={
                            'inline-flex items-center gap-0.5 text-xs font-medium tabular-nums ' +
                            (delta >= 0 ? 'text-green-600' : 'text-red-600')
                          }
                        >
                          {delta >= 0 ? (
                            <ArrowUpRight className="w-3 h-3" aria-hidden="true" />
                          ) : (
                            <ArrowDownRight className="w-3 h-3" aria-hidden="true" />
                          )}
                          {Math.abs(delta).toLocaleString('es-AR', {
                            maximumFractionDigits: 1,
                          })}
                          %
                        </span>
                      )}
                    </div>
                  </div>

                  <div className="grid grid-cols-3 gap-2 text-muted-fg">
                    <div>
                      <p className="text-[11px] uppercase tracking-wider">Sucursales</p>
                      <p className="text-sm font-medium text-slate-700 tabular-nums">
                        {c.sucursales.toLocaleString('es-AR')}
                      </p>
                    </div>
                    <div>
                      <p className="text-[11px] uppercase tracking-wider">Facturas</p>
                      <p className="text-sm font-medium text-slate-700 tabular-nums">
                        {c.facturas.toLocaleString('es-AR')}
                      </p>
                    </div>
                    <div>
                      <p className="text-[11px] uppercase tracking-wider">Recargos</p>
                      <p className="text-sm font-medium text-slate-700 tabular-nums">
                        {formatARS(c.recargos)}
                      </p>
                    </div>
                  </div>

                  <p className="text-[11px] text-muted-fg/70 mt-auto pt-2 border-t border-slate-100 tabular-nums">
                    Cerrado {formatDateTimeAR(c.fechaCierre)}
                  </p>
                </Card>
              </Link>
            )
          })}
        </div>
      )}
    </div>
  )
}
