import { createClient } from '@/lib/supabase/server'
import Link from 'next/link'
import { notFound } from 'next/navigation'
import type { AuditLog, Json } from '@/types/database'

const TIPO_OP_LABEL: Record<string, { label: string; clase: string }> = {
  I: { label: 'INSERT', clase: 'bg-green-50 text-green-700 border-green-200' },
  U: { label: 'UPDATE', clase: 'bg-blue-50 text-blue-700 border-blue-200' },
  D: { label: 'DELETE', clase: 'bg-red-50 text-red-700 border-red-200' },
}

/**
 * Detalle de un registro de auditoria (R1).
 *
 * Muestra valores_anteriores y valores_nuevos lado a lado con resaltado
 * de columnas que cambiaron (UPDATE). Para INSERT solo se muestra el
 * lado "nuevo"; para DELETE solo el "anterior".
 */
export default async function AuditoriaDetallePage({
  params,
}: {
  params: Promise<{ id: string }>
}) {
  const { id } = await params
  const supabase = await createClient()

  const { data, error } = await supabase
    .from('audit_log')
    .select('*')
    .eq('id_audit', id)
    .maybeSingle()

  if (error) {
    return (
      <div className="rounded-lg bg-red-50 border border-red-200 p-6">
        <p className="text-red-700 font-medium">Error al cargar el registro</p>
        <p className="text-red-500 text-sm mt-1">{error.message}</p>
      </div>
    )
  }

  if (!data) {
    notFound()
  }

  const row = data as AuditLog
  const op = TIPO_OP_LABEL[row.tipo_op] ?? {
    label: row.tipo_op,
    clase: 'bg-gray-50 text-gray-700 border-gray-200',
  }
  const fecha = new Date(row.fecha_hora).toLocaleString('es-AR', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
  })

  const anterior = (row.valores_anteriores ?? {}) as Record<string, Json>
  const nuevo = (row.valores_nuevos ?? {}) as Record<string, Json>

  // Union de claves para el diff (orden alfabetico).
  const claves = Array.from(
    new Set([...Object.keys(anterior), ...Object.keys(nuevo)]),
  ).sort()

  // Stringificacion estable para comparar (un valor que paso de 1 a "1" deberia
  // mostrarse como cambio; JSON.stringify discrimina tipos primitivos).
  const stringify = (v: Json | undefined) =>
    v === undefined ? '—' : JSON.stringify(v, null, 2)

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Auditoría #{row.id_audit}</h1>
          <p className="text-gray-500 mt-1 text-sm">Detalle del cambio registrado</p>
        </div>
        <Link
          href="/admin/auditoria"
          className="text-sm text-blue-600 hover:text-blue-800 font-medium"
        >
          ← Volver al log
        </Link>
      </div>

      {/* Cabecera */}
      <div className="bg-white rounded-xl border border-gray-200 shadow-sm p-5 mb-6 grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-6 gap-4">
        <div>
          <p className="text-xs font-semibold text-gray-400 uppercase tracking-wide">Operación</p>
          <span
            className={`mt-1 inline-flex items-center text-xs font-semibold px-2 py-0.5 rounded-full border ${op.clase}`}
          >
            {op.label}
          </span>
        </div>
        <div>
          <p className="text-xs font-semibold text-gray-400 uppercase tracking-wide">Tabla</p>
          <p className="text-sm text-gray-900 font-medium mt-1">{row.tabla}</p>
        </div>
        <div>
          <p className="text-xs font-semibold text-gray-400 uppercase tracking-wide">
            Id registro
          </p>
          <p className="text-sm text-gray-900 font-mono mt-1">{row.id_registro ?? '—'}</p>
        </div>
        <div>
          <p className="text-xs font-semibold text-gray-400 uppercase tracking-wide">Fecha</p>
          <p className="text-sm text-gray-700 mt-1">{fecha}</p>
        </div>
        <div>
          <p className="text-xs font-semibold text-gray-400 uppercase tracking-wide">Usuario DB</p>
          <p className="text-sm text-gray-700 font-mono mt-1">{row.usuario_db}</p>
        </div>
        <div>
          <p className="text-xs font-semibold text-gray-400 uppercase tracking-wide">
            Usuario app
          </p>
          <p className="text-xs text-gray-700 font-mono mt-1 break-all">
            {row.usuario_app ?? '—'}
          </p>
        </div>
      </div>

      {/* Diff */}
      {row.tipo_op === 'U' ? (
        <div className="bg-white rounded-xl border border-gray-200 shadow-sm overflow-hidden">
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wide">
                    Columna
                  </th>
                  <th className="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wide">
                    Valor anterior
                  </th>
                  <th className="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wide">
                    Valor nuevo
                  </th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100">
                {claves.map((k) => {
                  const a = stringify(anterior[k])
                  const n = stringify(nuevo[k])
                  const cambio = a !== n
                  return (
                    <tr
                      key={k}
                      className={cambio ? 'bg-amber-50' : ''}
                    >
                      <td className="px-4 py-3 text-sm font-medium text-gray-900 align-top whitespace-nowrap">
                        {k}
                        {cambio && (
                          <span className="ml-2 inline-flex items-center text-[10px] font-semibold px-1.5 py-0.5 rounded bg-amber-200 text-amber-900">
                            cambió
                          </span>
                        )}
                      </td>
                      <td className="px-4 py-3 text-xs text-gray-700 font-mono align-top">
                        <pre className="whitespace-pre-wrap break-all">{a}</pre>
                      </td>
                      <td className="px-4 py-3 text-xs text-gray-700 font-mono align-top">
                        <pre className="whitespace-pre-wrap break-all">{n}</pre>
                      </td>
                    </tr>
                  )
                })}
              </tbody>
            </table>
          </div>
        </div>
      ) : (
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
          {/* Anterior */}
          {row.tipo_op === 'D' && (
            <div className="bg-white rounded-xl border border-gray-200 shadow-sm overflow-hidden">
              <div className="bg-red-50 border-b border-red-100 px-4 py-2">
                <h2 className="text-sm font-semibold text-red-700">
                  Valores anteriores (eliminado)
                </h2>
              </div>
              <pre className="p-4 text-xs text-gray-700 font-mono whitespace-pre-wrap break-all overflow-x-auto">
                {JSON.stringify(row.valores_anteriores, null, 2)}
              </pre>
            </div>
          )}

          {/* Nuevo */}
          {row.tipo_op === 'I' && (
            <div className="bg-white rounded-xl border border-gray-200 shadow-sm overflow-hidden">
              <div className="bg-green-50 border-b border-green-100 px-4 py-2">
                <h2 className="text-sm font-semibold text-green-700">
                  Valores nuevos (insertado)
                </h2>
              </div>
              <pre className="p-4 text-xs text-gray-700 font-mono whitespace-pre-wrap break-all overflow-x-auto">
                {JSON.stringify(row.valores_nuevos, null, 2)}
              </pre>
            </div>
          )}
        </div>
      )}
    </div>
  )
}
