import { createClient } from '@/lib/supabase/server'
import { notFound } from 'next/navigation'
import Link from 'next/link'
import { CerrarAlquilerForm } from '@/components/CerrarAlquilerForm'
import type { Alquiler, Vehiculo, Cliente, Sucursal } from '@/types/database'

type AlquilerCompleto = Alquiler & {
  vehiculo: Pick<Vehiculo, 'marca' | 'modelo' | 'patente' | 'km_actuales'> | null
  cliente: Pick<Cliente, 'nombre' | 'apellido' | 'dni'> | null
}

interface Props {
  params: Promise<{ id_alquiler: string }>
}

/**
 * Página de cierre de alquiler.
 * Carga el alquiler con sus joins y todas las sucursales para el select.
 * Delega el form interactivo a CerrarAlquilerForm (Client Component).
 */
export default async function CerrarAlquilerPage({ params }: Props) {
  const { id_alquiler } = await params
  const id = parseInt(id_alquiler, 10)

  if (isNaN(id)) notFound()

  const supabase = await createClient()

  // Cargamos alquiler + sucursales en paralelo
  const [alquilerRes, sucursalesRes] = await Promise.all([
    supabase
      .from('alquiler')
      .select(`
        *,
        vehiculo ( marca, modelo, patente, km_actuales ),
        cliente ( nombre, apellido, dni )
      `)
      .eq('id_alquiler', id)
      .eq('estado', 'activo')
      .single(),
    supabase
      .from('sucursal')
      .select('id_sucursal, nombre')
      .order('nombre'),
  ])

  // Si no existe o ya está cerrado → 404
  if (alquilerRes.error || !alquilerRes.data) {
    notFound()
  }

  if (sucursalesRes.error) {
    return (
      <div className="rounded-lg bg-red-50 border border-red-200 p-6">
        <p className="text-red-700 font-medium">Error al cargar sucursales</p>
        <p className="text-red-500 text-sm mt-1">{sucursalesRes.error.message}</p>
      </div>
    )
  }

  const alquiler = alquilerRes.data as AlquilerCompleto
  const sucursales = (sucursalesRes.data ?? []) as Sucursal[]

  const fechaInicio = new Date(alquiler.fecha_inicio).toLocaleDateString('es-AR', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
  })
  const fechaFinPrevista = new Date(alquiler.fecha_fin_prevista).toLocaleDateString('es-AR', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
  })

  return (
    <div className="max-w-xl mx-auto">
      <div className="flex items-center justify-between mb-8">
        <h1 className="text-2xl font-bold text-gray-900">Cerrar alquiler #{alquiler.id_alquiler}</h1>
        <Link
          href="/admin/alquileres"
          className="text-sm text-blue-600 hover:text-blue-800 font-medium"
        >
          ← Volver
        </Link>
      </div>

      {/* Resumen del alquiler */}
      <div className="bg-gray-50 rounded-xl border border-gray-200 p-5 mb-6">
        <h2 className="text-sm font-semibold text-gray-700 uppercase tracking-wide mb-3">
          Resumen
        </h2>
        <dl className="grid grid-cols-2 gap-x-4 gap-y-2 text-sm">
          <div>
            <dt className="text-gray-400 text-xs uppercase tracking-wide">Vehículo</dt>
            <dd className="font-medium text-gray-900">
              {alquiler.vehiculo
                ? `${alquiler.vehiculo.marca} ${alquiler.vehiculo.modelo}`
                : `#${alquiler.id_vehiculo}`}
            </dd>
            {alquiler.vehiculo && (
              <dd className="text-gray-500 text-xs">{alquiler.vehiculo.patente}</dd>
            )}
          </div>
          <div>
            <dt className="text-gray-400 text-xs uppercase tracking-wide">Cliente</dt>
            <dd className="font-medium text-gray-900">
              {alquiler.cliente
                ? `${alquiler.cliente.nombre} ${alquiler.cliente.apellido}`
                : `#${alquiler.id_cliente}`}
            </dd>
            {alquiler.cliente && (
              <dd className="text-gray-500 text-xs">DNI {alquiler.cliente.dni}</dd>
            )}
          </div>
          <div>
            <dt className="text-gray-400 text-xs uppercase tracking-wide">Inicio</dt>
            <dd className="text-gray-700">{fechaInicio}</dd>
          </div>
          <div>
            <dt className="text-gray-400 text-xs uppercase tracking-wide">Fin previsto</dt>
            <dd className="text-gray-700">{fechaFinPrevista}</dd>
          </div>
          <div>
            <dt className="text-gray-400 text-xs uppercase tracking-wide">Km inicio</dt>
            <dd className="text-gray-700">{alquiler.km_inicio.toLocaleString('es-AR')} km</dd>
          </div>
          {alquiler.vehiculo && (
            <div>
              <dt className="text-gray-400 text-xs uppercase tracking-wide">Km actuales (vehículo)</dt>
              <dd className="text-gray-700">{alquiler.vehiculo.km_actuales.toLocaleString('es-AR')} km</dd>
            </div>
          )}
        </dl>
      </div>

      {/* Form interactivo */}
      <CerrarAlquilerForm
        idAlquiler={alquiler.id_alquiler}
        kmInicio={alquiler.km_inicio}
        sucursales={sucursales}
      />
    </div>
  )
}
