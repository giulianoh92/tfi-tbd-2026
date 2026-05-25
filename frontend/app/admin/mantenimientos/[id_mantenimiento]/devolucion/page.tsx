import { createClient } from '@/lib/supabase/server'
import { notFound, redirect } from 'next/navigation'
import { DevolucionMantenimientoForm } from '@/components/DevolucionMantenimientoForm'
import { Card } from '@/components/ui/Card'
import { formatDateAR } from '@/lib/format'
import type { Mantenimiento, Taller, Vehiculo } from '@/types/database'

type MantenimientoCompleto = Mantenimiento & {
  vehiculo:
    | Pick<Vehiculo, 'id_vehiculo' | 'marca' | 'modelo' | 'patente' | 'km_actuales'>
    | null
  taller: Pick<Taller, 'id_taller' | 'nombre' | 'direccion'> | null
}

interface Props {
  params: Promise<{ id_mantenimiento: string }>
}

/**
 * Pagina staff: registrar devolucion de mantenimiento (CU-08).
 *
 * Carga el mantenimiento con vehiculo + taller. Si ya esta cerrado
 * (fecha_devolucion IS NOT NULL) redirige al listado, ya que la accion no
 * tiene sentido sobre un mantenimiento historico.
 */
export default async function DevolucionMantenimientoPage({ params }: Props) {
  const { id_mantenimiento } = await params
  const id = parseInt(id_mantenimiento, 10)

  if (isNaN(id)) notFound()

  const supabase = await createClient()

  const { data, error } = await supabase
    .from('mantenimiento')
    .select(
      `
      id_mantenimiento,
      id_vehiculo,
      id_taller,
      fecha_envio,
      fecha_devolucion,
      observaciones,
      vehiculo ( id_vehiculo, marca, modelo, patente, km_actuales ),
      taller ( id_taller, nombre, direccion )
    `,
    )
    .eq('id_mantenimiento', id)
    .single()

  if (error || !data) {
    notFound()
  }

  const mantenimiento = data as MantenimientoCompleto

  // Si ya esta cerrado, no permitir doble devolucion.
  if (mantenimiento.fecha_devolucion != null) {
    redirect('/admin/mantenimientos')
  }

  if (!mantenimiento.vehiculo) {
    return (
      <div role="alert" className="rounded-lg bg-danger-bg border border-danger-border p-6">
        <p className="text-danger-fg font-medium">
          No se pudo cargar el vehículo asociado al mantenimiento.
        </p>
      </div>
    )
  }

  return (
    <div className="max-w-xl mx-auto">
      <h1 className="font-display text-2xl font-bold text-slate-900 mb-8">
        Registrar devolución de mantenimiento #{mantenimiento.id_mantenimiento}
      </h1>

      {/* Resumen del mantenimiento abierto */}
      <Card variant="flat" className="bg-slate-50 p-5 mb-6">
        <h2 className="text-xs font-semibold text-muted-fg uppercase tracking-wider mb-3">
          Resumen
        </h2>
        <dl className="grid grid-cols-2 gap-x-4 gap-y-2 text-sm">
          <div>
            <dt className="text-muted-fg text-xs uppercase tracking-wider">Vehículo</dt>
            <dd className="font-medium text-slate-900">
              {mantenimiento.vehiculo.marca} {mantenimiento.vehiculo.modelo}
            </dd>
            <dd className="text-muted-fg text-xs font-mono">
              {mantenimiento.vehiculo.patente}
            </dd>
          </div>
          <div>
            <dt className="text-muted-fg text-xs uppercase tracking-wider">Taller</dt>
            <dd className="font-medium text-slate-900">
              {mantenimiento.taller?.nombre ?? `Taller #${mantenimiento.id_taller}`}
            </dd>
            {mantenimiento.taller && (
              <dd className="text-muted-fg text-xs">{mantenimiento.taller.direccion}</dd>
            )}
          </div>
          <div>
            <dt className="text-muted-fg text-xs uppercase tracking-wider">Fecha envío</dt>
            <dd className="text-slate-700 tabular-nums">
              {formatDateAR(mantenimiento.fecha_envio)}
            </dd>
          </div>
          <div>
            <dt className="text-muted-fg text-xs uppercase tracking-wider">
              Km al envío
            </dt>
            <dd className="text-slate-700 tabular-nums">
              {mantenimiento.vehiculo.km_actuales.toLocaleString('es-AR')} km
            </dd>
          </div>
          {mantenimiento.observaciones && (
            <div className="col-span-2">
              <dt className="text-muted-fg text-xs uppercase tracking-wider">
                Observaciones
              </dt>
              <dd className="text-slate-700 whitespace-pre-wrap">
                {mantenimiento.observaciones}
              </dd>
            </div>
          )}
        </dl>
      </Card>

      <DevolucionMantenimientoForm
        idVehiculo={mantenimiento.vehiculo.id_vehiculo}
        kmActuales={mantenimiento.vehiculo.km_actuales}
      />
    </div>
  )
}
