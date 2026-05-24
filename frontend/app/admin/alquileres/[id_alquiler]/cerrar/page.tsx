import { createClient } from '@/lib/supabase/server'
import { notFound } from 'next/navigation'
import { CerrarAlquilerForm } from '@/components/CerrarAlquilerForm'
import { Card } from '@/components/ui/Card'
import { formatDateAR } from '@/lib/format'
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
      <div role="alert" className="rounded-lg bg-danger-bg border border-danger-border p-6">
        <p className="text-danger-fg font-medium">Error al cargar sucursales</p>
        <p className="text-danger-fg/80 text-sm mt-1">{sucursalesRes.error.message}</p>
      </div>
    )
  }

  const alquiler = alquilerRes.data as AlquilerCompleto
  const sucursales = (sucursalesRes.data ?? []) as Sucursal[]

  return (
    <div className="max-w-xl mx-auto">
      <h1 className="font-display text-2xl font-bold text-slate-900 mb-8">
        Cerrar alquiler #{alquiler.id_alquiler}
      </h1>

      {/* Resumen del alquiler */}
      <Card variant="flat" className="bg-slate-50 p-5 mb-6">
        <h2 className="text-xs font-semibold text-muted-fg uppercase tracking-wider mb-3">
          Resumen
        </h2>
        <dl className="grid grid-cols-2 gap-x-4 gap-y-2 text-sm">
          <div>
            <dt className="text-muted-fg text-xs uppercase tracking-wider">Vehículo</dt>
            <dd className="font-medium text-slate-900">
              {alquiler.vehiculo
                ? `${alquiler.vehiculo.marca} ${alquiler.vehiculo.modelo}`
                : `#${alquiler.id_vehiculo}`}
            </dd>
            {alquiler.vehiculo && (
              <dd className="text-muted-fg text-xs">{alquiler.vehiculo.patente}</dd>
            )}
          </div>
          <div>
            <dt className="text-muted-fg text-xs uppercase tracking-wider">Cliente</dt>
            <dd className="font-medium text-slate-900">
              {alquiler.cliente
                ? `${alquiler.cliente.nombre} ${alquiler.cliente.apellido}`
                : `#${alquiler.id_cliente}`}
            </dd>
            {alquiler.cliente && (
              <dd className="text-muted-fg text-xs">DNI {alquiler.cliente.dni}</dd>
            )}
          </div>
          <div>
            <dt className="text-muted-fg text-xs uppercase tracking-wider">Inicio</dt>
            <dd className="text-slate-700 tabular-nums">{formatDateAR(alquiler.fecha_inicio)}</dd>
          </div>
          <div>
            <dt className="text-muted-fg text-xs uppercase tracking-wider">Fin previsto</dt>
            <dd className="text-slate-700 tabular-nums">{formatDateAR(alquiler.fecha_fin_prevista)}</dd>
          </div>
          <div>
            <dt className="text-muted-fg text-xs uppercase tracking-wider">Km inicio</dt>
            <dd className="text-slate-700 tabular-nums">{alquiler.km_inicio.toLocaleString('es-AR')} km</dd>
          </div>
          {alquiler.vehiculo && (
            <div>
              <dt className="text-muted-fg text-xs uppercase tracking-wider">Km actuales (vehículo)</dt>
              <dd className="text-slate-700 tabular-nums">{alquiler.vehiculo.km_actuales.toLocaleString('es-AR')} km</dd>
            </div>
          )}
        </dl>
      </Card>

      {/* Form interactivo */}
      <CerrarAlquilerForm
        idAlquiler={alquiler.id_alquiler}
        kmInicio={alquiler.km_inicio}
        sucursales={sucursales}
      />
    </div>
  )
}
