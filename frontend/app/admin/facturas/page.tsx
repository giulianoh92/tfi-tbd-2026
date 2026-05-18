import { createClient } from '@/lib/supabase/server'
import Link from 'next/link'
import type { Factura, Cliente } from '@/types/database'

type FacturaConCliente = Factura & {
  cliente: Pick<Cliente, 'nombre' | 'apellido'> | null
}

/**
 * Lista todas las facturas emitidas con link al detalle individual.
 * RLS policy factura_staff_all garantiza acceso solo a usuarios staff.
 */
export default async function FacturasPage() {
  const supabase = await createClient()

  // Join directo: factura→cliente (FK única, sin hint de constraint)
  const { data: facturas, error } = await supabase
    .from('factura')
    .select(`
      *,
      cliente ( nombre, apellido )
    `)
    .order('fecha_emision', { ascending: false })

  if (error) {
    return (
      <div className="rounded-lg bg-red-50 border border-red-200 p-6">
        <p className="text-red-700 font-medium">Error al cargar facturas</p>
        <p className="text-red-500 text-sm mt-1">{error.message}</p>
      </div>
    )
  }

  const filas = (facturas ?? []) as FacturaConCliente[]

  return (
    <div>
      <div className="flex items-center justify-between mb-8">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Facturas emitidas</h1>
          <p className="text-gray-500 mt-1 text-sm">
            {filas.length} factura{filas.length !== 1 ? 's' : ''} en total
          </p>
        </div>
        <Link
          href="/admin"
          className="text-sm text-blue-600 hover:text-blue-800 font-medium"
        >
          ← Panel
        </Link>
      </div>

      {filas.length === 0 ? (
        <div className="text-center py-16">
          <p className="text-gray-500 text-lg">Todavía no hay facturas emitidas.</p>
        </div>
      ) : (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
          {filas.map((f) => {
            const fechaEmision = new Date(f.fecha_emision).toLocaleDateString('es-AR', {
              day: '2-digit',
              month: '2-digit',
              year: 'numeric',
            })

            return (
              <div
                key={f.id_factura}
                className="bg-white rounded-xl border border-gray-200 shadow-sm p-5 flex flex-col gap-3 hover:shadow-md transition-shadow"
              >
                <div className="flex items-start justify-between gap-2">
                  <div>
                    <p className="font-semibold text-gray-900 text-sm">{f.numero_factura}</p>
                    <p className="text-gray-400 text-xs mt-0.5">{fechaEmision}</p>
                  </div>
                  <span className="shrink-0 text-xs font-medium px-2 py-0.5 rounded-full bg-green-50 text-green-700 border border-green-200">
                    Emitida
                  </span>
                </div>

                <div>
                  <p className="text-xs text-gray-400 uppercase tracking-wide">Cliente</p>
                  <p className="text-sm text-gray-700 font-medium">
                    {f.cliente
                      ? `${f.cliente.nombre} ${f.cliente.apellido}`
                      : `#${f.id_cliente}`}
                  </p>
                </div>

                <div className="mt-auto flex items-center justify-between pt-2 border-t border-gray-100">
                  <div>
                    <p className="text-xs text-gray-400 uppercase tracking-wide">Total</p>
                    <p className="text-lg font-bold text-gray-900">
                      ${Number(f.total).toLocaleString('es-AR', { minimumFractionDigits: 2 })}
                    </p>
                  </div>
                  <Link
                    href={`/admin/facturas/${f.id_factura}`}
                    className="text-sm font-medium text-blue-600 hover:text-blue-800 transition-colors"
                  >
                    Ver detalle →
                  </Link>
                </div>
              </div>
            )
          })}
        </div>
      )}
    </div>
  )
}
