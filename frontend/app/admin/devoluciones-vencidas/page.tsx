import { createClient } from '@/lib/supabase/server'
import Link from 'next/link'
import { MarcarNotificadoButton } from '@/components/MarcarNotificadoButton'
import type { DevolucionVencida, Vehiculo, Cliente } from '@/types/database'

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
 *
 * Lista las filas que el job pa_detectar_devoluciones_vencidas detecto en
 * sus ultimas pasadas. El staff puede toggle el flag `notificado` cuando
 * contacta al cliente.
 *
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

  if (filtro === 'pendientes') {
    query = query.eq('notificado', false)
  } else if (filtro === 'notificadas') {
    query = query.eq('notificado', true)
  }

  const { data, error, count } = await query

  if (error) {
    return (
      <div className="rounded-lg bg-red-50 border border-red-200 p-6">
        <p className="text-red-700 font-medium">
          Error al cargar las devoluciones vencidas
        </p>
        <p className="text-red-500 text-sm mt-1">{error.message}</p>
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
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">
            Devoluciones vencidas
          </h1>
          <p className="text-gray-500 mt-1 text-sm">
            {total.toLocaleString('es-AR')} detección{total !== 1 ? 'es' : ''}{' '}
            registrada{total !== 1 ? 's' : ''}. Página {pagina} de {totalPaginas}.
          </p>
          <p className="text-gray-400 mt-1 text-xs">
            El job <code className="font-mono">detectar-devoluciones-vencidas</code>{' '}
            corre cada 6 horas (pg_cron).
          </p>
        </div>
        <Link
          href="/admin"
          className="text-sm text-blue-600 hover:text-blue-800 font-medium"
        >
          ← Panel
        </Link>
      </div>

      {/* Tabs de filtro */}
      <div className="flex items-center gap-2 mb-6">
        {(['todas', 'pendientes', 'notificadas'] as const).map((t) => {
          const activo = filtro === t
          return (
            <Link
              key={t}
              href={buildHref(t, 1)}
              className={
                activo
                  ? 'px-3 py-1.5 rounded-lg text-sm font-medium bg-blue-600 text-white'
                  : 'px-3 py-1.5 rounded-lg text-sm font-medium border border-gray-300 text-gray-700 hover:bg-gray-50'
              }
            >
              {t === 'todas'
                ? 'Todas'
                : t === 'pendientes'
                  ? 'Pendientes'
                  : 'Notificadas'}
            </Link>
          )
        })}
      </div>

      {filas.length === 0 ? (
        <div className="text-center py-16 bg-white rounded-xl border border-gray-200">
          <p className="text-gray-500 text-lg">
            No hay devoluciones vencidas que coincidan con el filtro.
          </p>
        </div>
      ) : (
        <div className="bg-white rounded-xl border border-gray-200 shadow-sm overflow-hidden">
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wide">
                    Detectado
                  </th>
                  <th className="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wide">
                    Cliente
                  </th>
                  <th className="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wide">
                    Vehículo
                  </th>
                  <th className="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wide">
                    Fecha prevista
                  </th>
                  <th className="px-4 py-3 text-right text-xs font-semibold text-gray-500 uppercase tracking-wide">
                    Hs excedidas
                  </th>
                  <th className="px-4 py-3 text-center text-xs font-semibold text-gray-500 uppercase tracking-wide">
                    Estado
                  </th>
                  <th className="px-4 py-3 text-right text-xs font-semibold text-gray-500 uppercase tracking-wide">
                    Acción
                  </th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100">
                {filas.map((row) => {
                  const fechaDeteccion = new Date(
                    row.fecha_deteccion
                  ).toLocaleString('es-AR', {
                    day: '2-digit',
                    month: '2-digit',
                    year: 'numeric',
                    hour: '2-digit',
                    minute: '2-digit',
                  })
                  const fechaPrevista = new Date(
                    row.fecha_fin_prevista
                  ).toLocaleString('es-AR', {
                    day: '2-digit',
                    month: '2-digit',
                    year: 'numeric',
                    hour: '2-digit',
                    minute: '2-digit',
                  })

                  return (
                    <tr
                      key={row.id_devolucion_vencida}
                      className="hover:bg-gray-50 transition-colors"
                    >
                      <td className="px-4 py-3 text-sm text-gray-700 whitespace-nowrap">
                        {fechaDeteccion}
                      </td>
                      <td className="px-4 py-3">
                        <p className="text-sm text-gray-900">
                          {row.cliente
                            ? `${row.cliente.nombre} ${row.cliente.apellido}`
                            : `Cliente #${row.id_cliente}`}
                        </p>
                        {row.cliente && (
                          <p className="text-gray-400 text-xs">
                            DNI {row.cliente.dni}
                          </p>
                        )}
                      </td>
                      <td className="px-4 py-3">
                        <p className="font-medium text-gray-900 text-sm">
                          {row.vehiculo
                            ? `${row.vehiculo.marca} ${row.vehiculo.modelo}`
                            : `Vehículo #${row.id_vehiculo}`}
                        </p>
                        {row.vehiculo && (
                          <p className="text-gray-400 text-xs font-mono">
                            {row.vehiculo.patente}
                          </p>
                        )}
                      </td>
                      <td className="px-4 py-3 text-sm text-gray-700 whitespace-nowrap">
                        {fechaPrevista}
                      </td>
                      <td className="px-4 py-3 text-right text-sm text-gray-900 font-mono">
                        {Number(row.horas_excedidas).toLocaleString('es-AR', {
                          maximumFractionDigits: 2,
                        })}
                      </td>
                      <td className="px-4 py-3 text-center">
                        {row.notificado ? (
                          <span className="inline-flex items-center text-xs font-semibold px-2 py-0.5 rounded-full border bg-green-50 text-green-700 border-green-200">
                            Notificado
                          </span>
                        ) : (
                          <span className="inline-flex items-center text-xs font-semibold px-2 py-0.5 rounded-full border bg-yellow-50 text-yellow-700 border-yellow-200">
                            Pendiente
                          </span>
                        )}
                      </td>
                      <td className="px-4 py-3 text-right">
                        <MarcarNotificadoButton
                          idDevolucionVencida={row.id_devolucion_vencida}
                          notificado={row.notificado}
                        />
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
                href={buildHref(filtro, pagina - 1)}
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
                href={buildHref(filtro, pagina + 1)}
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
