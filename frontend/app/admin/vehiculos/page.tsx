import { createClient } from '@/lib/supabase/server'
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
      <div role="alert" className="rounded-lg bg-danger-bg border border-danger-border p-6">
        <p className="text-danger-fg font-medium">Error al cargar la flota</p>
        <ul className="text-danger-fg/80 text-sm mt-1 list-disc list-inside">
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
      <div className="mb-6">
        <h1 className="font-display text-3xl font-bold text-slate-900">Flota</h1>
        <p className="text-muted-fg mt-1 text-sm">
          Gestiona altas, ediciones y bajas de la flota.
        </p>
      </div>

      <VehiculosAdminClient
        vehiculos={vehiculos}
        sucursales={sucursales}
        tiposVehiculo={tipos}
      />
    </div>
  )
}
