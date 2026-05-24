import { createClient } from '@/lib/supabase/server'
import Link from 'next/link'
import { ArrowLeft, ArrowRight } from 'lucide-react'
import { MarcarNotificadoButton } from '@/components/MarcarNotificadoButton'
import type { DevolucionVencida, Vehiculo, Cliente } from '@/types/database'
import { Card } from '@/components/ui/Card'
import { Badge } from '@/components/ui/Badge'
import { cn } from '@/lib/cn'
import { formatDateTimeAR } from '@/lib/format'

type DevolucionConDetalles = DevolucionVencida & {
  vehiculo: Pick<Vehiculo, 'marca' | 'modelo' | 'patente'> | null
  cliente: Pick<Cliente, 'nombre' | 'apellido' | 'dni'> | null
}

const PAGE_SIZE = 50

type SearchParams = {
  filtro?: 'todas' | 'pendientes' | 'notificadas'
  page?: string
}

/**
 * Vista staff de devoluciones vencidas (Sprint 4 - R9).
 * RLS: `devolucion_vencida_staff_read` exige fn_es_staff().
 */
export default async function DevolucionesVencidasPage({
  searchParams,
}: {
  searchParams: Promise<SearchParams>
}) {
  const params = await searchParams
  const supabase = await createClient()

  const filtro = params.filtro ?? 'todas'
  const pagina = Math.max(1, parseInt(params.page ?? '1', 10) || 1)

  const from = (pagina - 1) * PAGE_SIZE
  const to = from + PAGE_SIZE - 1

  let query = supabase
    .from('devolucion_vencida')
    .select(
      `
      *,
      vehiculo ( marca, modelo, patente ),
      cliente ( nombre, apellido, dni )
    `,
      { count: 'exact' }
    )
    .order('fecha_deteccion', { ascending: false })
    .range(from, to)

  if (filtro === 'pendientes') query = query.eq('notificado', false)
  else if (filtro === 'notificadas') query = query.eq('notificado', true)

  const { data, error, count } = await query

  if (error) {
    return (
      <div role="alert" className="rounded-lg bg-danger-bg border border-danger-border p-6">
        <p className="text-danger-fg font-medium">Error al cargar las devoluciones vencidas</p>
        <p className="text-danger-fg/80 text-sm mt-1">{error.message}</p>
      </div>
    )
  }

  const filas = (data ?? []) as DevolucionConDetalles[]
  const total = count ?? 0
  const totalPaginas = Math.max(1, Math.ceil(total / PAGE_SIZE))

  const buildHref = (
    nuevoFiltro: SearchParams['filtro'],
    nuevaPagina: number
  ) => {
    const qs = new URLSearchParams()
    if (nuevoFiltro && nuevoFiltro !== 'todas') qs.set('filtro', nuevoFiltro)
    if (nuevaPagina > 1) qs.set('page', String(nuevaPagina))
    const tail = qs.toString()
    return tail
      ? `/admin/devoluciones-vencidas?${tail}`
      : '/admin/devoluciones-vencidas'
  }

  return (
    <div>
      <div className="mb-6">
        <h1 className="font-display text-3xl font-bold text-slate-900">Devoluciones vencidas</h1>
        <p className="text-muted-fg mt-1 text-sm">
          {total.toLocaleString('es-AR')} detección{total !== 1 ? 'es' : ''}{' '}
          registrada{total !== 1 ? 's' : ''}. Página {pagina} de {totalPaginas}.
        </p>
        <p className="text-muted-fg/80 mt-1 text-xs">
          El job <code className="font-mono">detectar-devoluciones-vencidas</code> corre cada 6 horas (pg_cron).
        </p>
      </div>

      {/* Tabs de filtro */}
      <div role="tablist" aria-label="Filtro de devoluciones" className="flex items-center gap-2 mb-6">
        {(['todas', 'pendientes', 'notificadas'] as const).map((t) => {
          const activo = filtro === t
          const label =
            t === 'todas' ? 'Todas' : t === 'pendientes' ? 'Pendientes' : 'Notificadas'
          return (
            <Link
              key={t}
              href={buildHref(t, 1)}
              role="tab"
              aria-selected={activo}
              className={cn(
                'px-3 py-1.5 rounded-lg text-sm font-medium transition-colors',
                'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand-500',
                activo
                  ? 'bg-brand-600 text-white'
                  : 'border border-slate-300 bg-white text-slate-700 hover:bg-slate-50'
              )}
            >
              {label}
            </Link>
          )
        })}
      </div>

      {filas.length === 0 ? (
        <Card variant="raised" className="text-center py-16">
          <p className="text-muted-fg text-lg">No hay devoluciones vencidas que coincidan con el filtro.</p>
        </Card>
      ) : (
        <Card variant="raised" className="overflow-hidden p-0">
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-slate-200">
              <thead className="bg-slate-50">
                <tr>
                  <Th>Detectado</Th>
                  <Th>Cliente</Th>
                  <Th>Vehículo</Th>
                  <Th>Fecha prevista</Th>
                  <Th align="right">Hs excedidas</Th>
                  <Th align="center">Estado</Th>
                  <Th align="right">Acción</Th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {filas.map((row) => (
                  <tr key={row.id_devolucion_vencida} className="hover:bg-slate-50 transition-colors">
                    <td className="px-4 py-3 text-sm text-slate-700 whitespace-nowrap tabular-nums">
                      {formatDateTimeAR(row.fecha_deteccion)}
                    </td>
                    <td className="px-4 py-3">
                      <p className="text-sm text-slate-900">
                        {row.cliente
                          ? `${row.cliente.nombre} ${row.cliente.apellido}`
                          : `Cliente #${row.id_cliente}`}
                      </p>
                      {row.cliente && (
                        <p className="text-muted-fg text-xs">DNI {row.cliente.dni}</p>
                      )}
                    </td>
                    <td className="px-4 py-3">
                      <p className="font-medium text-slate-900 text-sm">
                        {row.vehiculo
                          ? `${row.vehiculo.marca} ${row.vehiculo.modelo}`
                          : `Vehículo #${row.id_vehiculo}`}
                      </p>
                      {row.vehiculo && (
                        <p className="text-muted-fg text-xs font-mono">{row.vehiculo.patente}</p>
                      )}
                    </td>
                    <td className="px-4 py-3 text-sm text-slate-700 whitespace-nowrap tabular-nums">
                      {formatDateTimeAR(row.fecha_fin_prevista)}
                    </td>
                    <td className="px-4 py-3 text-right text-sm text-slate-900 font-mono tabular-nums">
                      {Number(row.horas_excedidas).toLocaleString('es-AR', {
                        maximumFractionDigits: 2,
                      })}
                    </td>
                    <td className="px-4 py-3 text-center">
                      {row.notificado ? (
                        <Badge variant="success">Notificado</Badge>
                      ) : (
                        <Badge variant="warning">Pendiente</Badge>
                      )}
                    </td>
                    <td className="px-4 py-3 text-right">
                      <MarcarNotificadoButton
                        idDevolucionVencida={row.id_devolucion_vencida}
                        notificado={row.notificado}
                      />
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </Card>
      )}

      {/* Paginacion */}
      {totalPaginas > 1 && (
        <div className="flex items-center justify-between mt-4">
          <div className="text-sm text-muted-fg">
            Mostrando {from + 1}-{Math.min(to + 1, total)} de {total}
          </div>
          <div className="flex items-center gap-2">
            <PageNav href={pagina > 1 ? buildHref(filtro, pagina - 1) : null} dir="prev" />
            <span className="text-sm text-muted-fg px-2 tabular-nums">{pagina} / {totalPaginas}</span>
            <PageNav href={pagina < totalPaginas ? buildHref(filtro, pagina + 1) : null} dir="next" />
          </div>
        </div>
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

function PageNav({ href, dir }: { href: string | null; dir: 'prev' | 'next' }) {
  const label = dir === 'prev' ? 'Anterior' : 'Siguiente'
  const Icon = dir === 'prev' ? ArrowLeft : ArrowRight
  const inner = (
    <span className="inline-flex items-center gap-1">
      {dir === 'prev' && <Icon className="w-4 h-4" aria-hidden="true" />}
      {label}
      {dir === 'next' && <Icon className="w-4 h-4" aria-hidden="true" />}
    </span>
  )
  if (!href) {
    return (
      <span className="rounded-lg border border-slate-200 text-slate-300 text-sm font-medium px-3 py-1.5 cursor-not-allowed">
        {inner}
      </span>
    )
  }
  return (
    <Link
      href={href}
      className="rounded-lg border border-slate-300 bg-white text-slate-700 text-sm font-medium px-3 py-1.5 hover:bg-slate-50 transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand-500"
    >
      {inner}
    </Link>
  )
}
