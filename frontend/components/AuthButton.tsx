'use client'

import { useEffect, useState } from 'react'
import { useRouter } from 'next/navigation'
import Link from 'next/link'
import { createClient } from '@/lib/supabase/client'
import type { User } from '@supabase/supabase-js'

/**
 * Botón de autenticación.
 * Escucha onAuthStateChange para mantenerse sincronizado con la sesión.
 * Muestra el email del usuario si está autenticado, o un link a /login.
 */
export function AuthButton() {
  const supabase = createClient()
  const router = useRouter()
  const [user, setUser] = useState<User | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    // Obtiene sesión inicial
    supabase.auth.getUser().then(({ data }) => {
      setUser(data.user)
      setLoading(false)
    })

    // Escucha cambios de sesión (login, logout, refresh)
    const {
      data: { subscription },
    } = supabase.auth.onAuthStateChange((_event, session) => {
      setUser(session?.user ?? null)
    })

    return () => subscription.unsubscribe()
  }, [supabase.auth])

  async function handleSignOut() {
    await supabase.auth.signOut()
    router.push('/')
    router.refresh()
  }

  if (loading) {
    return <div className="h-5 w-24 bg-gray-200 rounded animate-pulse" />
  }

  if (!user) {
    return (
      <Link
        href="/login"
        className="text-sm font-medium text-blue-600 hover:text-blue-800 transition-colors"
      >
        Ingresar
      </Link>
    )
  }

  return (
    <div className="flex items-center gap-3">
      <span className="text-sm text-gray-600 hidden sm:block">{user.email}</span>
      <button
        onClick={handleSignOut}
        className="text-sm font-medium text-gray-500 hover:text-red-600 transition-colors"
      >
        Salir
      </button>
    </div>
  )
}
