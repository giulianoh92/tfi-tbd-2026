import Link from 'next/link'
import { AuthButton } from '@/components/AuthButton'

/**
 * Header de navegación global.
 * Nav es un Server Component; AuthButton es Client Component
 * (necesita escuchar onAuthStateChange).
 */
export function Nav() {
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
          </div>

          {/* Auth */}
          <AuthButton />
        </div>
      </div>
    </nav>
  )
}
