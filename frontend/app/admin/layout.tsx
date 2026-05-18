import { createClient } from '@/lib/supabase/server'
import { redirect } from 'next/navigation'

/**
 * Layout protegido para el panel staff.
 * Verifica que el JWT tenga app_metadata.role === 'staff'.
 * Si no → redirect a la landing. Si sí → renderiza con banner de modo staff.
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

  // Primero verificamos que haya sesión
  if (!user) {
    redirect('/login')
  }

  // Luego verificamos que el claim de staff esté en app_metadata (no user_metadata)
  const isStaff = user.app_metadata?.role === 'staff'
  if (!isStaff) {
    redirect('/')
  }

  return (
    <div>
      {/* Banner de modo staff */}
      <div className="mb-6 flex items-center gap-3 rounded-lg border border-amber-200 bg-amber-50 px-4 py-3">
        <span className="inline-flex items-center rounded-full bg-amber-100 px-2.5 py-0.5 text-xs font-semibold text-amber-800 border border-amber-300">
          STAFF
        </span>
        <span className="text-sm text-amber-700 font-medium">
          Modo staff activo — {user.email}
        </span>
      </div>

      {children}
    </div>
  )
}
