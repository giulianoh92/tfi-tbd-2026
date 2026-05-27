import { createClient } from '@/lib/supabase/server'
import Link from 'next/link'
import { ArrowLeft, ArrowRight } from 'lucide-react'
import type { AuditLog } from '@/types/database'
import { Card } from '@/components/ui/Card'
import { Badge } from '@/components/ui/Badge'
import { Button } from '@/components/ui/Button'
import { Input } from '@/components/ui/Input'
import { Select } from '@/components/ui/Select'
import { Label } from '@/components/ui/Label'
import { formatDateTimeAR } from '@/lib/format'

const TABLAS_AUDITADAS = [
  'cliente',
  'vehiculo',
  'reserva',
  'alquiler',
  'factura',
  'mantenimiento',
] as const

type BadgeVariant = 'success' | 'info' | 'danger' | 'muted'

const TIPO_OP_LABEL: Record<string, { label: string; variant: BadgeVariant }> = {
  I: { label: 'INSERT', variant: 'success' },
  U: { label: 'UPDATE', variant: 'info' },
  D: { label: 'DELETE', variant: 'danger' },
}

const PAGE_SIZE = 50

type SearchParams = {
  tabla?: string
  tipo_op?: string
  desde?: string
  hasta?: string
  page?: string
}

/**
 * Listado de auditoria (R1). Server component que lee `audit_log` con
 * paginacion server-side, filtros por tabla / tipo_op / rango de fechas.
 *
 * RLS policy `audit_log_staff_read` garantiza que solo staff lo vea.
 */
