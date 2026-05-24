import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'
import { ShieldCheck } from 'lucide-react'
import { AdminSidebar } from '@/components/admin/AdminSidebar'
import { Breadcrumbs } from '@/components/admin/Breadcrumbs'
import { Badge } from '@/components/ui/Badge'

/**
 * Layout protegido para el panel staff.
 * Verifica que el JWT tenga app_metadata.role === 'staff'.
 * Si no, redirect a la landing. Si si, renderiza con banner + sidebar.
 *
 * Color del banner: brand-staff (indigo), no amber, para no colisionar con
 * los estados "pendiente" / "vencido" del dominio.
 */
export default async function AdminLayout({
  children,
}: {
  children: React.ReactNode
}) {
  const supabase = await createClient()

  const {
    data: { user },
  } = await supabase.auth.getUser()

  if (!user) {
    redirect('/login')
  }

  const isStaff = user.app_metadata?.role === 'staff'
  if (!isStaff) {
    redirect('/')
  }

  return (
    <div>
      {/* Banner de modo staff */}
      <div className="mb-6 flex items-center gap-3 rounded-lg border border-brand-staff-border bg-brand-staff-bg px-4 py-3">
        <ShieldCheck className="w-4 h-4 text-brand-staff-fg shrink-0" aria-hidden="true" />
        <Badge variant="staff">STAFF</Badge>
        <span className="text-sm text-brand-staff-fg font-medium truncate">
          Modo staff activo — {user.email}
        </span>
      </div>

      <div className="flex flex-col lg:flex-row gap-6">
        <AdminSidebar />
        <div className="flex-1 min-w-0">
          <Breadcrumbs />
          {children}
        </div>
      </div>
    </div>
  )
}
