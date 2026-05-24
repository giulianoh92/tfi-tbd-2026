import { createClient } from '@/lib/supabase/server'
import Link from 'next/link'
import { VehiculosAdminClient } from '@/components/VehiculosAdminClient'
import type {
  Vehiculo,
  Sucursal,
  TipoVehiculo,
  EstadoVehiculo,
} from '@/types/database'

type VehiculoConRefs = Vehiculo & {
  estado_vehiculo: Pick<EstadoVehiculo, 'nombre'> | null
  tipo_vehiculo: Pick<TipoVehiculo, 'nombre'> | null
  sucursal: Pick<Sucursal, 'nombre'> | null
}

/**
 * Pagina staff: gestion de flota (Sprint 3 - R3).
 * Listado con acciones crear / editar / dar de baja, todas via SP.
 *
 * Acceso: el AdminLayout ya valida JWT con role=staff. Las mutaciones
 * pasan por procedures que vuelven a chequear fn_es_staff() (defensa en
 * profundidad).
 */
export default async function VehiculosPage() {
  const supabase = await createClient()

  const [vehiculosRes, sucursalesRes, tiposRes] = await Promise.all([
    supabase
      .from('vehiculo')
      .select(`
        *,
        estado_vehiculo ( nombre ),
        tipo_vehiculo ( nombre ),
        sucursal ( nombre )
      `)
      .order('patente'),
    supabase
      .from('sucursal')
      .select('id_sucursal, nombre, direccion, telefono')
      .order('nombre'),
    supabase
      .from('tipo_vehiculo')
      .select('id_tipo, nombre, descripcion')
      .order('nombre'),
  ])

  const errores = [vehiculosRes.error, sucursalesRes.error, tiposRes.error].filter(Boolean)
  if (errores.length > 0) {
    return (
      <div className="rounded-lg bg-red-50 border border-red-200 p-6">
        <p className="text-red-700 font-medium">Error al cargar la flota</p>
        <ul className="text-red-500 text-sm mt-1 list-disc list-inside">
          {errores.map((e, i) => (
            <li key={i}>{e?.message ?? 'desconocido'}</li>
          ))}
        </ul>
      </div>
    )
  }

  const vehiculos = (vehiculosRes.data ?? []) as VehiculoConRefs[]
  const sucursales = (sucursalesRes.data ?? []) as Sucursal[]
  const tipos = (tiposRes.data ?? []) as TipoVehiculo[]

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Flota</h1>
          <p className="text-gray-500 mt-1 text-sm">
            CRUD de vehiculos via stored procedures.
          </p>
        </div>
        <Link
          href="/admin"
          className="text-sm text-blue-600 hover:text-blue-800 font-medium"
        >
          ← Panel
        </Link>
      </div>

      <VehiculosAdminClient
        vehiculos={vehiculos}
        sucursales={sucursales}
        tiposVehiculo={tipos}
      />
    </div>
  )
}
