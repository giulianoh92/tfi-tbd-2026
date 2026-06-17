'use client'

import Link from 'next/link'
import { usePathname } from 'next/navigation'
import { ChevronRight, Home } from 'lucide-react'

/**
 * Breadcrumbs dinamicos basados en pathname.
 * Mapea segmentos a labels legibles (titlecase + casos especiales).
 */
const LABELS: Record<string, string> = {
  admin: 'Panel',
  alquileres: 'Alquileres',
  facturas: 'Facturas',
  auditoria: 'Auditoria',
  vehiculos: 'Flota',
  'devoluciones-vencidas': 'Devoluciones vencidas',
  'reportes-mensuales': 'Reportes mensuales',
  nuevo: 'Nuevo',
  cerrar: 'Cerrar',
}

function labelFor(segment: string): string {
  if (LABELS[segment]) return LABELS[segment]
  // Si parece un id numerico, devolverlo como "#<n>"
  if (/^\d+$/.test(segment)) return `#${segment}`
  return segment
}

export function Breadcrumbs() {
  const pathname = usePathname()
  const parts = pathname.split('/').filter(Boolean)

  // Si no estamos bajo /admin, no renderizamos.
  if (parts[0] !== 'admin') return null

  // Construimos paths acumulados: ['/admin', '/admin/alquileres', ...]
  const crumbs = parts.map((seg, i) => ({
    href: '/' + parts.slice(0, i + 1).join('/'),
    label: labelFor(seg),
    isLast: i === parts.length - 1,
  }))

  return (
    <nav aria-label="Breadcrumbs" className="mb-4">
      <ol className="flex items-center gap-1 text-sm text-muted-fg flex-wrap">
        <li>
          <Link
            href="/admin"
            className="inline-flex items-center gap-1 hover:text-slate-900 transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand-500 rounded"
            aria-label="Panel"
          >
            <Home className="w-3.5 h-3.5" aria-hidden="true" />
          </Link>
        </li>
        {crumbs.slice(1).map((c) => (
          <li key={c.href} className="inline-flex items-center gap-1">
            <ChevronRight className="w-3.5 h-3.5 text-slate-300" aria-hidden="true" />
            {c.isLast ? (
              <span aria-current="page" className="text-slate-900 font-medium">
                {c.label}
              </span>
            ) : (
              <Link
                href={c.href}
                className="hover:text-slate-900 transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand-500 rounded"
              >
                {c.label}
              </Link>
            )}
          </li>
        ))}
      </ol>
    </nav>
  )
}
