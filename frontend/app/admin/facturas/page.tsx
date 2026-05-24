import { createClient } from '@/lib/supabase/server'
import Link from 'next/link'
import { ArrowRight } from 'lucide-react'
import type { Factura, Cliente } from '@/types/database'
import { Card } from '@/components/ui/Card'
import { Badge } from '@/components/ui/Badge'
import { formatARS, formatDateAR } from '@/lib/format'

type FacturaConCliente = Factura & {
  cliente: Pick<Cliente, 'nombre' | 'apellido'> | null
}

/**
 * Lista todas las facturas emitidas con link al detalle individual.
 * RLS policy factura_staff_all garantiza acceso solo a usuarios staff.
 */
export default async function FacturasPage() {
  const supabase = await createClient()

  const { data: facturas, error } = await supabase
    .from('factura')
    .select(`
      *,
      cliente ( nombre, apellido )
    `)
    .order('fecha_emision', { ascending: false })

  if (error) {
    return (
      <div role="alert" className="rounded-lg bg-danger-bg border border-danger-border p-6">
        <p className="text-danger-fg font-medium">Error al cargar facturas</p>
        <p className="text-danger-fg/80 text-sm mt-1">{error.message}</p>
      </div>
    )
  }

  const filas = (facturas ?? []) as FacturaConCliente[]

  return (
    <div>
      <div className="mb-8">
        <h1 className="font-display text-3xl font-bold text-slate-900">Facturas emitidas</h1>
        <p className="text-muted-fg mt-1 text-sm">
          {filas.length} factura{filas.length !== 1 ? 's' : ''} en total
        </p>
      </div>

      {filas.length === 0 ? (
        <Card variant="raised" className="text-center py-16">
          <p className="text-muted-fg text-lg">Todavía no hay facturas emitidas.</p>
        </Card>
      ) : (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
          {filas.map((f) => (
            <Card
              key={f.id_factura}
              variant="raised"
              className="p-5 flex flex-col gap-3 hover:-translate-y-0.5 hover:shadow-md transition-all"
            >
              <div className="flex items-start justify-between gap-2">
                <div>
                  <p className="font-semibold text-slate-900 text-sm">{f.numero_factura}</p>
                  <p className="text-muted-fg text-xs mt-0.5">{formatDateAR(f.fecha_emision)}</p>
                </div>
                <Badge variant="success">Emitida</Badge>
              </div>

              <div>
                <p className="text-xs text-muted-fg uppercase tracking-wider">Cliente</p>
                <p className="text-sm text-slate-700 font-medium">
                  {f.cliente
                    ? `${f.cliente.nombre} ${f.cliente.apellido}`
                    : `#${f.id_cliente}`}
                </p>
              </div>

              <div className="mt-auto flex items-center justify-between pt-2 border-t border-slate-100">
                <div>
                  <p className="text-xs text-muted-fg uppercase tracking-wider">Total</p>
                  <p className="text-lg font-bold text-slate-900 tabular-nums">
                    {formatARS(Number(f.total))}
                  </p>
                </div>
                <Link
                  href={`/admin/facturas/${f.id_factura}`}
                  className="inline-flex items-center gap-1 text-sm font-medium text-brand-700 hover:underline focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand-500 rounded"
                >
                  Ver detalle
                  <ArrowRight className="w-3.5 h-3.5" aria-hidden="true" />
                </Link>
              </div>
            </Card>
          ))}
        </div>
      )}
    </div>
  )
}
