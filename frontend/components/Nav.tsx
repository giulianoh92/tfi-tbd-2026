import Link from 'next/link'
import { AuthButton } from '@/components/AuthButton'
import { createClient } from '@/lib/supabase/server'

/**
 * Header de navegación global.
 * Nav es async Server Component para poder leer el user y mostrar el link
 * de admin solo si tiene app_metadata.role === 'staff'.
 * AuthButton es Client Component (necesita escuchar onAuthStateChange).
 */
export async function Nav() {
  const supabase = await createClient()
  const {
    data: { user },
  } = await supabase.auth.getUser()

  const isStaff = user?.app_metadata?.role === 'staff'

  let displayName: string | undefined
  if (user) {
    const { data: clienteRow } = await supabase
      .from('cliente')
      .select('nombre, apellido')
      .eq('auth_user_id', user.id)
      .maybeSingle<{ nombre: string; apellido: string }>()
    const nombre = [clienteRow?.nombre, clienteRow?.apellido].filter(Boolean).join(' ')
    displayName = nombre || undefined
  }

  return (
    <nav className="bg-white/95 backdrop-blur supports-[backdrop-filter]:bg-white/80 border-b border-slate-200 sticky top-0 z-30">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex items-center justify-between h-14">
          {/* Logo / nombre */}
          <Link
            href="/"
            className="font-display font-bold text-slate-900 text-lg hover:text-brand-700 transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand-500 rounded"
          >
            AutoRenta
          </Link>

          {/* Links centrales */}
          <div className="hidden sm:flex items-center gap-6">
            <Link
              href="/"
              className="text-sm text-slate-600 hover:text-slate-900 transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand-500 rounded"
            >
              Vehículos
            </Link>
            <Link
              href="/mis-reservas"
              className="text-sm text-slate-600 hover:text-slate-900 transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand-500 rounded"
            >
              Mis reservas
            </Link>
            {isStaff && (
              <Link
                href="/admin"
                className="text-sm font-semibold text-brand-staff-fg hover:underline transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand-500 rounded"
              >
                Admin
              </Link>
            )}
          </div>

          <AuthButton displayName={displayName} />
        </div>
      </div>
    </nav>
  )
}
