import { createClient } from '@/lib/supabase/server'
import { VehiculoCard } from '@/components/VehiculoCard'
import type { Vehiculo, TipoVehiculo, ImagenVehiculo, Tarifa } from '@/types/database'

// Tipo compuesto para la landing: vehiculo enriquecido con joins
export type VehiculoConDetalles = Vehiculo & {
  tipo_vehiculo: Pick<TipoVehiculo, 'nombre'> | null
  imagen_portada: string | null
  precio_por_dia: number | null
}

export default async function HomePage() {
  const supabase = await createClient()

  // Trae los 10 vehículos con sus relaciones.
  // El filtro de disponibilidad queda para cuando exista la RLS policy
  // `vehiculo_public_read` + la policy de estado. Por ahora traemos todos
  // los que el rol `anon` pueda ver.
  const { data: vehiculos, error } = await supabase
    .from('vehiculo')
    .select(`
      *,
      tipo_vehiculo!vehiculo_id_tipo_fkey ( nombre ),
      imagen_vehiculo ( url_imagen, orden ),
      estado_vehiculo!vehiculo_id_estado_fkey ( codigo ),
      tarifa ( precio_por_dia, id_sucursal, id_tipo )
    `)
    .limit(10)

  if (error) {
    // En PoC mostramos el error técnico; en producción loguear y mostrar UI amigable.
    return (
      <div className="rounded-lg bg-red-50 border border-red-200 p-6">
        <p className="text-red-700 font-medium">Error al cargar vehículos</p>
        <p className="text-red-500 text-sm mt-1">{error.message}</p>
        <p className="text-gray-500 text-xs mt-2">
          ¿Tenés el stack local corriendo? Corré{' '}
          <code className="bg-red-100 px-1 rounded">bash scripts/dev-frontend.sh</code>
        </p>
      </div>
    )
  }

  // Normaliza el resultado de los joins para pasarle a cada Card
  const vehiculosNormalizados: VehiculoConDetalles[] = (vehiculos ?? []).map((v) => {
    const imgs = (v.imagen_vehiculo as ImagenVehiculo[] | null) ?? []
    const portada = imgs.find((i) => i.orden === 1)?.url_imagen ?? null

    // Busca la tarifa que corresponde al tipo del vehículo y su sucursal origen
    const tarifas = (v.tarifa as Tarifa[] | null) ?? []
    const tarifa = tarifas.find(
      (t) => t.id_tipo === v.id_tipo && t.id_sucursal === v.id_sucursal_origen
    ) ?? tarifas[0] ?? null

    return {
      ...v,
      tipo_vehiculo: (v.tipo_vehiculo as { nombre: string } | null),
      imagen_portada: portada,
      precio_por_dia: tarifa?.precio_por_dia ?? null,
    }
  })

  return (
    <div>
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-gray-900">Vehículos disponibles</h1>
        <p className="text-gray-500 mt-1">
          Elegí el vehículo que más se adapta a tu viaje.
        </p>
      </div>

      {vehiculosNormalizados.length === 0 ? (
        <p className="text-gray-500 text-center py-16">
          No hay vehículos disponibles en este momento.
        </p>
      ) : (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
          {vehiculosNormalizados.map((v) => (
            <VehiculoCard key={v.id_vehiculo} vehiculo={v} />
          ))}
        </div>
      )}
    </div>
  )
}
