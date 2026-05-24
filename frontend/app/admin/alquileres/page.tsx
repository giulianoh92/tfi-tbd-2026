import { createClient } from '@/lib/supabase/server'
import Link from 'next/link'
import type { Alquiler, Vehiculo, Cliente } from '@/types/database'

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
  // No se usan hints de constraint porque no hay ambigüedad.
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
      <div className="rounded-lg bg-red-50 border border-red-200 p-6">
        <p className="text-red-700 font-medium">Error al cargar alquileres</p>
        <p className="text-red-500 text-sm mt-1">{error.message}</p>
      </div>
    )
  }

  const filas = (alquileres ?? []) as AlquilerConDetalles[]

  return (
    <div>
      <div className="flex items-center justify-between mb-8">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Alquileres activos</h1>
          <p className="text-gray-500 mt-1 text-sm">
            {filas.length} alquiler{filas.length !== 1 ? 'es' : ''} en curso
          </p>
        </div>
        <div className="flex items-center gap-4">
          <Link
            href="/admin/alquileres/nuevo"
            className="inline-flex items-center px-4 py-2 bg-blue-600 text-white text-sm font-semibold rounded-lg hover:bg-blue-700 transition-colors"
          >
            + Nuevo alquiler
          </Link>
          <Link
            href="/admin"
            className="text-sm text-blue-600 hover:text-blue-800 font-medium"
          >
            ← Panel
          </Link>
        </div>
      </div>

      {filas.length === 0 ? (
        <div className="text-center py-16">
          <p className="text-gray-500 text-lg">No hay alquileres activos en este momento.</p>
        </div>
      ) : (
        <div className="bg-white rounded-xl border border-gray-200 shadow-sm overflow-hidden">
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-5 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wide">
                    Vehículo
                  </th>
                  <th className="px-5 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wide">
                    Cliente
                  </th>
                  <th className="px-5 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wide">
                    Fecha inicio
                  </th>
                  <th className="px-5 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wide">
                    Fecha fin prevista
                  </th>
                  <th className="px-5 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wide">
                    Km inicio
                  </th>
                  <th className="px-5 py-3 text-right text-xs font-semibold text-gray-500 uppercase tracking-wide">
                    Acción
                  </th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100">
                {filas.map((a) => {
                  const fechaInicio = new Date(a.fecha_inicio).toLocaleDateString('es-AR', {
                    day: '2-digit',
                    month: '2-digit',
                    year: 'numeric',
                  })
                  const fechaFin = new Date(a.fecha_fin_prevista).toLocaleDateString('es-AR', {
                    day: '2-digit',
                    month: '2-digit',
                    year: 'numeric',
                  })

                  return (
                    <tr key={a.id_alquiler} className="hover:bg-gray-50 transition-colors">
                      <td className="px-5 py-4">
                        <p className="font-medium text-gray-900 text-sm">
                          {a.vehiculo
                            ? `${a.vehiculo.marca} ${a.vehiculo.modelo}`
                            : `Vehículo #${a.id_vehiculo}`}
                        </p>
                        {a.vehiculo && (
                          <p className="text-gray-400 text-xs">{a.vehiculo.patente}</p>
                        )}
                      </td>
                      <td className="px-5 py-4">
                        <p className="text-sm text-gray-900">
                          {a.cliente
                            ? `${a.cliente.nombre} ${a.cliente.apellido}`
                            : `Cliente #${a.id_cliente}`}
                        </p>
                        {a.cliente && (
                          <p className="text-gray-400 text-xs">DNI {a.cliente.dni}</p>
                        )}
                      </td>
                      <td className="px-5 py-4 text-sm text-gray-700">{fechaInicio}</td>
                      <td className="px-5 py-4 text-sm text-gray-700">{fechaFin}</td>
                      <td className="px-5 py-4 text-sm text-gray-700">
                        {a.km_inicio.toLocaleString('es-AR')} km
                      </td>
                      <td className="px-5 py-4 text-right">
                        <Link
                          href={`/admin/alquileres/${a.id_alquiler}/cerrar`}
                          className="inline-flex items-center px-3 py-1.5 bg-orange-600 text-white text-xs font-semibold rounded-lg hover:bg-orange-700 transition-colors"
                        >
                          Cerrar →
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
    </div>
  )
}
