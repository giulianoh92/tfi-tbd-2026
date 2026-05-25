import { createClient } from '@/lib/supabase/server'
import { NuevoMantenimientoForm } from '@/components/NuevoMantenimientoForm'
import type { Sucursal, Taller, UbicacionVehiculo, Vehiculo } from '@/types/database'

// Mismo shape minimo que NuevoAlquilerForm usa para vehiculos elegibles.
export interface VehiculoDisponible
  extends Pick<
    Vehiculo,
    'id_vehiculo' | 'marca' | 'modelo' | 'patente' | 'km_actuales' | 'id_sucursal_origen'
  > {}

export type UbicacionVigente = Pick<UbicacionVehiculo, 'id_vehiculo' | 'id_sucursal'>

/**
 * Pagina staff: enviar vehiculo a mantenimiento (CU-07).
 *
 * Carga en paralelo:
 *   - Vehiculos en estado 'disponible' (solo esos pueden enviarse).
 *   - Talleres disponibles.
 *   - Sucursales + ubicaciones vigentes para mostrar "donde esta hoy" el
 *     vehiculo en el dropdown (ayuda al staff a elegir taller cercano).
 *
 * No usamos vw_vehiculos_disponibles porque no esta en los types regenerados
 * de Supabase (Views: never). Replicamos el patron de /alquileres/nuevo.
 */
export default async function NuevoMantenimientoPage() {
  const supabase = await createClient()

  const { data: estadoDisp } = await supabase
    .from('estado_vehiculo')
    .select('id_estado')
    .eq('nombre', 'disponible')
    .single<{ id_estado: number }>()

  const idEstadoDisp = estadoDisp?.id_estado ?? null

  const [vehiculosRes, talleresRes, sucursalesRes, ubicacionesRes] = await Promise.all([
    idEstadoDisp !== null
      ? supabase
          .from('vehiculo')
          .select(
            'id_vehiculo, marca, modelo, patente, km_actuales, id_sucursal_origen',
          )
          .eq('id_estado', idEstadoDisp)
          .order('marca')
      : supabase
          .from('vehiculo')
          .select(
            'id_vehiculo, marca, modelo, patente, km_actuales, id_sucursal_origen',
          )
          .order('marca'),
    supabase.from('taller').select('id_taller, nombre, direccion, telefono').order('nombre'),
    supabase.from('sucursal').select('id_sucursal, nombre, ciudad, direccion, telefono'),
    supabase
      .from('ubicacion_vehiculo')
      .select('id_vehiculo, id_sucursal')
      .is('fecha_hasta', null),
  ])

  const errores = [
    vehiculosRes.error,
    talleresRes.error,
    sucursalesRes.error,
    ubicacionesRes.error,
  ].filter(Boolean)
  if (errores.length > 0) {
    return (
      <div role="alert" className="rounded-lg bg-danger-bg border border-danger-border p-6">
        <p className="text-danger-fg font-medium">Error al cargar datos</p>
        <ul className="text-danger-fg/80 text-sm mt-1 list-disc list-inside">
          {errores.map((e, i) => (
            <li key={i}>{e?.message ?? 'desconocido'}</li>
          ))}
        </ul>
      </div>
    )
  }

  const vehiculos = (vehiculosRes.data ?? []) as VehiculoDisponible[]
  const talleres = (talleresRes.data ?? []) as Taller[]
  const sucursales = (sucursalesRes.data ?? []) as Sucursal[]
  const ubicacionesVigentes = (ubicacionesRes.data ?? []) as UbicacionVigente[]

  return (
    <div className="max-w-2xl mx-auto">
      <div className="mb-8">
        <h1 className="font-display text-2xl font-bold text-slate-900">
          Enviar vehículo a mantenimiento
        </h1>
        <p className="text-muted-fg mt-1 text-sm">
          Solo se listan vehículos en estado <strong>disponible</strong>. El envío
          deja al vehículo bloqueado para alquileres hasta su devolución.
        </p>
      </div>

      <NuevoMantenimientoForm
        vehiculos={vehiculos}
        talleres={talleres}
        sucursales={sucursales}
        ubicacionesVigentes={ubicacionesVigentes}
      />
    </div>
  )
}
