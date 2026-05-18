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

  return (
    <nav className="bg-white border-b border-gray-200 sticky top-0 z-10">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex items-center justify-between h-14">
          {/* Logo / nombre */}
          <Link
            href="/"
            className="font-bold text-gray-900 text-lg hover:text-blue-600 transition-colors"
          >
            AutoRenta
          </Link>

          {/* Links centrales */}
          <div className="hidden sm:flex items-center gap-6">
            <Link
              href="/"
              className="text-sm text-gray-600 hover:text-gray-900 transition-colors"
            >
              Vehículos
            </Link>
            <Link
              href="/mis-reservas"
              className="text-sm text-gray-600 hover:text-gray-900 transition-colors"
            >
              Mis reservas
            </Link>
            {/* Link de admin solo visible para usuarios staff */}
            {isStaff && (
              <Link
                href="/admin"
                className="text-sm font-semibold text-amber-700 hover:text-amber-900 transition-colors"
              >
                Admin
              </Link>
            )}
          </div>

          {/* Auth */}
          <AuthButton />
        </div>
      </div>
    </nav>
  )
}
