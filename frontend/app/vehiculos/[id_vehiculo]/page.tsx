import { createClient } from '@/lib/supabase/server'
import { redirect, notFound } from 'next/navigation'
import Link from 'next/link'
import { ArrowLeft, ArrowRight } from 'lucide-react'
import { VehiculoGallery } from '@/components/VehiculoGallery'
import { Badge } from '@/components/ui/Badge'
import { Card } from '@/components/ui/Card'
import { Button } from '@/components/ui/Button'
import { formatARS } from '@/lib/format'
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
      <div role="alert" className="rounded-lg bg-danger-bg border border-danger-border p-6">
        <p className="text-danger-fg font-medium">Error al cargar el vehículo</p>
        <p className="text-danger-fg/80 text-sm mt-1">{vehiculoRes.error.message}</p>
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
        className="inline-flex items-center gap-1 text-sm text-brand-700 hover:text-brand-700 hover:underline font-medium mb-6 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand-500 rounded"
      >
        <ArrowLeft className="w-4 h-4" aria-hidden="true" />
        Volver a vehículos
      </Link>

      <div className="grid grid-cols-1 lg:grid-cols-5 gap-8">
        <div className="lg:col-span-3">
          <VehiculoGallery alt={`${v.marca} ${v.modelo}`} images={imagenes} />
        </div>

        <div className="lg:col-span-2 flex flex-col gap-5">
          <div>
            <div className="flex items-start justify-between gap-3">
              <h1 className="font-display text-3xl font-bold text-slate-900 leading-tight">
                {v.marca} {v.modelo}
              </h1>
              {v.tipo_vehiculo && (
                <Badge variant="brand">{v.tipo_vehiculo.nombre}</Badge>
              )}
            </div>
            <p className="text-muted-fg mt-1">
              {v.anio} · Patente {v.patente}
            </p>
          </div>

          <Card variant="raised" className="p-5">
            {tarifa ? (
              <div>
                <p className="font-display text-3xl font-bold text-slate-900 tabular-nums">
                  {formatARS(tarifa.precio_por_dia)}
                  <span className="text-muted-fg text-base font-normal">/día</span>
                </p>
                <p className="text-xs text-muted-fg mt-1">
                  Tarifa estándar del tipo {v.tipo_vehiculo?.nombre ?? '—'}
                </p>
              </div>
            ) : (
              <p className="text-muted-fg">Tarifa no disponible</p>
            )}

            {disponible ? (
              <Link
                href={`/reservar/${v.id_vehiculo}`}
                className="mt-4 inline-flex w-full items-center justify-center gap-1 px-4 py-2.5 rounded-lg text-sm font-medium bg-brand-600 text-white hover:bg-brand-700 transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand-500 focus-visible:ring-offset-2"
              >
                Reservar
                <ArrowRight className="w-4 h-4" aria-hidden="true" />
              </Link>
            ) : (
              <Button
                type="button"
                variant="secondary"
                disabled
                className="mt-4 w-full"
                aria-label={`No disponible: ${estado}`}
              >
                No disponible ({estado})
              </Button>
            )}
          </Card>

          <Card variant="raised" className="p-5">
            <dl className="space-y-3 text-sm">
              <div className="flex justify-between gap-4">
                <dt className="text-muted-fg">Estado</dt>
                <dd className="text-slate-900 font-medium capitalize">{estado}</dd>
              </div>
              <div className="flex justify-between gap-4">
                <dt className="text-muted-fg">Kilometraje</dt>
                <dd className="text-slate-900 font-medium tabular-nums">
                  {v.km_actuales.toLocaleString('es-AR')} km
                </dd>
              </div>
              {sucursalOrigen && (
                <div className="flex justify-between gap-4">
                  <dt className="text-muted-fg">Sucursal</dt>
                  <dd className="text-slate-900 font-medium text-right">
                    {sucursalOrigen.nombre}
                    <span className="block text-xs text-muted-fg font-normal">
                      {sucursalOrigen.ciudad}
                    </span>
                  </dd>
                </div>
              )}
              {v.tipo_vehiculo?.descripcion && (
                <div>
                  <dt className="text-muted-fg mb-1">Sobre el tipo</dt>
                  <dd className="text-slate-700">{v.tipo_vehiculo.descripcion}</dd>
                </div>
              )}
            </dl>
          </Card>

          {v.detalle_confort && (
            <Card variant="raised" className="p-5">
              <h2 className="font-display font-semibold text-slate-900 text-sm mb-2">
                Equipamiento y confort
              </h2>
              <p className="text-slate-700 text-sm leading-relaxed">{v.detalle_confort}</p>
            </Card>
          )}
        </div>
      </div>
    </div>
  )
}
