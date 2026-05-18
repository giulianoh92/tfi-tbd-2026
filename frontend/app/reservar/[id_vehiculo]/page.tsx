import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import { ReservaForm } from '@/components/ReservaForm'
import type { Vehiculo, TipoReserva, TipoVehiculo } from '@/types/database'

interface PageProps {
  params: Promise<{ id_vehiculo: string }>
}

export default async function ReservarPage({ params }: PageProps) {
  const { id_vehiculo } = await params
  const idVehiculo = parseInt(id_vehiculo, 10)

  if (isNaN(idVehiculo)) {
    redirect('/')
  }

  const supabase = await createClient()

  const {
    data: { user },
  } = await supabase.auth.getUser()

  if (!user) {
    redirect(`/login?redirect=/reservar/${id_vehiculo}`)
  }

  // Carga el vehículo con su tipo
  const { data: vehiculo, error: errorVehiculo } = await supabase
    .from('vehiculo')
    .select(`
      *,
      tipo_vehiculo ( nombre )
    `)
    .eq('id_vehiculo', idVehiculo)
    .single()

  if (errorVehiculo || !vehiculo) {
    return (
      <div className="rounded-lg bg-red-50 border border-red-200 p-6">
        <p className="text-red-700 font-medium">Vehículo no encontrado</p>
        <p className="text-red-500 text-sm mt-1">{errorVehiculo?.message}</p>
      </div>
    )
  }

  // Carga los tipos de reserva disponibles
  const { data: tiposReserva, error: errorTipos } = await supabase
    .from('tipo_reserva')
    .select('*')
    .order('id_tipo_reserva')

  if (errorTipos || !tiposReserva) {
    return (
      <div className="rounded-lg bg-red-50 border border-red-200 p-6">
        <p className="text-red-700 font-medium">Error al cargar tipos de reserva</p>
        <p className="text-red-500 text-sm mt-1">{errorTipos?.message}</p>
      </div>
    )
  }

  const vehiculoTyped = vehiculo as Vehiculo & {
    tipo_vehiculo: Pick<TipoVehiculo, 'nombre'> | null
  }

  return (
    <div className="max-w-2xl mx-auto">
      <h1 className="text-2xl font-bold text-gray-900 mb-2">
        Reservar vehículo
      </h1>
      <p className="text-gray-600 mb-6">
        {vehiculoTyped.marca} {vehiculoTyped.modelo}{' '}
        <span className="text-gray-400">· {vehiculoTyped.patente}</span>
      </p>

      <ReservaForm
        idVehiculo={idVehiculo}
        vehiculoNombre={`${vehiculoTyped.marca} ${vehiculoTyped.modelo}`}
        tiposReserva={tiposReserva as TipoReserva[]}
      />
    </div>
  )
}
