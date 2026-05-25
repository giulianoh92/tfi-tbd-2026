'use client'

import { useState } from 'react'
import { Pencil, Plus } from 'lucide-react'
import type {
  Vehiculo,
  Sucursal,
  TipoVehiculo,
  EstadoVehiculo,
} from '@/types/database'
import { VehiculoFormModal } from './VehiculoFormModal'
import { BajaVehiculoButton } from './BajaVehiculoButton'
import { Button } from '@/components/ui/Button'
import { Badge } from '@/components/ui/Badge'
import { Card } from '@/components/ui/Card'

type VehiculoConRefs = Vehiculo & {
  estado_vehiculo: Pick<EstadoVehiculo, 'nombre'> | null
  tipo_vehiculo: Pick<TipoVehiculo, 'nombre'> | null
  sucursal: Pick<Sucursal, 'nombre'> | null
}

type BadgeVariant = 'success' | 'info' | 'warning' | 'brand' | 'danger' | 'muted'

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
        <p className="text-muted-fg text-sm">
          {vehiculos.length} vehiculo{vehiculos.length !== 1 ? 's' : ''} en flota
        </p>
        <Button
          type="button"
          variant="primary"
          onClick={() => setModalCrear(true)}
        >
          <Plus className="w-4 h-4" aria-hidden="true" />
          Nuevo vehiculo
        </Button>
      </div>

      <Card variant="raised" className="overflow-hidden p-0">
        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-slate-200">
            <thead className="bg-slate-50">
              <tr>
                <Th>Patente</Th>
                <Th>Marca / Modelo</Th>
                <Th>Año</Th>
                <Th>Tipo</Th>
                <Th>Sucursal</Th>
                <Th>Km</Th>
                <Th>Estado</Th>
                <Th align="right">Acciones</Th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {vehiculos.map((v) => {
                const estado = v.estado_vehiculo?.nombre ?? '?'
                const esBaja = estado === 'baja'
                return (
                  <tr key={v.id_vehiculo} className="hover:bg-slate-50 transition-colors">
                    <td className="px-5 py-3 font-medium text-slate-900 text-sm">
                      {v.patente}
                    </td>
                    <td className="px-5 py-3 text-sm text-slate-700">
                      {v.marca} {v.modelo}
                    </td>
                    <td className="px-5 py-3 text-sm text-slate-700">{v.anio}</td>
                    <td className="px-5 py-3 text-sm text-slate-700">
                      {v.tipo_vehiculo?.nombre ?? '-'}
                    </td>
                    <td className="px-5 py-3 text-sm text-slate-700">
                      {v.sucursal?.nombre ?? '-'}
                    </td>
                    <td className="px-5 py-3 text-sm text-slate-700 tabular-nums">
                      {v.km_actuales.toLocaleString('es-AR')}
                    </td>
                    <td className="px-5 py-3 text-sm">
                      <Badge variant={badgeVariant(estado)}>{estado}</Badge>
                    </td>
                    <td className="px-5 py-3 text-right whitespace-nowrap">
                      <div className="flex justify-end gap-2">
                        <Button
                          type="button"
                          variant="ghost"
                          size="sm"
                          onClick={() => setVehiculoEditar(v)}
                          disabled={esBaja}
                          aria-label={`Editar vehiculo ${v.patente}`}
                        >
                          <Pencil className="w-4 h-4" aria-hidden="true" />
                          Editar
                        </Button>
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
      </Card>

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

function badgeVariant(estado: string): BadgeVariant {
  switch (estado) {
    case 'disponible':       return 'success'
    case 'alquilado':        return 'info'
    case 'en_mantenimiento': return 'warning'
    case 'en_traslado':      return 'brand'
    case 'baja':             return 'danger'
    default:                 return 'muted'
  }
}
