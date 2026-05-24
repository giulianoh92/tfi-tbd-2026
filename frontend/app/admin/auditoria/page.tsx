import { createClient } from '@/lib/supabase/server'
import Link from 'next/link'
import type { AuditLog } from '@/types/database'

const TABLAS_AUDITADAS = [
  'cliente',
  'vehiculo',
  'reserva',
  'alquiler',
  'factura',
  'mantenimiento',
] as const

const TIPO_OP_LABEL: Record<string, { label: string; clase: string }> = {
  I: { label: 'INSERT', clase: 'bg-green-50 text-green-700 border-green-200' },
  U: { label: 'UPDATE', clase: 'bg-blue-50 text-blue-700 border-blue-200' },
  D: { label: 'DELETE', clase: 'bg-red-50 text-red-700 border-red-200' },
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

  if (filtroTabla) {
    query = query.eq('tabla', filtroTabla)
  }
  if (filtroTipoOp) {
    query = query.eq('tipo_op', filtroTipoOp)
  }
  if (filtroDesde) {
    query = query.gte('fecha_hora', filtroDesde)
  }
  if (filtroHasta) {
    // El input type=date manda YYYY-MM-DD. Para que `hasta` incluya el dia
    // completo le sumamos 23:59:59 antes de enviarlo a la query.
    query = query.lte('fecha_hora', `${filtroHasta}T23:59:59.999Z`)
  }

  const { data, error, count } = await query

  if (error) {
    return (
      <div className="rounded-lg bg-red-50 border border-red-200 p-6">
        <p className="text-red-700 font-medium">Error al cargar el log de auditoria</p>
        <p className="text-red-500 text-sm mt-1">{error.message}</p>
      </div>
    )
  }

  const filas = (data ?? []) as AuditLog[]
  const total = count ?? 0
  const totalPaginas = Math.max(1, Math.ceil(total / PAGE_SIZE))

  // Genera querystring conservando filtros y cambiando solo `page`.
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
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Auditoría</h1>
          <p className="text-gray-500 mt-1 text-sm">
            {total.toLocaleString('es-AR')} registro{total !== 1 ? 's' : ''} en
            el log. Página {pagina} de {totalPaginas}.
          </p>
        </div>
        <Link
          href="/admin"
          className="text-sm text-blue-600 hover:text-blue-800 font-medium"
        >
          ← Panel
        </Link>
      </div>

      {/* Filtros */}
      <form
        method="get"
        className="bg-white rounded-xl border border-gray-200 shadow-sm p-4 mb-6 grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-5 gap-4"
      >
        <div>
          <label
            htmlFor="tabla"
            className="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1"
          >
            Tabla
          </label>
          <select
            id="tabla"
            name="tabla"
            defaultValue={filtroTabla}
            className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm"
          >
            <option value="">Todas</option>
            {TABLAS_AUDITADAS.map((t) => (
              <option key={t} value={t}>
                {t}
              </option>
            ))}
          </select>
        </div>

        <div>
          <label
            htmlFor="tipo_op"
            className="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1"
          >
            Operación
          </label>
          <select
            id="tipo_op"
            name="tipo_op"
            defaultValue={filtroTipoOp}
            className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm"
          >
            <option value="">Todas</option>
            <option value="I">INSERT</option>
            <option value="U">UPDATE</option>
            <option value="D">DELETE</option>
          </select>
        </div>

        <div>
          <label
            htmlFor="desde"
            className="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1"
          >
            Desde
          </label>
          <input
            id="desde"
            type="date"
            name="desde"
            defaultValue={filtroDesde}
            className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm"
          />
        </div>

        <div>
          <label
            htmlFor="hasta"
            className="block text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1"
          >
            Hasta
          </label>
          <input
            id="hasta"
            type="date"
            name="hasta"
            defaultValue={filtroHasta}
            className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm"
          />
        </div>

        <div className="flex items-end gap-2">
          <button
            type="submit"
            className="flex-1 rounded-lg bg-blue-600 text-white text-sm font-medium px-4 py-2 hover:bg-blue-700 transition-colors"
          >
            Filtrar
          </button>
          <Link
            href="/admin/auditoria"
            className="rounded-lg border border-gray-300 text-gray-700 text-sm font-medium px-4 py-2 hover:bg-gray-50 transition-colors"
          >
            Limpiar
          </Link>
        </div>
      </form>

      {filas.length === 0 ? (
        <div className="text-center py-16 bg-white rounded-xl border border-gray-200">
          <p className="text-gray-500 text-lg">No hay registros que coincidan con los filtros.</p>
        </div>
      ) : (
        <div className="bg-white rounded-xl border border-gray-200 shadow-sm overflow-hidden">
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wide">
                    Fecha
                  </th>
                  <th className="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wide">
                    Op
                  </th>
                  <th className="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wide">
                    Tabla
                  </th>
                  <th className="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wide">
                    Id registro
                  </th>
                  <th className="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wide">
                    Usuario DB
                  </th>
                  <th className="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wide">
                    Usuario app
                  </th>
                  <th className="px-4 py-3 text-right text-xs font-semibold text-gray-500 uppercase tracking-wide">
                    Detalle
                  </th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100">
                {filas.map((row) => {
                  const fecha = new Date(row.fecha_hora).toLocaleString('es-AR', {
                    day: '2-digit',
                    month: '2-digit',
                    year: 'numeric',
                    hour: '2-digit',
                    minute: '2-digit',
                    second: '2-digit',
                  })
                  const op = TIPO_OP_LABEL[row.tipo_op] ?? {
                    label: row.tipo_op,
                    clase: 'bg-gray-50 text-gray-700 border-gray-200',
                  }
                  return (
                    <tr key={row.id_audit} className="hover:bg-gray-50 transition-colors">
                      <td className="px-4 py-3 text-sm text-gray-700 whitespace-nowrap">
                        {fecha}
                      </td>
                      <td className="px-4 py-3">
                        <span
                          className={`inline-flex items-center text-xs font-semibold px-2 py-0.5 rounded-full border ${op.clase}`}
                        >
                          {op.label}
                        </span>
                      </td>
                      <td className="px-4 py-3 text-sm text-gray-900 font-medium">{row.tabla}</td>
                      <td className="px-4 py-3 text-sm text-gray-500 font-mono">
                        {row.id_registro ?? '—'}
                      </td>
                      <td className="px-4 py-3 text-sm text-gray-500 font-mono">
                        {row.usuario_db}
                      </td>
                      <td className="px-4 py-3 text-xs text-gray-500 font-mono">
                        {row.usuario_app ?? '—'}
                      </td>
                      <td className="px-4 py-3 text-right">
                        <Link
                          href={`/admin/auditoria/${row.id_audit}`}
                          className="text-sm font-medium text-blue-600 hover:text-blue-800"
                        >
                          Ver →
                        </Link>
                      </td>
                    </tr>
                  )
                })}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* Paginacion */}
      {totalPaginas > 1 && (
        <div className="flex items-center justify-between mt-4">
          <div className="text-sm text-gray-500">
            Mostrando {from + 1}-{Math.min(to + 1, total)} de {total}
          </div>
          <div className="flex items-center gap-2">
            {pagina > 1 ? (
              <Link
                href={buildHref(pagina - 1)}
                className="rounded-lg border border-gray-300 text-gray-700 text-sm font-medium px-3 py-1.5 hover:bg-gray-50 transition-colors"
              >
                ← Anterior
              </Link>
            ) : (
              <span className="rounded-lg border border-gray-200 text-gray-300 text-sm font-medium px-3 py-1.5 cursor-not-allowed">
                ← Anterior
              </span>
            )}
            <span className="text-sm text-gray-500 px-2">
              {pagina} / {totalPaginas}
            </span>
            {pagina < totalPaginas ? (
              <Link
                href={buildHref(pagina + 1)}
                className="rounded-lg border border-gray-300 text-gray-700 text-sm font-medium px-3 py-1.5 hover:bg-gray-50 transition-colors"
              >
                Siguiente →
              </Link>
            ) : (
              <span className="rounded-lg border border-gray-200 text-gray-300 text-sm font-medium px-3 py-1.5 cursor-not-allowed">
                Siguiente →
              </span>
            )}
          </div>
        </div>
      )}
    </div>
  )
}
