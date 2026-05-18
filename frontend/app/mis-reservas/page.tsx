import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import Link from 'next/link'
import type { Reserva, Vehiculo, TipoReserva } from '@/types/database'

type ReservaConDetalles = Reserva & {
  vehiculo: Pick<Vehiculo, 'marca' | 'modelo' | 'patente'> | null
  tipo_reserva: Pick<TipoReserva, 'nombre'> | null
}

const ESTADO_LABELS: Record<string, { label: string; class: string }> = {
  pendiente: { label: 'Pendiente', class: 'bg-yellow-100 text-yellow-800' },
  concretada: { label: 'Concretada', class: 'bg-green-100 text-green-800' },
  cancelada: { label: 'Cancelada', class: 'bg-red-100 text-red-800' },
}

export default async function MisReservasPage() {
  const supabase = await createClient()

  const {
    data: { user },
  } = await supabase.auth.getUser()

  // El middleware debería haber redirigido antes de llegar acá,
  // pero lo verificamos de todas formas como defensa en profundidad.
  if (!user) {
    redirect('/login')
  }

  // El frontend NO filtra por cliente — confía en RLS.
  // La policy `reserva_owner_crud` filtra automáticamente las filas
  // que pertenecen al usuario autenticado.
  const { data: reservas, error } = await supabase
    .from('reserva')
    .select(`
      *,
      vehiculo ( marca, modelo, patente ),
      tipo_reserva ( nombre )
    `)
    .order('fecha_creacion', { ascending: false })

  if (error) {
    return (
      <div className="rounded-lg bg-red-50 border border-red-200 p-6">
        <p className="text-red-700 font-medium">Error al cargar reservas</p>
        <p className="text-red-500 text-sm mt-1">{error.message}</p>
      </div>
    )
  }

  const reservasTyped = (reservas ?? []) as ReservaConDetalles[]

  return (
    <div>
      <div className="flex items-center justify-between mb-8">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Mis reservas</h1>
          <p className="text-gray-500 mt-1 text-sm">{user.email}</p>
        </div>
        <Link
          href="/"
          className="text-sm text-blue-600 hover:text-blue-800 font-medium"
        >
          ← Ver vehículos
        </Link>
      </div>

      {reservasTyped.length === 0 ? (
        <div className="text-center py-16">
          <p className="text-gray-500 text-lg">Todavía no tenés reservas.</p>
          <Link
            href="/"
            className="mt-4 inline-block px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
          >
            Buscar un vehículo
          </Link>
        </div>
      ) : (
        <div className="space-y-4">
          {reservasTyped.map((r) => (
            <ReservaRow key={r.id_reserva} reserva={r} />
          ))}
        </div>
      )}
    </div>
  )
}

function ReservaRow({ reserva: r }: { reserva: ReservaConDetalles }) {
  const estado = ESTADO_LABELS[r.estado] ?? { label: r.estado, class: 'bg-gray-100 text-gray-800' }

  const fechaInicio = new Date(r.fecha_inicio).toLocaleDateString('es-AR', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
  })
  const fechaFin = new Date(r.fecha_fin_prevista).toLocaleDateString('es-AR', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
  })

  return (
    <div className="bg-white rounded-xl border border-gray-200 shadow-sm p-5">
      <div className="flex items-start justify-between gap-4">
        <div>
          <p className="font-semibold text-gray-900">
            {r.vehiculo
              ? `${r.vehiculo.marca} ${r.vehiculo.modelo}`
              : `Vehículo #${r.id_vehiculo}`}
          </p>
          {r.vehiculo && (
            <p className="text-gray-500 text-sm">{r.vehiculo.patente}</p>
          )}
        </div>
        <span
          className={`shrink-0 px-2.5 py-0.5 rounded-full text-xs font-medium ${estado.class}`}
        >
          {estado.label}
        </span>
      </div>

      <div className="mt-3 grid grid-cols-2 sm:grid-cols-3 gap-3 text-sm text-gray-600">
        <div>
          <span className="text-gray-400 text-xs uppercase tracking-wide">Desde</span>
          <p>{fechaInicio}</p>
        </div>
        <div>
          <span className="text-gray-400 text-xs uppercase tracking-wide">Hasta</span>
          <p>{fechaFin}</p>
        </div>
        <div>
          <span className="text-gray-400 text-xs uppercase tracking-wide">Tipo</span>
          <p className="capitalize">{r.tipo_reserva?.nombre ?? '—'}</p>
        </div>
      </div>

      <p className="text-gray-400 text-xs mt-3">
        Creada el{' '}
        {new Date(r.fecha_creacion).toLocaleDateString('es-AR', {
          day: '2-digit',
          month: '2-digit',
          year: 'numeric',
          hour: '2-digit',
          minute: '2-digit',
        })}
      </p>
    </div>
  )
}
