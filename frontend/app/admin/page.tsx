import { createClient } from '@/lib/supabase/server'
import Link from 'next/link'
import {
  Car,
  Receipt,
  History,
  Wrench,
  AlarmClock,
  Plus,
  ArrowRight,
  CarFront,
  type LucideIcon,
} from 'lucide-react'
import { Card } from '@/components/ui/Card'
import { cn } from '@/lib/cn'

/**
 * Landing del panel staff.
 * Muestra cards de acceso rápido con conteos en tiempo real.
 */
export default async function AdminPage() {
  const supabase = await createClient()

  // Conteos en paralelo para las cards
  const [
    alquileresRes,
    facturasRes,
    auditoriaRes,
    vehiculosRes,
    devolucionesVencidasRes,
    mantenimientosVigentesRes,
  ] = await Promise.all([
    supabase
      .from('alquiler')
      .select('id_alquiler', { count: 'exact', head: true })
      .eq('estado', 'activo'),
    supabase
      .from('factura')
      .select('id_factura', { count: 'exact', head: true }),
    supabase
      .from('audit_log')
      .select('id_audit', { count: 'exact', head: true }),
    supabase
      .from('vehiculo')
      .select('id_vehiculo', { count: 'exact', head: true }),
    supabase
      .from('devolucion_vencida')
      .select('id_devolucion_vencida', { count: 'exact', head: true })
      .eq('notificado', false),
    supabase
      .from('mantenimiento')
      .select('id_mantenimiento', { count: 'exact', head: true })
      .is('fecha_devolucion', null),
  ])

  const totalActivos = alquileresRes.count ?? 0
  const totalFacturas = facturasRes.count ?? 0
  const totalAuditoria = auditoriaRes.count ?? 0
  const totalVehiculos = vehiculosRes.count ?? 0
  const totalVencidasPendientes = devolucionesVencidasRes.count ?? 0
  const totalMantenimientosVigentes = mantenimientosVigentesRes.count ?? 0

  return (
    <div>
      <div className="mb-8">
        <h1 className="font-display text-3xl font-bold text-slate-900">
          Panel de administracion
        </h1>
        <p className="text-muted-fg mt-1">
          Gestiona alquileres, facturas y flota desde aca.
        </p>
      </div>

      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
        <AdminCard
          href="/admin/alquileres"
          icon={Car}
          eyebrow="Alquileres activos"
          metric={totalActivos.toString()}
          description="Cerra alquileres en curso y registra la devolucion del vehiculo."
          cta="Ver alquileres"
        />
        <AdminCard
          href="/admin/facturas"
          icon={Receipt}
          eyebrow="Facturas emitidas"
          metric={totalFacturas.toString()}
          description="Consulta el historial de facturas y su desglose de costos."
          cta="Ver facturas"
        />
        <AdminCard
          href="/admin/auditoria"
          icon={History}
          eyebrow="Auditoria"
          metric={totalAuditoria.toString()}
          description="Consulta el log completo de cambios sobre las tablas principales."
          cta="Ver auditoria"
        />
        <AdminCard
          href="/admin/vehiculos"
          icon={CarFront}
          eyebrow="Flota"
          metric={totalVehiculos.toString()}
          description="Gestiona altas, ediciones y bajas de la flota."
          cta="Ver flota"
        />
        <AdminCard
          href="/admin/mantenimientos"
          icon={Wrench}
          eyebrow="Mantenimientos"
          metric={totalMantenimientosVigentes.toString()}
          metricSubtitle="en taller"
          description="Envíos a taller y registro de devoluciones."
          cta="Ver mantenimientos"
          accent={totalMantenimientosVigentes > 0 ? 'warning' : 'neutral'}
        />
        <AdminCard
          href="/admin/devoluciones-vencidas"
          icon={AlarmClock}
          eyebrow="Devoluciones vencidas"
          metric={totalVencidasPendientes.toString()}
          metricSubtitle="pendientes de notificar"
          description="Detectadas automaticamente cada 6 horas por el job pg_cron."
          cta="Ver listado"
          accent={totalVencidasPendientes > 0 ? 'warning' : 'neutral'}
        />
        <AdminCard
          href="/admin/alquileres/nuevo"
          icon={Plus}
          eyebrow="Nuevo alquiler"
          metric="Registrar"
          metricSize="text-lg"
          description="Da de alta un alquiler con reserva previa o walk-in (sin reserva)."
          cta="Registrar alquiler"
        />
      </div>
    </div>
  )
}

function AdminCard({
  href,
  icon: Icon,
  eyebrow,
  metric,
  metricSize,
  metricSubtitle,
  description,
  cta,
  accent = 'neutral',
}: {
  href: string
  icon: LucideIcon
  eyebrow: string
  metric: string
  metricSize?: string
  metricSubtitle?: string
  description: string
  cta: string
  accent?: 'neutral' | 'warning'
}) {
  return (
    <Link href={href} className="group focus-visible:outline-none">
      <Card
        variant="raised"
        className={cn(
          'h-full p-6 flex flex-col gap-4',
          'transition-all duration-200 ease-out',
          'group-hover:-translate-y-0.5 group-hover:shadow-md group-hover:border-brand-200',
          'group-focus-visible:ring-2 group-focus-visible:ring-brand-500 group-focus-visible:ring-offset-2'
        )}
      >
        <div className="flex items-start justify-between">
          <div>
            <p className="text-xs font-semibold text-muted-fg uppercase tracking-wider">
              {eyebrow}
            </p>
            <p
              className={cn(
                'font-display font-bold text-slate-900 mt-1 tabular-nums',
                metricSize ?? 'text-4xl'
              )}
            >
              {metric}
            </p>
            {metricSubtitle && (
              <p className="text-xs text-muted-fg mt-0.5">{metricSubtitle}</p>
            )}
          </div>
          <div
            className={cn(
              'flex items-center justify-center w-10 h-10 rounded-lg',
              accent === 'warning'
                ? 'bg-warning-bg text-warning-fg'
                : 'bg-brand-50 text-brand-700'
            )}
          >
            <Icon className="w-5 h-5" aria-hidden="true" />
          </div>
        </div>
        <p className="text-sm text-muted-fg">{description}</p>
        <span className="mt-auto inline-flex items-center gap-1 text-sm font-medium text-brand-700 group-hover:gap-2 transition-all">
          {cta}
          <ArrowRight className="w-4 h-4" aria-hidden="true" />
        </span>
      </Card>
    </Link>
  )
}
