import { createClient } from '@/lib/supabase/server'
import { notFound } from 'next/navigation'
import type { AuditLog, Json } from '@/types/database'
import { Card } from '@/components/ui/Card'
import { Badge } from '@/components/ui/Badge'
import { formatDateTimeAR } from '@/lib/format'

type BadgeVariant = 'success' | 'info' | 'danger' | 'muted'

const TIPO_OP_LABEL: Record<string, { label: string; variant: BadgeVariant }> = {
  I: { label: 'INSERT', variant: 'success' },
  U: { label: 'UPDATE', variant: 'info' },
  D: { label: 'DELETE', variant: 'danger' },
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
      <div role="alert" className="rounded-lg bg-danger-bg border border-danger-border p-6">
        <p className="text-danger-fg font-medium">Error al cargar el registro</p>
        <p className="text-danger-fg/80 text-sm mt-1">{error.message}</p>
      </div>
    )
  }

  if (!data) {
    notFound()
  }

  const row = data as AuditLog
  const op = TIPO_OP_LABEL[row.tipo_op] ?? {
    label: row.tipo_op,
    variant: 'muted' as BadgeVariant,
  }
  const fecha = formatDateTimeAR(row.fecha_hora)

  // Resolver nombre del usuario_app si existe.
  let usuarioNombre: string | null = null
  if (row.usuario_app) {
    const { data: uRow } = await supabase
      .from('vw_usuario_legible')
      .select('nombre')
      .eq('id', row.usuario_app)
      .maybeSingle<{ nombre: string | null }>()
    usuarioNombre = uRow?.nombre ?? null
  }

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
      <div className="mb-6">
        <h1 className="font-display text-3xl font-bold text-slate-900">Auditoría #{row.id_audit}</h1>
        <p className="text-muted-fg mt-1 text-sm">Detalle del cambio registrado</p>
      </div>

      {/* Cabecera */}
      <Card variant="raised" className="p-5 mb-6 grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-6 gap-4">
        <div>
          <p className="text-xs font-semibold text-muted-fg uppercase tracking-wider">Operación</p>
          <div className="mt-1">
            <Badge variant={op.variant}>{op.label}</Badge>
          </div>
        </div>
        <div>
          <p className="text-xs font-semibold text-muted-fg uppercase tracking-wider">Tabla</p>
          <p className="text-sm text-slate-900 font-medium mt-1">{row.tabla}</p>
        </div>
        <div>
          <p className="text-xs font-semibold text-muted-fg uppercase tracking-wider">Id registro</p>
          <p className="text-sm text-slate-900 font-mono mt-1">{row.id_registro ?? '—'}</p>
        </div>
        <div>
          <p className="text-xs font-semibold text-muted-fg uppercase tracking-wider">Fecha</p>
          <p className="text-sm text-slate-700 mt-1 tabular-nums">{fecha}</p>
        </div>
        <div>
          <p className="text-xs font-semibold text-muted-fg uppercase tracking-wider">Usuario DB</p>
          <p className="text-sm text-slate-700 font-mono mt-1">{row.usuario_db}</p>
          <p className="text-xs text-muted-fg mt-1">Rol Postgres efectivo tras SET ROLE del JWT.</p>
        </div>
        <div>
          <p className="text-xs font-semibold text-muted-fg uppercase tracking-wider">Rol sesion</p>
          <p className="text-sm text-slate-700 font-mono mt-1">{row.rol_sesion}</p>
          <p className="text-xs text-muted-fg mt-1">Rol que abrio la conexion fisica (no falsificable salvo re-login).</p>
        </div>
        <div>
          <p className="text-xs font-semibold text-muted-fg uppercase tracking-wider">Usuario app</p>
          <p className="text-sm text-slate-700 font-medium mt-1">
            {usuarioNombre ?? row.usuario_app ?? '—'}
          </p>
          {usuarioNombre && row.usuario_app && (
            <p className="text-xs text-muted-fg font-mono mt-0.5 break-all" title={row.usuario_app}>
              {row.usuario_app}
            </p>
          )}
          <p className="text-xs text-muted-fg mt-1">UUID del JWT.sub (identidad logica en auth.users).</p>
        </div>
      </Card>

      {/* Diff */}
      {row.tipo_op === 'U' ? (
        <Card variant="raised" className="overflow-hidden p-0">
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-slate-200">
              <thead className="bg-slate-50">
                <tr>
                  <th className="px-4 py-3 text-left text-xs font-semibold text-muted-fg uppercase tracking-wider">Columna</th>
                  <th className="px-4 py-3 text-left text-xs font-semibold text-muted-fg uppercase tracking-wider">Valor anterior</th>
                  <th className="px-4 py-3 text-left text-xs font-semibold text-muted-fg uppercase tracking-wider">Valor nuevo</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {claves.map((k) => {
                  const a = stringify(anterior[k])
                  const n = stringify(nuevo[k])
                  const cambio = a !== n
                  return (
                    <tr key={k} className={cambio ? 'bg-warning-bg/50' : ''}>
                      <td className="px-4 py-3 text-sm font-medium text-slate-900 align-top whitespace-nowrap">
                        {k}
                        {cambio && (
                          <Badge variant="warning" className="ml-2">cambió</Badge>
                        )}
                      </td>
                      <td className="px-4 py-3 text-xs text-slate-700 font-mono align-top">
                        <pre className="whitespace-pre-wrap break-all">{a}</pre>
                      </td>
                      <td className="px-4 py-3 text-xs text-slate-700 font-mono align-top">
                        <pre className="whitespace-pre-wrap break-all">{n}</pre>
                      </td>
                    </tr>
                  )
                })}
              </tbody>
            </table>
          </div>
        </Card>
      ) : (
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
          {row.tipo_op === 'D' && (
            <Card variant="raised" className="overflow-hidden p-0">
              <div className="bg-danger-bg border-b border-danger-border px-4 py-2">
                <h2 className="text-sm font-semibold text-danger-fg">Valores anteriores (eliminado)</h2>
              </div>
              <pre className="p-4 text-xs text-slate-700 font-mono whitespace-pre-wrap break-all overflow-x-auto">
                {JSON.stringify(row.valores_anteriores, null, 2)}
              </pre>
            </Card>
          )}

          {row.tipo_op === 'I' && (
            <Card variant="raised" className="overflow-hidden p-0">
              <div className="bg-success-bg border-b border-success-border px-4 py-2">
                <h2 className="text-sm font-semibold text-success-fg">Valores nuevos (insertado)</h2>
              </div>
              <pre className="p-4 text-xs text-slate-700 font-mono whitespace-pre-wrap break-all overflow-x-auto">
                {JSON.stringify(row.valores_nuevos, null, 2)}
              </pre>
            </Card>
          )}
        </div>
      )}
    </div>
  )
}
