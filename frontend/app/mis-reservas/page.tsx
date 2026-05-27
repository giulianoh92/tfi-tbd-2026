import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import Link from 'next/link'
import type { Reserva, Vehiculo, TipoReserva } from '@/types/database'
import { CancelarReservaButton } from '@/components/CancelarReservaButton'
import { Card } from '@/components/ui/Card'
import { Badge } from '@/components/ui/Badge'
import { formatDateAR, formatDateTimeAR } from '@/lib/format'

type ReservaConDetalles = Reserva & {
  vehiculo: Pick<Vehiculo, 'marca' | 'modelo' | 'patente'> | null
  tipo_reserva: Pick<TipoReserva, 'nombre'> | null
  motivo_cancelacion?: string | null
}

type BadgeVariant = 'warning' | 'success' | 'danger' | 'muted'

const ESTADO_LABELS: Record<string, { label: string; variant: BadgeVariant }> = {
  pendiente: { label: 'Pendiente', variant: 'warning' },
  concretada: { label: 'Concretada', variant: 'success' },
  cancelada: { label: 'Cancelada', variant: 'danger' },
}

export default async function MisReservasPage() {
  const supabase = await createClient()

  const {
    data: { user },
  } = await supabase.auth.getUser()

  if (!user) {
    redirect('/login')
  }

  const { data: clienteRow } = await supabase
    .from('cliente')
    .select('id_cliente, nombre, apellido')
    .eq('auth_user_id', user.id)
    .maybeSingle<{ id_cliente: number; nombre: string; apellido: string }>()

  const idCliente = clienteRow?.id_cliente ?? null
  const clienteNombre = clienteRow
    ? [clienteRow.nombre, clienteRow.apellido].filter(Boolean).join(' ') || undefined
    : undefined

  const { data: reservas, error } = idCliente
    ? await supabase
        .from('reserva')
        .select(`
          *,
          motivo_cancelacion,
          vehiculo ( marca, modelo, patente ),
          tipo_reserva ( nombre )
        `)
        .eq('id_cliente', idCliente)
        .order('fecha_creacion', { ascending: false })
    : { data: [], error: null }

  if (error) {
    return (
      <div role="alert" className="rounded-lg bg-danger-bg border border-danger-border p-6">
        <p className="text-danger-fg font-medium">Error al cargar reservas</p>
        <p className="text-danger-fg/80 text-sm mt-1">{error.message}</p>
      </div>
    )
  }

  const reservasTyped = (reservas ?? []) as ReservaConDetalles[]

  return (
    <div>
      <div className="mb-8">
        <h1 className="font-display text-3xl font-bold text-slate-900">Mis reservas</h1>
        <p className="text-muted-fg mt-1 text-sm">{clienteNombre ?? user.email}</p>
      </div>

      {reservasTyped.length === 0 ? (
        <Card variant="raised" className="text-center py-16">
          <p className="text-muted-fg text-lg">Todavía no tenés reservas.</p>
          <Link
            href="/"
            className="mt-4 inline-block px-6 py-2 bg-brand-600 text-white rounded-lg hover:bg-brand-700 transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand-500 focus-visible:ring-offset-2"
          >
            Buscar un vehículo
          </Link>
        </Card>
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
  const estado = ESTADO_LABELS[r.estado] ?? {
    label: r.estado,
    variant: 'muted' as BadgeVariant,
  }

  return (
    <Card variant="raised" className="p-5">
      <div className="flex items-start justify-between gap-4">
        <div>
          <p className="font-display font-semibold text-slate-900">
            {r.vehiculo
              ? `${r.vehiculo.marca} ${r.vehiculo.modelo}`
              : `Vehículo #${r.id_vehiculo}`}
          </p>
          {r.vehiculo && (
            <p className="text-muted-fg text-sm">{r.vehiculo.patente}</p>
          )}
        </div>
        <Badge variant={estado.variant}>{estado.label}</Badge>
      </div>

      <div className="mt-3 grid grid-cols-2 sm:grid-cols-3 gap-3 text-sm text-slate-600">
        <div>
          <span className="text-muted-fg text-xs uppercase tracking-wider">Desde</span>
          <p className="tabular-nums">{formatDateAR(r.fecha_inicio)}</p>
        </div>
        <div>
          <span className="text-muted-fg text-xs uppercase tracking-wider">Hasta</span>
          <p className="tabular-nums">{formatDateAR(r.fecha_fin_prevista)}</p>
        </div>
        <div>
          <span className="text-muted-fg text-xs uppercase tracking-wider">Tipo</span>
          <p className="capitalize">{r.tipo_reserva?.nombre ?? '—'}</p>
        </div>
      </div>

      {r.estado === 'cancelada' && r.motivo_cancelacion && (
        <p className="mt-2 text-xs text-muted-fg">
          <span className="font-medium">Motivo:</span> {r.motivo_cancelacion}
        </p>
      )}

      <div className="mt-3 flex items-center justify-between gap-3">
        <p className="text-muted-fg text-xs tabular-nums">
          Creada el {formatDateTimeAR(r.fecha_creacion)}
        </p>
        {r.estado === 'pendiente' && (
          <CancelarReservaButton idReserva={r.id_reserva} />
        )}
      </div>
    </Card>
  )
}
