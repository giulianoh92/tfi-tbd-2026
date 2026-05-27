import Image from 'next/image'
import Link from 'next/link'
import { ArrowRight } from 'lucide-react'
import type { VehiculoConDetalles } from '@/app/page'
import { formatARS } from '@/lib/format'
import { Badge } from '@/components/ui/Badge'
import { cn } from '@/lib/cn'

interface VehiculoCardProps {
  vehiculo: VehiculoConDetalles
  priority?: boolean
  unidadesDisponibles?: number
}

const PLACEHOLDER_URL =
  'https://raw.githubusercontent.com/giulianoh92/tfi-tbd-2026/main/assets/vehiculos/placeholder.jpg'

export function VehiculoCard({ vehiculo: v, priority = false, unidadesDisponibles }: VehiculoCardProps) {
  const imageSrc = v.imagen_portada ?? PLACEHOLDER_URL
  const detalleHref = `/vehiculos/${v.id_vehiculo}`

  return (
    <div
      className={cn(
        'relative group bg-surface-raised rounded-xl border border-slate-200 shadow-sm overflow-hidden flex flex-col',
        'transition-all duration-200 ease-out',
        'hover:-translate-y-0.5 hover:shadow-md hover:border-brand-200'
      )}
    >
      {/* Overlay link cubre la card entera para que cualquier click vaya al detalle.
          El boton "Reservar" usa z-20 + relative para escapar este overlay. */}
      <Link
        href={detalleHref}
        aria-label={`Ver detalle de ${v.marca} ${v.modelo}`}
        className="absolute inset-0 z-10 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand-500 focus-visible:ring-offset-2 rounded-xl"
      />

      <div className="relative h-48 bg-slate-100">
        <Image
          src={imageSrc}
          alt={`${v.marca} ${v.modelo}`}
          fill
          className="object-cover transition-transform duration-300 group-hover:scale-[1.03]"
          sizes="(max-width: 640px) 100vw, (max-width: 1024px) 50vw, 33vw"
          priority={priority}
        />
      </div>

      <div className="p-4 flex flex-col flex-1">
        <div className="flex items-start justify-between gap-2">
          <div>
            <h2 className="font-display font-semibold text-slate-900 text-base leading-tight group-hover:text-brand-700 transition-colors">
              {v.marca} {v.modelo}
            </h2>
            <p className="text-muted-fg text-sm">{v.anio}</p>
            {unidadesDisponibles != null && unidadesDisponibles > 0 && (
              <Badge variant="success" className="mt-1">
                {unidadesDisponibles} disponible{unidadesDisponibles !== 1 ? 's' : ''} de este modelo
              </Badge>
            )}
          </div>
          {v.tipo_vehiculo && (
            <Badge variant="brand">{v.tipo_vehiculo.nombre}</Badge>
          )}
        </div>

        {v.detalle_confort && (
          <p className="text-muted-fg text-xs mt-2 line-clamp-2">
            {v.detalle_confort}
          </p>
        )}

        <div className="mt-auto pt-4 flex items-center justify-between">
          <div>
            {v.precio_por_dia != null ? (
              <p className="font-bold text-slate-900 text-lg tabular-nums">
                {formatARS(v.precio_por_dia)}
                <span className="text-muted-fg text-sm font-normal">/día</span>
              </p>
            ) : (
              <p className="text-muted-fg text-sm">Tarifa no disponible</p>
            )}
          </div>

          <Link
            href={`/reservar/${v.id_vehiculo}`}
            className="relative z-20 inline-flex items-center gap-1 px-4 py-1.5 bg-brand-600 text-white text-sm font-medium rounded-lg hover:bg-brand-700 transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand-500 focus-visible:ring-offset-2"
          >
            Reservar
            <ArrowRight className="w-4 h-4" aria-hidden="true" />
          </Link>
        </div>
      </div>
    </div>
  )
}
