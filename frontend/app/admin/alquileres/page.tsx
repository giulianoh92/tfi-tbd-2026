import { createClient } from '@/lib/supabase/server'
import Link from 'next/link'
import { Plus, ArrowRight } from 'lucide-react'
import type { Alquiler, Vehiculo, Cliente } from '@/types/database'
import { Card } from '@/components/ui/Card'
import { Badge } from '@/components/ui/Badge'
import { formatDateAR, diasHasta } from '@/lib/format'

type AlquilerConDetalles = Alquiler & {
  vehiculo: Pick<Vehiculo, 'marca' | 'modelo' | 'patente' | 'id_sucursal_origen'> | null
  cliente: Pick<Cliente, 'nombre' | 'apellido' | 'dni'> | null
}

/**
 * Lista todos los alquileres con estado 'activo'.
 * RLS policy alquiler_staff_all garantiza acceso solo a usuarios staff.
 */
export default async function AlquileresPage() {
  const supabase = await createClient()

  // Join directo: alquiler→vehiculo (FK única) y alquiler→cliente (FK única).
  const { data: alquileres, error } = await supabase
    .from('alquiler')
    .select(`
      *,
      vehiculo ( marca, modelo, patente, id_sucursal_origen ),
      cliente ( nombre, apellido, dni )
    `)
    .eq('estado', 'activo')
    .order('fecha_inicio')

  if (error) {
    return (
      <div role="alert" className="rounded-lg bg-danger-bg border border-danger-border p-6">
        <p className="text-danger-fg font-medium">Error al cargar alquileres</p>
        <p className="text-danger-fg/80 text-sm mt-1">{error.message}</p>
      </div>
    )
  }

  const filas = (alquileres ?? []) as AlquilerConDetalles[]

  return (
    <div>
      <div className="flex flex-wrap items-end justify-between gap-4 mb-8">
        <div>
          <h1 className="font-display text-3xl font-bold text-slate-900">Alquileres activos</h1>
          <p className="text-muted-fg mt-1 text-sm">
            {filas.length} alquiler{filas.length !== 1 ? 'es' : ''} en curso
          </p>
        </div>
        <Link
          href="/admin/alquileres/nuevo"
          className="inline-flex items-center gap-1 px-4 py-2 bg-brand-600 text-white text-sm font-semibold rounded-lg hover:bg-brand-700 transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand-500 focus-visible:ring-offset-2"
        >
          <Plus className="w-4 h-4" aria-hidden="true" />
          Nuevo alquiler
        </Link>
      </div>

      {filas.length === 0 ? (
        <Card variant="raised" className="text-center py-16">
          <p className="text-muted-fg text-lg">No hay alquileres activos en este momento.</p>
        </Card>
      ) : (
        <Card variant="raised" className="overflow-hidden p-0">
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-slate-200">
              <thead className="bg-slate-50">
                <tr>
                  <Th>Vehículo</Th>
                  <Th>Cliente</Th>
                  <Th>Fecha inicio</Th>
                  <Th>Fecha fin prevista</Th>
                  <Th>Restantes</Th>
                  <Th>Km inicio</Th>
                  <Th align="right">Acción</Th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {filas.map((a) => {
                  const dias = diasHasta(a.fecha_fin_prevista)
                  return (
                    <tr key={a.id_alquiler} className="hover:bg-slate-50 transition-colors">
                      <td className="px-5 py-4">
                        <p className="font-medium text-slate-900 text-sm">
                          {a.vehiculo
                            ? `${a.vehiculo.marca} ${a.vehiculo.modelo}`
                            : `Vehículo #${a.id_vehiculo}`}
                        </p>
                        {a.vehiculo && (
                          <p className="text-muted-fg text-xs">{a.vehiculo.patente}</p>
                        )}
                      </td>
                      <td className="px-5 py-4">
                        <p className="text-sm text-slate-900">
                          {a.cliente
                            ? `${a.cliente.nombre} ${a.cliente.apellido}`
                            : `Cliente #${a.id_cliente}`}
                        </p>
                        {a.cliente && (
                          <p className="text-muted-fg text-xs">DNI {a.cliente.dni}</p>
                        )}
                      </td>
                      <td className="px-5 py-4 text-sm text-slate-700 tabular-nums">
                        {formatDateAR(a.fecha_inicio)}
                      </td>
                      <td className="px-5 py-4 text-sm text-slate-700 tabular-nums">
                        {formatDateAR(a.fecha_fin_prevista)}
                      </td>
                      <td className="px-5 py-4 text-sm">
                        <RestantesBadge dias={dias} />
                      </td>
                      <td className="px-5 py-4 text-sm text-slate-700 tabular-nums">
                        {a.km_inicio.toLocaleString('es-AR')} km
                      </td>
                      <td className="px-5 py-4 text-right">
                        <Link
                          href={`/admin/alquileres/${a.id_alquiler}/cerrar`}
                          className="inline-flex items-center gap-1 px-3 py-1.5 bg-orange-600 text-white text-xs font-semibold rounded-lg hover:bg-orange-700 transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand-500"
                        >
                          Cerrar
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
      className={`px-5 py-3 text-xs font-semibold text-muted-fg uppercase tracking-wider ${
        align === 'right' ? 'text-right' : 'text-left'
      }`}
    >
      {children}
    </th>
  )
}

function RestantesBadge({ dias }: { dias: number }) {
  if (dias < 0) return <Badge variant="danger">Vencido ({dias}d)</Badge>
  if (dias === 0) return <Badge variant="danger">Hoy</Badge>
  if (dias <= 1) return <Badge variant="danger">{dias} día</Badge>
  if (dias <= 3) return <Badge variant="warning">{dias} días</Badge>
  return <Badge variant="success">{dias} días</Badge>
}
