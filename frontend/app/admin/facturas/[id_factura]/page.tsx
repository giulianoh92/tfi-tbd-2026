import { createClient } from '@/lib/supabase/server'
import { notFound } from 'next/navigation'
import Link from 'next/link'
import type { Factura, Alquiler, Vehiculo, Cliente } from '@/types/database'

type FacturaCompleta = Factura & {
  cliente: Pick<Cliente, 'nombre' | 'apellido' | 'dni'> | null
  alquiler: (Pick<Alquiler, 'id_alquiler' | 'fecha_inicio' | 'fecha_fin_prevista' | 'fecha_devolucion_real' | 'km_inicio' | 'km_fin'> & {
    vehiculo: Pick<Vehiculo, 'marca' | 'modelo' | 'patente'> | null
  }) | null
}

interface Props {
  params: Promise<{ id_factura: string }>
}

/**
 * Vista detallada de una factura individual.
 * Diseño estilo "papel blanco" apto para impresión.
 * RLS policy factura_staff_all garantiza acceso solo a usuarios staff.
 */
export default async function FacturaDetallePage({ params }: Props) {
  const { id_factura } = await params
  const id = parseInt(id_factura, 10)

  if (isNaN(id)) notFound()

  const supabase = await createClient()

  // factura → cliente (FK única)
  // factura → alquiler (FK única) → vehiculo (FK única)
  // PostgREST infiere el join sin hints porque cada par tiene una sola FK
  const { data, error } = await supabase
    .from('factura')
    .select(`
      *,
      cliente ( nombre, apellido, dni ),
      alquiler (
        id_alquiler,
        fecha_inicio,
        fecha_fin_prevista,
        fecha_devolucion_real,
        km_inicio,
        km_fin,
        vehiculo ( marca, modelo, patente )
      )
    `)
    .eq('id_factura', id)
    .single()

  if (error || !data) {
    notFound()
  }

  const factura = data as FacturaCompleta

  // Helpers de formato
  const fmt = (n: number | string | null | undefined) =>
    n != null
      ? `$${Number(n).toLocaleString('es-AR', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`
      : '—'

  const fmtDate = (d: string | null | undefined) =>
    d
      ? new Date(d).toLocaleDateString('es-AR', { day: '2-digit', month: '2-digit', year: 'numeric' })
      : '—'

  const porcentajeRecargo = factura.porcentaje_recargo_aplicado != null
    ? `${(Number(factura.porcentaje_recargo_aplicado) * 100).toFixed(0)}%`
    : '—'

  return (
    <div>
      {/* Nav superior — oculto al imprimir */}
      <div className="flex items-center gap-4 mb-8 print:hidden">
        <Link
          href="/admin/facturas"
          className="text-sm text-blue-600 hover:text-blue-800 font-medium"
        >
          ← Volver
        </Link>
        <button
          onClick={undefined}
          className="text-sm text-gray-500 hover:text-gray-700"
          // onclick se maneja desde el browser; este botón queda como placeholder
          // para que el usuario use Ctrl+P / Cmd+P del browser
        >
          Imprimir
        </button>
      </div>

      {/* "Papel" de la factura */}
      <div className="bg-white rounded-xl border border-gray-200 shadow-sm p-8 max-w-2xl mx-auto print:shadow-none print:rounded-none print:border-0">

        {/* Header */}
        <div className="flex items-start justify-between pb-6 border-b border-gray-200">
          <div>
            <h1 className="text-2xl font-bold text-gray-900">AutoRenta</h1>
            <p className="text-gray-500 text-sm mt-0.5">Sistema de Alquiler de Vehículos</p>
          </div>
          <div className="text-right">
            <p className="text-sm font-semibold text-gray-500 uppercase tracking-wide">Factura</p>
            <p className="text-xl font-bold text-gray-900 mt-0.5">{factura.numero_factura}</p>
            <p className="text-sm text-gray-500 mt-1">{fmtDate(factura.fecha_emision)}</p>
          </div>
        </div>

        {/* Cliente */}
        <div className="py-5 border-b border-gray-100">
          <p className="text-xs font-semibold text-gray-400 uppercase tracking-wide mb-1">
            Facturado a
          </p>
          {factura.cliente ? (
            <>
              <p className="font-semibold text-gray-900">
                {factura.cliente.nombre} {factura.cliente.apellido}
              </p>
              <p className="text-sm text-gray-500">DNI {factura.cliente.dni}</p>
            </>
          ) : (
            <p className="text-sm text-gray-500">Cliente #{factura.id_cliente}</p>
          )}
        </div>

        {/* Desglose de costos */}
        <div className="py-5 border-b border-gray-100">
          <p className="text-xs font-semibold text-gray-400 uppercase tracking-wide mb-3">
            Desglose
          </p>
          <table className="w-full text-sm">
            <tbody className="divide-y divide-gray-50">
              <tr>
                <td className="py-2 text-gray-600">Precio por día aplicado</td>
                <td className="py-2 text-right font-medium text-gray-900">
                  {fmt(factura.precio_por_dia_aplicado)}
                </td>
              </tr>
              <tr>
                <td className="py-2 text-gray-600">Costo base</td>
                <td className="py-2 text-right font-medium text-gray-900">
                  {fmt(factura.costo_base)}
                </td>
              </tr>
              {(factura.horas_excedidas ?? 0) > 0 && (
                <tr>
                  <td className="py-2 text-gray-600">
                    Horas excedidas ({factura.horas_excedidas}h · recargo {porcentajeRecargo})
                  </td>
                  <td className="py-2 text-right font-medium text-orange-700">
                    {fmt(factura.recargo_excedente)}
                  </td>
                </tr>
              )}
              {(factura.horas_excedidas ?? 0) === 0 && (
                <tr>
                  <td className="py-2 text-gray-400 italic">Sin horas excedidas</td>
                  <td className="py-2 text-right text-gray-400">—</td>
                </tr>
              )}
            </tbody>
            <tfoot>
              <tr className="border-t-2 border-gray-200">
                <td className="pt-3 font-bold text-gray-900">Total</td>
                <td className="pt-3 text-right font-bold text-xl text-gray-900">
                  {fmt(factura.total)}
                </td>
              </tr>
            </tfoot>
          </table>
        </div>

        {/* Datos del alquiler y vehículo */}
        {factura.alquiler && (
          <div className="pt-5">
            <p className="text-xs font-semibold text-gray-400 uppercase tracking-wide mb-3">
              Alquiler #{factura.alquiler.id_alquiler}
            </p>
            <div className="grid grid-cols-2 gap-x-6 gap-y-2 text-sm">
              {factura.alquiler.vehiculo && (
                <>
                  <div>
                    <p className="text-gray-400 text-xs uppercase tracking-wide">Vehículo</p>
                    <p className="text-gray-700">
                      {factura.alquiler.vehiculo.marca} {factura.alquiler.vehiculo.modelo}
                    </p>
                    <p className="text-gray-400 text-xs">{factura.alquiler.vehiculo.patente}</p>
                  </div>
                </>
              )}
              <div>
                <p className="text-gray-400 text-xs uppercase tracking-wide">Período</p>
                <p className="text-gray-700">
                  {fmtDate(factura.alquiler.fecha_inicio)} → {fmtDate(factura.alquiler.fecha_devolucion_real ?? factura.alquiler.fecha_fin_prevista)}
                </p>
              </div>
              <div>
                <p className="text-gray-400 text-xs uppercase tracking-wide">Km recorridos</p>
                <p className="text-gray-700">
                  {factura.alquiler.km_inicio != null && factura.alquiler.km_fin != null
                    ? `${(factura.alquiler.km_fin - factura.alquiler.km_inicio).toLocaleString('es-AR')} km`
                    : '—'}
                </p>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  )
}
