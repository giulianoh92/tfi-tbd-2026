import { createClient } from '@/lib/supabase/server'
import { notFound } from 'next/navigation'
import type { Factura, Alquiler, Vehiculo, Cliente } from '@/types/database'
import { Card } from '@/components/ui/Card'
import { Badge } from '@/components/ui/Badge'
import { formatDateAR } from '@/lib/format'

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
 * Vista detallada de una factura individual — formato documento.
 * Diseño "papel" apto para impresión y descarga.
 * RLS: factura_staff_all.
 */
export default async function FacturaDetallePage({ params }: Props) {
  const { id_factura } = await params
  const id = parseInt(id_factura, 10)

  if (isNaN(id)) notFound()

  const supabase = await createClient()

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

  const fmt = (n: number | string | null | undefined) =>
    n != null
      ? new Intl.NumberFormat('es-AR', {
          style: 'currency',
          currency: 'ARS',
          minimumFractionDigits: 2,
          maximumFractionDigits: 2,
        }).format(Number(n))
      : '—'

  const porcentajeRecargo = factura.porcentaje_recargo_aplicado != null
    ? `${(Number(factura.porcentaje_recargo_aplicado) * 100).toFixed(0)}%`
    : '—'

  return (
    <div>
      {/* "Papel" de la factura */}
      <Card
        variant="paper"
        className="p-10 max-w-2xl mx-auto print:shadow-none print:rounded-none print:border-0"
      >
        {/* Header emisor */}
        <div className="flex items-start justify-between pb-6 border-b border-amber-200">
          <div>
            <h1 className="font-display text-2xl font-bold text-slate-900">AutoRenta</h1>
            <p className="text-muted-fg text-sm mt-0.5">Sistema de Alquiler de Vehículos</p>
            <p className="text-muted-fg text-xs mt-2">CUIT 30-12345678-9</p>
            <p className="text-muted-fg text-xs">Condición IVA: Responsable Inscripto</p>
          </div>
          <div className="text-right">
            <Badge variant="success">Emitida</Badge>
            <p className="text-xs font-semibold text-muted-fg uppercase tracking-wider mt-2">Factura</p>
            <p className="font-display text-xl font-bold text-slate-900 mt-0.5 tabular-nums">
              {factura.numero_factura}
            </p>
            <p className="text-sm text-muted-fg mt-1 tabular-nums">
              {formatDateAR(factura.fecha_emision)}
            </p>
          </div>
        </div>

        {/* Cliente */}
        <div className="py-5 border-b border-amber-100">
          <p className="text-xs font-semibold text-muted-fg uppercase tracking-wider mb-1">
            Facturado a
          </p>
          {factura.cliente ? (
            <>
              <p className="font-semibold text-slate-900">
                {factura.cliente.nombre} {factura.cliente.apellido}
              </p>
              <p className="text-sm text-muted-fg">DNI {factura.cliente.dni}</p>
            </>
          ) : (
            <p className="text-sm text-muted-fg">Cliente #{factura.id_cliente}</p>
          )}
        </div>

        {/* Desglose de costos */}
        <div className="py-5 border-b border-amber-100">
          <p className="text-xs font-semibold text-muted-fg uppercase tracking-wider mb-3">
            Desglose
          </p>
          <table className="w-full text-sm">
            <tbody className="divide-y divide-amber-100/60">
              <tr>
                <td className="py-2 text-slate-700">Precio por día aplicado</td>
                <td className="py-2 text-right font-medium text-slate-900 tabular-nums">
                  {fmt(factura.precio_por_dia_aplicado)}
                </td>
              </tr>
              <tr>
                <td className="py-2 text-slate-700">Costo base</td>
                <td className="py-2 text-right font-medium text-slate-900 tabular-nums">
                  {fmt(factura.costo_base)}
                </td>
              </tr>
              {(factura.horas_excedidas ?? 0) > 0 ? (
                <tr>
                  <td className="py-2 text-slate-700">
                    Horas excedidas ({factura.horas_excedidas}h · recargo {porcentajeRecargo})
                  </td>
                  <td className="py-2 text-right font-medium text-orange-700 tabular-nums">
                    {fmt(factura.recargo_excedente)}
                  </td>
                </tr>
              ) : (
                <tr>
                  <td className="py-2 text-muted-fg italic">Sin horas excedidas</td>
                  <td className="py-2 text-right text-muted-fg">—</td>
                </tr>
              )}
            </tbody>
            <tfoot>
              <tr className="border-t-2 border-amber-300">
                <td className="pt-3 font-bold text-slate-900">Total</td>
                <td className="pt-3 text-right font-display font-bold text-xl text-slate-900 tabular-nums">
                  {fmt(factura.total)}
                </td>
              </tr>
            </tfoot>
          </table>
        </div>

        {/* Datos del alquiler y vehículo */}
        {factura.alquiler && (
          <div className="pt-5">
            <p className="text-xs font-semibold text-muted-fg uppercase tracking-wider mb-3">
              Alquiler #{factura.alquiler.id_alquiler}
            </p>
            <div className="grid grid-cols-2 gap-x-6 gap-y-3 text-sm">
              {factura.alquiler.vehiculo && (
                <div>
                  <p className="text-muted-fg text-xs uppercase tracking-wider">Vehículo</p>
                  <p className="text-slate-700">
                    {factura.alquiler.vehiculo.marca} {factura.alquiler.vehiculo.modelo}
                  </p>
                  <p className="text-muted-fg text-xs font-mono">{factura.alquiler.vehiculo.patente}</p>
                </div>
              )}
              <div>
                <p className="text-muted-fg text-xs uppercase tracking-wider">Período</p>
                <p className="text-slate-700 tabular-nums">
                  {formatDateAR(factura.alquiler.fecha_inicio)} →{' '}
                  {formatDateAR(
                    factura.alquiler.fecha_devolucion_real ?? factura.alquiler.fecha_fin_prevista
                  )}
                </p>
              </div>
              <div>
                <p className="text-muted-fg text-xs uppercase tracking-wider">Km recorridos</p>
                <p className="text-slate-700 tabular-nums">
                  {factura.alquiler.km_inicio != null && factura.alquiler.km_fin != null
                    ? `${(factura.alquiler.km_fin - factura.alquiler.km_inicio).toLocaleString('es-AR')} km`
                    : '—'}
                </p>
              </div>
            </div>
          </div>
        )}

        {/* Footer legal */}
        <div className="pt-6 mt-6 border-t border-amber-200">
          <p className="text-[10px] text-muted-fg leading-relaxed">
            Documento emitido electronicamente — TFI TBD 2026. Esta factura es valida sin firma
            ológrafa. Conserve el original para sus registros. Por consultas sobre este
            comprobante contactese con AutoRenta.
          </p>
        </div>
      </Card>
    </div>
  )
}

