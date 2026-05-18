import { createClient } from '@/lib/supabase/server'
import { redirect, notFound } from 'next/navigation'
import Link from 'next/link'
import { VehiculoGallery } from '@/components/VehiculoGallery'
import type {
  Vehiculo,
  TipoVehiculo,
  EstadoVehiculo,
  ImagenVehiculo,
  Tarifa,
} from '@/types/database'

interface PageProps {
  params: Promise<{ id_vehiculo: string }>
}

type VehiculoDetalle = Vehiculo & {
  tipo_vehiculo: Pick<TipoVehiculo, 'nombre' | 'descripcion'> | null
  estado_vehiculo: Pick<EstadoVehiculo, 'nombre'> | null
  imagen_vehiculo: Pick<ImagenVehiculo, 'url_imagen' | 'orden'>[] | null
}

type SucursalRow = { id_sucursal: number; nombre: string; ciudad: string }

export default async function VehiculoDetallePage({ params }: PageProps) {
  const { id_vehiculo } = await params
  const idVehiculo = parseInt(id_vehiculo, 10)

  if (isNaN(idVehiculo)) {
    redirect('/')
  }

  const supabase = await createClient()

  const [vehiculoRes, tarifasRes, sucursalesRes] = await Promise.all([
    supabase
      .from('vehiculo')
      .select(`
        *,
        tipo_vehiculo ( nombre, descripcion ),
        estado_vehiculo ( nombre ),
        imagen_vehiculo ( url_imagen, orden )
      `)
      .eq('id_vehiculo', idVehiculo)
      .maybeSingle(),
    supabase.from('tarifa').select('precio_por_dia, id_sucursal, id_tipo'),
    supabase.from('sucursal').select('id_sucursal, nombre, ciudad'),
  ])

  if (vehiculoRes.error) {
    return (
      <div className="rounded-lg bg-red-50 border border-red-200 p-6">
        <p className="text-red-700 font-medium">Error al cargar el vehículo</p>
        <p className="text-red-500 text-sm mt-1">{vehiculoRes.error.message}</p>
      </div>
    )
  }

  if (!vehiculoRes.data) {
    notFound()
  }

  const v = vehiculoRes.data as VehiculoDetalle
  const tarifas = (tarifasRes.data ?? []) as Tarifa[]
  const sucursales = (sucursalesRes.data ?? []) as SucursalRow[]

  // Tarifa para el tipo + sucursal origen, fallback a cualquier tarifa del tipo
  const tarifa =
    tarifas.find((t) => t.id_tipo === v.id_tipo && t.id_sucursal === v.id_sucursal_origen) ??
    tarifas.find((t) => t.id_tipo === v.id_tipo) ??
    null

  const sucursalOrigen = sucursales.find((s) => s.id_sucursal === v.id_sucursal_origen) ?? null
  const imagenes = v.imagen_vehiculo ?? []
  const estado = v.estado_vehiculo?.nombre?.toLowerCase() ?? 'desconocido'
  const disponible = estado === 'disponible'

  return (
    <div>
      <Link
        href="/"
        className="inline-flex items-center text-sm text-blue-600 hover:text-blue-800 font-medium mb-6"
      >
        ← Volver a vehículos
      </Link>

      <div className="grid grid-cols-1 lg:grid-cols-5 gap-8">
        <div className="lg:col-span-3">
          <VehiculoGallery alt={`${v.marca} ${v.modelo}`} images={imagenes} />
        </div>

        <div className="lg:col-span-2 flex flex-col gap-5">
          <div>
            <div className="flex items-start justify-between gap-3">
              <h1 className="text-3xl font-bold text-gray-900 leading-tight">
                {v.marca} {v.modelo}
              </h1>
              {v.tipo_vehiculo && (
                <span className="shrink-0 text-xs font-medium px-2.5 py-0.5 rounded-full bg-blue-50 text-blue-700">
                  {v.tipo_vehiculo.nombre}
                </span>
              )}
            </div>
            <p className="text-gray-500 mt-1">
              {v.anio} · Patente {v.patente}
            </p>
          </div>

          <div className="bg-white border border-gray-200 rounded-xl p-5 shadow-sm">
            {tarifa ? (
              <div>
                <p className="text-3xl font-bold text-gray-900">
                  ${tarifa.precio_por_dia.toLocaleString('es-AR')}
                  <span className="text-gray-400 text-base font-normal">/día</span>
                </p>
                <p className="text-xs text-gray-500 mt-1">
                  Tarifa estándar del tipo {v.tipo_vehiculo?.nombre ?? '—'}
                </p>
              </div>
            ) : (
              <p className="text-gray-400">Tarifa no disponible</p>
            )}

            <Link
              href={disponible ? `/reservar/${v.id_vehiculo}` : '#'}
              aria-disabled={!disponible}
              tabIndex={disponible ? 0 : -1}
              className={`mt-4 block text-center px-4 py-2.5 rounded-lg text-sm font-medium transition-colors ${
                disponible
                  ? 'bg-blue-600 text-white hover:bg-blue-700'
                  : 'bg-gray-200 text-gray-500 cursor-not-allowed pointer-events-none'
              }`}
            >
              {disponible ? 'Reservar →' : `No disponible (${estado})`}
            </Link>
          </div>

          <dl className="bg-white border border-gray-200 rounded-xl p-5 shadow-sm space-y-3 text-sm">
            <div className="flex justify-between gap-4">
              <dt className="text-gray-500">Estado</dt>
              <dd className="text-gray-900 font-medium capitalize">{estado}</dd>
            </div>
            <div className="flex justify-between gap-4">
              <dt className="text-gray-500">Kilometraje</dt>
              <dd className="text-gray-900 font-medium">
                {v.km_actuales.toLocaleString('es-AR')} km
              </dd>
            </div>
            {sucursalOrigen && (
              <div className="flex justify-between gap-4">
                <dt className="text-gray-500">Sucursal</dt>
                <dd className="text-gray-900 font-medium text-right">
                  {sucursalOrigen.nombre}
                  <span className="block text-xs text-gray-400 font-normal">
                    {sucursalOrigen.ciudad}
                  </span>
                </dd>
              </div>
            )}
            {v.tipo_vehiculo?.descripcion && (
              <div>
                <dt className="text-gray-500 mb-1">Sobre el tipo</dt>
                <dd className="text-gray-700">{v.tipo_vehiculo.descripcion}</dd>
              </div>
            )}
          </dl>

          {v.detalle_confort && (
            <div className="bg-white border border-gray-200 rounded-xl p-5 shadow-sm">
              <h2 className="font-semibold text-gray-900 text-sm mb-2">
                Equipamiento y confort
              </h2>
              <p className="text-gray-700 text-sm leading-relaxed">{v.detalle_confort}</p>
            </div>
          )}
        </div>
      </div>
    </div>
  )
}
