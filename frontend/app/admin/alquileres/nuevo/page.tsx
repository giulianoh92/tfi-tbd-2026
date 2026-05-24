import { createClient } from '@/lib/supabase/server'
import { NuevoAlquilerForm } from '@/components/NuevoAlquilerForm'
import type { Cliente, Vehiculo, Tarifa, Reserva } from '@/types/database'

type ReservaPendiente = Pick<
  Reserva,
  'id_reserva' | 'id_cliente' | 'id_vehiculo' | 'fecha_inicio' | 'fecha_fin_prevista'
> & {
  cliente: Pick<Cliente, 'nombre' | 'apellido' | 'dni'> | null
  vehiculo: Pick<Vehiculo, 'marca' | 'modelo' | 'patente' | 'km_actuales'> | null
}

/**
 * Pagina staff: alta de alquiler.
 * Sprint 3 (R3, R6). Carga en paralelo:
 *   - reservas pendientes (para la rama "con reserva previa")
 *   - clientes y vehiculos disponibles (para walk-in)
 *   - tarifas
 * Delega el form interactivo a `NuevoAlquilerForm` (client component) que
 * invoca el procedure `pa_registrar_alquiler` via RPC.
 */
export default async function NuevoAlquilerPage() {
  const supabase = await createClient()

  // Resolver id_estado de 'disponible' para filtrar la flota en walk-in.
  const { data: estadoDisp } = await supabase
    .from('estado_vehiculo')
    .select('id_estado')
    .eq('nombre', 'disponible')
    .single()

  const idEstadoDisp = estadoDisp?.id_estado ?? null

  const [reservasRes, clientesRes, vehiculosRes, tarifasRes] = await Promise.all([
    supabase
      .from('reserva')
      .select(`
        id_reserva,
        id_cliente,
        id_vehiculo,
        fecha_inicio,
        fecha_fin_prevista,
        cliente ( nombre, apellido, dni ),
        vehiculo ( marca, modelo, patente, km_actuales )
      `)
      .eq('estado', 'pendiente')
      .order('fecha_inicio'),
    supabase
      .from('cliente')
      .select('id_cliente, nombre, apellido, dni')
      .order('apellido'),
    // Si idEstadoDisp es null fallamos al filtro mas inocuo (todos los
    // vehiculos). El procedure rechazara igualmente los no-disponibles.
    idEstadoDisp !== null
      ? supabase
          .from('vehiculo')
          .select('id_vehiculo, marca, modelo, patente, km_actuales')
          .eq('id_estado', idEstadoDisp)
          .order('marca')
      : supabase
          .from('vehiculo')
          .select('id_vehiculo, marca, modelo, patente, km_actuales')
          .order('marca'),
    supabase
      .from('tarifa')
      .select('*')
      .order('id_tarifa'),
  ])

  const errores = [reservasRes.error, clientesRes.error, vehiculosRes.error, tarifasRes.error].filter(Boolean)
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

  const reservasPendientes = (reservasRes.data ?? []) as ReservaPendiente[]
  const clientes = (clientesRes.data ?? []) as Pick<
    Cliente,
    'id_cliente' | 'nombre' | 'apellido' | 'dni'
  >[]
  const vehiculos = (vehiculosRes.data ?? []) as Pick<
    Vehiculo,
    'id_vehiculo' | 'marca' | 'modelo' | 'patente' | 'km_actuales'
  >[]
  const tarifas = (tarifasRes.data ?? []) as Tarifa[]

  return (
    <div className="max-w-2xl mx-auto">
      <div className="mb-8">
        <h1 className="font-display text-2xl font-bold text-slate-900">Registrar alquiler</h1>
        <p className="text-muted-fg mt-1 text-sm">
          Con reserva previa o walk-in (sin reserva).
        </p>
      </div>

      <NuevoAlquilerForm
        reservasPendientes={reservasPendientes}
        clientes={clientes}
        vehiculos={vehiculos}
        tarifas={tarifas}
      />
    </div>
  )
}
