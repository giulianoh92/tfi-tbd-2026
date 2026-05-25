import { createClient } from '@/lib/supabase/server'
import Link from 'next/link'
import { Plus, ArrowRight } from 'lucide-react'
import type { Mantenimiento, Taller, Vehiculo } from '@/types/database'
import { Card } from '@/components/ui/Card'
import { Badge } from '@/components/ui/Badge'
import { formatDateAR } from '@/lib/format'

type MantenimientoConDetalles = Mantenimiento & {
  vehiculo: Pick<Vehiculo, 'id_vehiculo' | 'marca' | 'modelo' | 'patente'> | null
  taller: Pick<Taller, 'id_taller' | 'nombre' | 'direccion'> | null
}

/**
 * Listado de mantenimientos (CU-07 / CU-08).
 *
 * Dos secciones:
 *   - Vigentes: fecha_devolucion IS NULL. Permiten registrar la devolucion.
 *   - Historicos: fecha_devolucion IS NOT NULL. Solo consulta.
 *
 * Las FK son unicas asi que el join implicito de PostgREST funciona sin alias.
 */
export default async function MantenimientosPage() {
  const supabase = await createClient()

  const { data, error } = await supabase
    .from('mantenimiento')
    .select(
      `
      id_mantenimiento,
      id_vehiculo,
      id_taller,
      fecha_envio,
      fecha_devolucion,
      observaciones,
      vehiculo ( id_vehiculo, marca, modelo, patente ),
      taller ( id_taller, nombre, direccion )
    `,
    )
    .order('fecha_envio', { ascending: false })

  if (error) {
    return (
      <div role="alert" className="rounded-lg bg-danger-bg border border-danger-border p-6">
        <p className="text-danger-fg font-medium">Error al cargar mantenimientos</p>
        <p className="text-danger-fg/80 text-sm mt-1">{error.message}</p>
      </div>
    )
  }

  const filas = (data ?? []) as MantenimientoConDetalles[]
  const vigentes = filas.filter((m) => m.fecha_devolucion == null)
  const historicos = filas.filter((m) => m.fecha_devolucion != null)

  return (
    <div>
      <div className="flex flex-wrap items-end justify-between gap-4 mb-8">
        <div>
          <h1 className="font-display text-3xl font-bold text-slate-900">Mantenimientos</h1>
          <p className="text-muted-fg mt-1 text-sm">
            {vigentes.length} en taller · {historicos.length} histórico
            {historicos.length !== 1 ? 's' : ''}
          </p>
        </div>
        <Link
          href="/admin/mantenimientos/nuevo"
          className="inline-flex items-center gap-1 px-4 py-2 bg-brand-600 text-white text-sm font-semibold rounded-lg hover:bg-brand-700 transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand-500 focus-visible:ring-offset-2"
        >
          <Plus className="w-4 h-4" aria-hidden="true" />
          Nuevo envío
        </Link>
      </div>

      {/* Vigentes */}
      <section className="mb-10">
        <div className="flex items-center gap-2 mb-3">
          <h2 className="font-display text-lg font-semibold text-slate-900">
            En taller
          </h2>
          <Badge variant={vigentes.length > 0 ? 'warning' : 'muted'}>
            {vigentes.length}
          </Badge>
        </div>

        {vigentes.length === 0 ? (
          <Card variant="raised" className="text-center py-12">
            <p className="text-muted-fg text-sm">
              No hay vehículos en taller en este momento.
            </p>
          </Card>
        ) : (
          <Card variant="raised" className="overflow-hidden p-0">
            <div className="overflow-x-auto">
              <table className="min-w-full divide-y divide-slate-200">
                <thead className="bg-slate-50">
                  <tr>
                    <Th>Vehículo</Th>
                    <Th>Taller</Th>
                    <Th>Fecha envío</Th>
                    <Th>Observaciones</Th>
                    <Th align="right">Acción</Th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100">
                  {vigentes.map((m) => (
                    <tr key={m.id_mantenimiento} className="hover:bg-slate-50 transition-colors">
                      <td className="px-5 py-4">
                        <p className="font-medium text-slate-900 text-sm">
                          {m.vehiculo
                            ? `${m.vehiculo.marca} ${m.vehiculo.modelo}`
                            : `Vehículo #${m.id_vehiculo}`}
                        </p>
                        {m.vehiculo && (
                          <p className="text-muted-fg text-xs font-mono">{m.vehiculo.patente}</p>
                        )}
                      </td>
                      <td className="px-5 py-4">
                        <p className="text-sm text-slate-900">
                          {m.taller?.nombre ?? `Taller #${m.id_taller}`}
                        </p>
                        {m.taller && (
                          <p className="text-muted-fg text-xs">{m.taller.direccion}</p>
                        )}
                      </td>
                      <td className="px-5 py-4 text-sm text-slate-700 tabular-nums whitespace-nowrap">
                        {formatDateAR(m.fecha_envio)}
                      </td>
                      <td className="px-5 py-4 text-sm text-slate-700 max-w-xs">
                        <p className="line-clamp-2">{m.observaciones ?? '—'}</p>
                      </td>
                      <td className="px-5 py-4 text-right">
                        <Link
                          href={`/admin/mantenimientos/${m.id_mantenimiento}/devolucion`}
                          className="inline-flex items-center gap-1 px-3 py-1.5 bg-orange-600 text-white text-xs font-semibold rounded-lg hover:bg-orange-700 transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand-500"
                        >
                          Registrar devolución
                          <ArrowRight className="w-3.5 h-3.5" aria-hidden="true" />
                        </Link>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </Card>
        )}
      </section>

      {/* Historicos */}
      <section>
        <div className="flex items-center gap-2 mb-3">
          <h2 className="font-display text-lg font-semibold text-slate-900">Histórico</h2>
          <Badge variant="muted">{historicos.length}</Badge>
        </div>

        {historicos.length === 0 ? (
          <Card variant="raised" className="text-center py-12">
            <p className="text-muted-fg text-sm">Sin mantenimientos cerrados aún.</p>
          </Card>
        ) : (
          <Card variant="raised" className="overflow-hidden p-0">
            <div className="overflow-x-auto max-h-[28rem] overflow-y-auto">
              <table className="min-w-full divide-y divide-slate-200">
                <thead className="bg-slate-50 sticky top-0 z-10">
                  <tr>
                    <Th>Vehículo</Th>
                    <Th>Taller</Th>
                    <Th>Fecha envío</Th>
                    <Th>Fecha devolución</Th>
                    <Th>Observaciones</Th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100">
                  {historicos.map((m) => (
                    <tr key={m.id_mantenimiento} className="hover:bg-slate-50 transition-colors">
                      <td className="px-5 py-3">
                        <p className="font-medium text-slate-900 text-sm">
                          {m.vehiculo
                            ? `${m.vehiculo.marca} ${m.vehiculo.modelo}`
                            : `Vehículo #${m.id_vehiculo}`}
                        </p>
                        {m.vehiculo && (
                          <p className="text-muted-fg text-xs font-mono">{m.vehiculo.patente}</p>
                        )}
                      </td>
                      <td className="px-5 py-3 text-sm text-slate-700">
                        {m.taller?.nombre ?? `Taller #${m.id_taller}`}
                      </td>
                      <td className="px-5 py-3 text-sm text-slate-700 tabular-nums whitespace-nowrap">
                        {formatDateAR(m.fecha_envio)}
                      </td>
                      <td className="px-5 py-3 text-sm text-slate-700 tabular-nums whitespace-nowrap">
                        {formatDateAR(m.fecha_devolucion)}
                      </td>
                      <td className="px-5 py-3 text-sm text-slate-700 max-w-xs">
                        <p className="line-clamp-2">{m.observaciones ?? '—'}</p>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </Card>
        )}
      </section>
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
      className={`px-5 py-3 text-xs font-semibold text-muted-fg uppercase tracking-wider ${
        align === 'right' ? 'text-right' : align === 'center' ? 'text-center' : 'text-left'
      }`}
    >
      {children}
    </th>
  )
}
