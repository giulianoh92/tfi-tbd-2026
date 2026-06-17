'use client'

import Link from 'next/link'
import { usePathname } from 'next/navigation'
import {
  LayoutDashboard,
  Car,
  CarFront,
  Receipt,
  BarChart3,
  History,
  Wrench,
  AlarmClock,
  type LucideIcon,
} from 'lucide-react'
import { cn } from '@/lib/cn'

interface NavItem {
  href: string
  label: string
  icon: LucideIcon
  /** Si true, solo activo si el pathname == href. Si false, activa con prefijo. */
  exact?: boolean
}

const NAV: NavItem[] = [
  { href: '/admin',                       label: 'Dashboard',             icon: LayoutDashboard, exact: true },
  { href: '/admin/alquileres',            label: 'Alquileres',            icon: Car },
  { href: '/admin/facturas',              label: 'Facturas',              icon: Receipt },
  { href: '/admin/reportes-mensuales',    label: 'Reportes mensuales',    icon: BarChart3 },
  { href: '/admin/auditoria',             label: 'Auditoria',             icon: History },
  { href: '/admin/vehiculos',             label: 'Flota',                 icon: CarFront },
  { href: '/admin/mantenimientos',        label: 'Mantenimientos',        icon: Wrench },
  { href: '/admin/devoluciones-vencidas', label: 'Devoluciones vencidas', icon: AlarmClock },
]

/**
 * Sidebar persistente del panel staff.
 * Resalta item activo segun pathname (exact o prefijo).
 */
export function AdminSidebar() {
  const pathname = usePathname()

  return (
    <aside
      aria-label="Navegacion panel staff"
      className="lg:w-56 lg:shrink-0 lg:sticky lg:top-[5.5rem] lg:h-[calc(100vh-7rem)]"
    >
      <nav className="flex lg:flex-col gap-1 overflow-x-auto lg:overflow-visible">
        {NAV.map((item) => {
          const active = item.exact
            ? pathname === item.href
            : pathname === item.href || pathname.startsWith(`${item.href}/`)
          const Icon = item.icon
          return (
            <Link
              key={item.href}
              href={item.href}
              aria-current={active ? 'page' : undefined}
              className={cn(
                'inline-flex items-center gap-2 rounded-lg px-3 py-2 text-sm font-medium whitespace-nowrap',
                'transition-colors',
                'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand-500',
                active
                  ? 'bg-brand-50 text-brand-700'
                  : 'text-slate-700 hover:bg-slate-100 hover:text-slate-900'
              )}
            >
              <Icon className="w-4 h-4 shrink-0" aria-hidden="true" />
              <span>{item.label}</span>
            </Link>
          )
        })}
      </nav>
    </aside>
  )
}
