import { createClient } from '@/lib/supabase/server'
import Link from 'next/link'

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
  ])

  const totalActivos = alquileresRes.count ?? 0
  const totalFacturas = facturasRes.count ?? 0
  const totalAuditoria = auditoriaRes.count ?? 0
  const totalVehiculos = vehiculosRes.count ?? 0
  const totalVencidasPendientes = devolucionesVencidasRes.count ?? 0

  return (
    <div>
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-gray-900">Panel de administración</h1>
        <p className="text-gray-500 mt-1">
          Gestioná alquileres, facturas y flota desde acá.
        </p>
      </div>

      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
        {/* Card: Alquileres activos */}
        <Link
          href="/admin/alquileres"
          className="group bg-white rounded-xl border border-gray-200 shadow-sm p-6 hover:shadow-md hover:border-blue-300 transition-all flex flex-col gap-4"
        >
          <div className="flex items-start justify-between">
            <div>
              <p className="text-sm font-medium text-gray-500 uppercase tracking-wide">
                Alquileres activos
              </p>
              <p className="text-4xl font-bold text-gray-900 mt-1">{totalActivos}</p>
            </div>
            <span className="text-3xl">🚗</span>
          </div>
          <p className="text-sm text-gray-500">
            Cerrá alquileres en curso y registrá la devolución del vehículo.
          </p>
          <span className="mt-auto text-sm font-medium text-blue-600 group-hover:text-blue-800 transition-colors">
            Ver alquileres →
          </span>
        </Link>

        {/* Card: Facturas emitidas */}
        <Link
          href="/admin/facturas"
          className="group bg-white rounded-xl border border-gray-200 shadow-sm p-6 hover:shadow-md hover:border-blue-300 transition-all flex flex-col gap-4"
        >
          <div className="flex items-start justify-between">
            <div>
              <p className="text-sm font-medium text-gray-500 uppercase tracking-wide">
                Facturas emitidas
              </p>
              <p className="text-4xl font-bold text-gray-900 mt-1">{totalFacturas}</p>
            </div>
            <span className="text-3xl">🧾</span>
          </div>
          <p className="text-sm text-gray-500">
            Consultá el historial de facturas y su desglose de costos.
          </p>
          <span className="mt-auto text-sm font-medium text-blue-600 group-hover:text-blue-800 transition-colors">
            Ver facturas →
          </span>
        </Link>

        {/* Card: Auditoría */}
        <Link
          href="/admin/auditoria"
          className="group bg-white rounded-xl border border-gray-200 shadow-sm p-6 hover:shadow-md hover:border-blue-300 transition-all flex flex-col gap-4"
        >
          <div className="flex items-start justify-between">
            <div>
              <p className="text-sm font-medium text-gray-500 uppercase tracking-wide">
                Auditoría
              </p>
              <p className="text-4xl font-bold text-gray-900 mt-1">{totalAuditoria}</p>
            </div>
            <span className="text-3xl">🗂️</span>
          </div>
          <p className="text-sm text-gray-500">
            Consultá el log completo de cambios sobre las tablas principales.
          </p>
          <span className="mt-auto text-sm font-medium text-blue-600 group-hover:text-blue-800 transition-colors">
            Ver auditoría →
          </span>
        </Link>

        {/* Card: Flota (Sprint 3) */}
        <Link
          href="/admin/vehiculos"
          className="group bg-white rounded-xl border border-gray-200 shadow-sm p-6 hover:shadow-md hover:border-blue-300 transition-all flex flex-col gap-4"
        >
          <div className="flex items-start justify-between">
            <div>
              <p className="text-sm font-medium text-gray-500 uppercase tracking-wide">
                Flota
              </p>
              <p className="text-4xl font-bold text-gray-900 mt-1">{totalVehiculos}</p>
            </div>
            <span className="text-3xl">🔧</span>
          </div>
          <p className="text-sm text-gray-500">
            Gestion de vehiculos: alta, edicion y baja via stored procedures.
          </p>
          <span className="mt-auto text-sm font-medium text-blue-600 group-hover:text-blue-800 transition-colors">
            Ver flota →
          </span>
        </Link>

        {/* Card: Devoluciones vencidas (Sprint 4 - R9) */}
        <Link
          href="/admin/devoluciones-vencidas"
          className="group bg-white rounded-xl border border-gray-200 shadow-sm p-6 hover:shadow-md hover:border-blue-300 transition-all flex flex-col gap-4"
        >
          <div className="flex items-start justify-between">
            <div>
              <p className="text-sm font-medium text-gray-500 uppercase tracking-wide">
                Devoluciones vencidas
              </p>
              <p className="text-4xl font-bold text-gray-900 mt-1">
                {totalVencidasPendientes}
              </p>
              <p className="text-xs text-gray-400 mt-0.5">pendientes de notificar</p>
            </div>
            <span className="text-3xl">⏰</span>
          </div>
          <p className="text-sm text-gray-500">
            Detectadas automáticamente cada 6 horas por el job pg_cron.
          </p>
          <span className="mt-auto text-sm font-medium text-blue-600 group-hover:text-blue-800 transition-colors">
            Ver listado →
          </span>
        </Link>

        {/* Card: Nuevo alquiler (Sprint 3) */}
        <Link
          href="/admin/alquileres/nuevo"
          className="group bg-white rounded-xl border border-gray-200 shadow-sm p-6 hover:shadow-md hover:border-blue-300 transition-all flex flex-col gap-4"
        >
          <div className="flex items-start justify-between">
            <div>
              <p className="text-sm font-medium text-gray-500 uppercase tracking-wide">
                Nuevo alquiler
              </p>
              <p className="text-lg font-semibold text-gray-900 mt-1">Registrar</p>
            </div>
            <span className="text-3xl">➕</span>
          </div>
          <p className="text-sm text-gray-500">
            Da de alta un alquiler con reserva previa o walk-in (sin reserva).
          </p>
          <span className="mt-auto text-sm font-medium text-blue-600 group-hover:text-blue-800 transition-colors">
            Registrar alquiler →
          </span>
        </Link>
      </div>
    </div>
  )
}
