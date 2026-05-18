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

  // Dos queries en paralelo: vehiculos con joins directos (FKs unicas, sin
  // hints de constraint) + tarifas planas. La relacion tipo+sucursal -> tarifa
  // se resuelve en JS abajo (no hay FK directa vehiculo->tarifa).
  const [vehiculosRes, tarifasRes] = await Promise.all([
    supabase
      .from('vehiculo')
      .select(`
        *,
        tipo_vehiculo ( nombre ),
        imagen_vehiculo ( url_imagen, orden ),
        estado_vehiculo ( nombre )
      `)
      .limit(10),
    supabase
      .from('tarifa')
      .select('precio_por_dia, id_sucursal, id_tipo'),
  ])

  const vehiculos = vehiculosRes.data
  const tarifasAll = tarifasRes.data ?? []
  const error = vehiculosRes.error ?? tarifasRes.error

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

    // Busca la tarifa que corresponde al tipo del vehículo y su sucursal origen.
    // Fallback: cualquier tarifa del mismo tipo si no hay una especifica de la sucursal.
    const tarifa = (tarifasAll as Tarifa[]).find(
      (t) => t.id_tipo === v.id_tipo && t.id_sucursal === v.id_sucursal_origen
    ) ?? (tarifasAll as Tarifa[]).find((t) => t.id_tipo === v.id_tipo) ?? null

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
          {vehiculosNormalizados.map((v, idx) => (
            <VehiculoCard key={v.id_vehiculo} vehiculo={v} priority={idx < 3} />
          ))}
        </div>
      )}
    </div>
  )
}