export default async function AuditoriaPage({
  searchParams,
}: {
  searchParams: Promise<SearchParams>
}) {
  const params = await searchParams
  const supabase = await createClient()

  const filtroTabla = params.tabla ?? ''
  const filtroTipoOp = params.tipo_op ?? ''
  const filtroDesde = params.desde ?? ''
  const filtroHasta = params.hasta ?? ''
  const pagina = Math.max(1, parseInt(params.page ?? '1', 10) || 1)

  const from = (pagina - 1) * PAGE_SIZE
  const to = from + PAGE_SIZE - 1

  let query = supabase
    .from('audit_log')
    .select('*', { count: 'exact' })
    .order('fecha_hora', { ascending: false })
    .range(from, to)

  if (filtroTabla) query = query.eq('tabla', filtroTabla)
  if (filtroTipoOp) query = query.eq('tipo_op', filtroTipoOp)
  if (filtroDesde) query = query.gte('fecha_hora', filtroDesde)
  if (filtroHasta) query = query.lte('fecha_hora', `${filtroHasta}T23:59:59.999Z`)

  const { data, error, count } = await query

  if (error) {
    return (
      <div role="alert" className="rounded-lg bg-danger-bg border border-danger-border p-6">
        <p className="text-danger-fg font-medium">Error al cargar el log de auditoria</p>
        <p className="text-danger-fg/80 text-sm mt-1">{error.message}</p>
      </div>
    )
  }

  const filas = (data ?? []) as AuditLog[]
  const total = count ?? 0
  const totalPaginas = Math.max(1, Math.ceil(total / PAGE_SIZE))

  // Resolver UUID → nombre legible para la columna usuario_app.
  const idsDistintos = Array.from(
    new Set(filas.map((r) => r.usuario_app).filter(Boolean)),
  ) as string[]
  const mapaUsuarios = new Map<string, string>()
  if (idsDistintos.length > 0) {
    const { data: usuarios } = await supabase
      .from('vw_usuario_legible')
      .select('id, nombre')
      .in('id', idsDistintos)
      .returns<{ id: string; nombre: string | null }[]>()
    for (const u of usuarios ?? []) {
      if (u.id && u.nombre) mapaUsuarios.set(u.id, u.nombre)
    }
  }

  const buildHref = (nuevaPagina: number) => {
    const qs = new URLSearchParams()
    if (filtroTabla) qs.set('tabla', filtroTabla)
    if (filtroTipoOp) qs.set('tipo_op', filtroTipoOp)
    if (filtroDesde) qs.set('desde', filtroDesde)
    if (filtroHasta) qs.set('hasta', filtroHasta)
    qs.set('page', String(nuevaPagina))
    return `/admin/auditoria?${qs.toString()}`
  }

  return (
    <div>
      <div className="mb-6">
        <h1 className="font-display text-3xl font-bold text-slate-900">Auditoría</h1>
        <p className="text-muted-fg mt-1 text-sm">
          {total.toLocaleString('es-AR')} registro{total !== 1 ? 's' : ''} en el log. Página {pagina} de {totalPaginas}.
        </p>
      </div>

      {/* Filtros */}
      <Card variant="raised" className="p-4 mb-6">
        <form
          key={`${filtroTabla}|${filtroTipoOp}|${filtroDesde}|${filtroHasta}`}
          method="get"
          className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-5 gap-4"
        >
          <div>
            <Label htmlFor="tabla">Tabla</Label>
            <Select id="tabla" name="tabla" defaultValue={filtroTabla}>
              <option value="">Todas</option>
              {TABLAS_AUDITADAS.map((t) => (
                <option key={t} value={t}>{t}</option>
              ))}
            </Select>
          </div>

          <div>
            <Label htmlFor="tipo_op">Operación</Label>
            <Select id="tipo_op" name="tipo_op" defaultValue={filtroTipoOp}>
              <option value="">Todas</option>
              <option value="I">INSERT</option>
              <option value="U">UPDATE</option>
              <option value="D">DELETE</option>
            </Select>
          </div>

          <div>
            <Label htmlFor="desde">Desde</Label>
            <Input id="desde" type="date" name="desde" defaultValue={filtroDesde} />
          </div>

          <div>
            <Label htmlFor="hasta">Hasta</Label>
            <Input id="hasta" type="date" name="hasta" defaultValue={filtroHasta} />
          </div>

          <div className="flex items-end gap-2">
            <Button type="submit" variant="primary" className="flex-1">
              Filtrar
            </Button>
            <Link
              href="/admin/auditoria"
              className="inline-flex items-center justify-center rounded-lg border border-slate-200 bg-white text-slate-700 text-sm font-medium px-4 py-2 hover:bg-slate-50 transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand-500"
            >
              Limpiar
            </Link>
          </div>
        </form>
      </Card>

      {filas.length === 0 ? (
        <Card variant="raised" className="text-center py-16">
          <p className="text-muted-fg text-lg">No hay registros que coincidan con los filtros.</p>
        </Card>
      ) : (
        <Card variant="raised" className="overflow-hidden p-0">
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-slate-200">
              <thead className="bg-slate-50">
                <tr>
                  <Th>Fecha</Th>
                  <Th>Op</Th>
                  <Th>Tabla</Th>
                  <Th>Id registro</Th>
                  <Th>Usuario DB</Th>
                  <Th>Rol sesion</Th>
                  <Th>Usuario app</Th>
                  <Th align="right">Detalle</Th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {filas.map((row) => {
                  const op = TIPO_OP_LABEL[row.tipo_op] ?? {
                    label: row.tipo_op,
                    variant: 'muted' as BadgeVariant,
                  }
                  return (
                    <tr key={row.id_audit} className="hover:bg-slate-50 transition-colors">
                      <td className="px-4 py-3 text-sm text-slate-700 whitespace-nowrap tabular-nums">
                        {formatDateTimeAR(row.fecha_hora)}
                      </td>
                      <td className="px-4 py-3">
                        <Badge variant={op.variant}>{op.label}</Badge>
                      </td>
                      <td className="px-4 py-3 text-sm text-slate-900 font-medium">{row.tabla}</td>
                      <td className="px-4 py-3 text-sm text-muted-fg font-mono">{row.id_registro ?? '—'}</td>
                      <td className="px-4 py-3 text-sm text-muted-fg font-mono">{row.usuario_db}</td>
                      <td className="px-4 py-3 text-sm text-muted-fg font-mono">{row.rol_sesion}</td>
                      <td
                        className="px-4 py-3 text-xs text-muted-fg font-mono"
                        title={row.usuario_app ?? undefined}
                      >
                        {(row.usuario_app && mapaUsuarios.get(row.usuario_app)) ?? row.usuario_app ?? '—'}
                      </td>
                      <td className="px-4 py-3 text-right">
                        <Link
                          href={`/admin/auditoria/${row.id_audit}`}
                          className="inline-flex items-center gap-1 text-sm font-medium text-brand-700 hover:underline focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand-500 rounded"
                        >
                          Ver
                          <ArrowRight className="w-3.5 h-3.5" aria-hidden="true" />
                        </Link>
                      </td>
                    </tr>
                  )
                })}
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
            <PageNav href={pagina > 1 ? buildHref(pagina - 1) : null} dir="prev" />
            <span className="text-sm text-muted-fg px-2 tabular-nums">{pagina} / {totalPaginas}</span>
            <PageNav href={pagina < totalPaginas ? buildHref(pagina + 1) : null} dir="next" />
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
  align?: 'left' | 'right'
}) {
  return (
    <th
      className={`px-4 py-3 text-xs font-semibold text-muted-fg uppercase tracking-wider ${
        align === 'right' ? 'text-right' : 'text-left'
      }`}
    >
      {children}
    </th>
  )
}

function PageNav({ href, dir }: { href: string | null; dir: 'prev' | 'next' }) {
  const label = dir === 'prev' ? 'Anterior' : 'Siguiente'
  const Icon = dir === 'prev' ? ArrowLeft : ArrowRight
  const content = (
    <span className="inline-flex items-center gap-1">
      {dir === 'prev' && <Icon className="w-4 h-4" aria-hidden="true" />}
      {label}
      {dir === 'next' && <Icon className="w-4 h-4" aria-hidden="true" />}
    </span>
  )

  if (!href) {
    return (
      <span className="rounded-lg border border-slate-200 text-slate-300 text-sm font-medium px-3 py-1.5 cursor-not-allowed">
        {content}
      </span>
    )
  }

  return (
    <Link
      href={href}
      className="rounded-lg border border-slate-300 bg-white text-slate-700 text-sm font-medium px-3 py-1.5 hover:bg-slate-50 transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand-500"
    >
      {content}
    </Link>
  )
}
