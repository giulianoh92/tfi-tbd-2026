'use client'

import { useState } from 'react'
import type {
  Vehiculo,
  Sucursal,
  TipoVehiculo,
  EstadoVehiculo,
} from '@/types/database'
import { VehiculoFormModal } from './VehiculoFormModal'
import { BajaVehiculoButton } from './BajaVehiculoButton'

type VehiculoConRefs = Vehiculo & {
  estado_vehiculo: Pick<EstadoVehiculo, 'nombre'> | null
  tipo_vehiculo: Pick<TipoVehiculo, 'nombre'> | null
  sucursal: Pick<Sucursal, 'nombre'> | null
}

interface Props {
  vehiculos: VehiculoConRefs[]
  sucursales: Sucursal[]
  tiposVehiculo: TipoVehiculo[]
}

/**
 * Componente cliente que coordina la lista de vehiculos del panel staff y
 * los modales de crear / editar. La baja se delega a BajaVehiculoButton.
 */
export function VehiculosAdminClient({
  vehiculos,
  sucursales,
  tiposVehiculo,
}: Props) {
  const [modalCrear, setModalCrear] = useState(false)
  const [vehiculoEditar, setVehiculoEditar] = useState<Vehiculo | null>(null)

  return (
    <>
      <div className="flex items-center justify-between mb-6">
        <p className="text-gray-500 text-sm">
          {vehiculos.length} vehiculo{vehiculos.length !== 1 ? 's' : ''} en flota
        </p>
        <button
          type="button"
          onClick={() => setModalCrear(true)}
          className="inline-flex items-center px-4 py-2 bg-blue-600 text-white text-sm font-semibold rounded-lg hover:bg-blue-700 transition-colors"
        >
          + Nuevo vehiculo
        </button>
      </div>

      <div className="bg-white rounded-xl border border-gray-200 shadow-sm overflow-hidden">
        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-gray-200">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-5 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wide">
                  Patente
                </th>
                <th className="px-5 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wide">
                  Marca / Modelo
                </th>
                <th className="px-5 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wide">
                  Año
                </th>
                <th className="px-5 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wide">
                  Tipo
                </th>
                <th className="px-5 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wide">
                  Sucursal
                </th>
                <th className="px-5 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wide">
                  Km
                </th>
                <th className="px-5 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wide">
                  Estado
                </th>
                <th className="px-5 py-3 text-right text-xs font-semibold text-gray-500 uppercase tracking-wide">
                  Acciones
                </th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {vehiculos.map((v) => {
                const estado = v.estado_vehiculo?.nombre ?? '?'
                const esBaja = estado === 'baja'
                return (
                  <tr key={v.id_vehiculo} className="hover:bg-gray-50 transition-colors">
                    <td className="px-5 py-3 font-medium text-gray-900 text-sm">
                      {v.patente}
                    </td>
                    <td className="px-5 py-3 text-sm text-gray-700">
                      {v.marca} {v.modelo}
                    </td>
                    <td className="px-5 py-3 text-sm text-gray-700">{v.anio}</td>
                    <td className="px-5 py-3 text-sm text-gray-700">
                      {v.tipo_vehiculo?.nombre ?? '-'}
                    </td>
                    <td className="px-5 py-3 text-sm text-gray-700">
                      {v.sucursal?.nombre ?? '-'}
                    </td>
                    <td className="px-5 py-3 text-sm text-gray-700">
                      {v.km_actuales.toLocaleString('es-AR')}
                    </td>
                    <td className="px-5 py-3 text-sm">
                      <span
                        className={`inline-flex items-center px-2 py-0.5 rounded text-xs font-medium border ${badgeClass(estado)}`}
                      >
                        {estado}
                      </span>
                    </td>
                    <td className="px-5 py-3 text-right">
                      <div className="flex justify-end gap-3">
                        <button
                          type="button"
                          onClick={() => setVehiculoEditar(v)}
                          disabled={esBaja}
                          className="text-xs font-medium text-blue-600 hover:text-blue-800 hover:underline disabled:opacity-40 disabled:cursor-not-allowed disabled:no-underline"
                        >
                          Editar
                        </button>
                        {!esBaja && (
                          <BajaVehiculoButton
                            idVehiculo={v.id_vehiculo}
                            patente={v.patente}
                          />
                        )}
                      </div>
                    </td>
                  </tr>
                )
              })}
            </tbody>
          </table>
        </div>
      </div>

      <VehiculoFormModal
        modo="crear"
        open={modalCrear}
        onClose={() => setModalCrear(false)}
        sucursales={sucursales}
        tiposVehiculo={tiposVehiculo}
      />

      {vehiculoEditar && (
        <VehiculoFormModal
          modo="editar"
          vehiculo={vehiculoEditar}
          open={true}
          onClose={() => setVehiculoEditar(null)}
          sucursales={sucursales}
          tiposVehiculo={tiposVehiculo}
        />
      )}
    </>
  )
}

function badgeClass(estado: string): string {
  switch (estado) {
    case 'disponible':
      return 'bg-green-50 text-green-700 border-green-200'
    case 'alquilado':
      return 'bg-blue-50 text-blue-700 border-blue-200'
    case 'en_mantenimiento':
      return 'bg-yellow-50 text-yellow-700 border-yellow-200'
    case 'en_traslado':
      return 'bg-purple-50 text-purple-700 border-purple-200'
    case 'baja':
      return 'bg-red-50 text-red-700 border-red-200'
    default:
      return 'bg-gray-50 text-gray-600 border-gray-200'
  }
}
