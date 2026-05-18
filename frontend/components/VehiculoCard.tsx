import Image from 'next/image'
import Link from 'next/link'
import type { VehiculoConDetalles } from '@/app/page'

interface VehiculoCardProps {
  vehiculo: VehiculoConDetalles
  priority?: boolean
}

const PLACEHOLDER_URL =
  'https://raw.githubusercontent.com/giulianoh92/tfi-tbd-2026/main/assets/vehiculos/placeholder.jpg'

export function VehiculoCard({ vehiculo: v, priority = false }: VehiculoCardProps) {
  const imageSrc = v.imagen_portada ?? PLACEHOLDER_URL

  return (
    <div className="bg-white rounded-xl border border-gray-200 shadow-sm overflow-hidden hover:shadow-md transition-shadow flex flex-col">
      <div className="relative h-48 bg-gray-100">
        <Image
          src={imageSrc}
          alt={`${v.marca} ${v.modelo}`}
          fill
          className="object-cover"
          sizes="(max-width: 640px) 100vw, (max-width: 1024px) 50vw, 33vw"
          priority={priority}
        />
      </div>

      <div className="p-4 flex flex-col flex-1">
        <div className="flex items-start justify-between gap-2">
          <div>
            <h2 className="font-semibold text-gray-900 text-base leading-tight">
              {v.marca} {v.modelo}
            </h2>
            <p className="text-gray-500 text-sm">{v.anio}</p>
          </div>
          {v.tipo_vehiculo && (
            <span className="shrink-0 text-xs font-medium px-2 py-0.5 rounded-full bg-blue-50 text-blue-700">
              {v.tipo_vehiculo.nombre}
            </span>
          )}
        </div>

        {v.detalle_confort && (
          <p className="text-gray-500 text-xs mt-2 line-clamp-2">
            {v.detalle_confort}
          </p>
        )}

        <div className="mt-auto pt-4 flex items-center justify-between">
          <div>
            {v.precio_por_dia != null ? (
              <p className="font-bold text-gray-900 text-lg">
                ${v.precio_por_dia.toLocaleString('es-AR')}
                <span className="text-gray-400 text-sm font-normal">/día</span>
              </p>
            ) : (
              <p className="text-gray-400 text-sm">Tarifa no disponible</p>
            )}
          </div>

          <Link
            href={`/reservar/${v.id_vehiculo}`}
            className="px-4 py-1.5 bg-blue-600 text-white text-sm font-medium rounded-lg hover:bg-blue-700 transition-colors"
          >
            Reservar →
          </Link>
        </div>
      </div>
    </div>
  )
}
