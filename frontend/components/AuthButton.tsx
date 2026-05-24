'use client'

import { useEffect, useState } from 'react'
import { useRouter } from 'next/navigation'
import Link from 'next/link'
import { LogOut } from 'lucide-react'
import { createClient } from '@/lib/supabase/client'
import type { User } from '@supabase/supabase-js'

/**
 * Botón de autenticación.
 * Escucha onAuthStateChange para mantenerse sincronizado con la sesión.
 */
export function AuthButton() {
  const supabase = createClient()
  const router = useRouter()
  const [user, setUser] = useState<User | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    supabase.auth.getUser().then(({ data }) => {
      setUser(data.user)
      setLoading(false)
    })

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
    return <div className="h-5 w-24 bg-slate-200 rounded animate-pulse" />
  }

  if (!user) {
    return (
      <Link
        href="/login"
        className="text-sm font-medium text-brand-700 hover:underline transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand-500 rounded"
      >
        Ingresar
      </Link>
    )
  }

  return (
    <div className="flex items-center gap-3">
      <span className="text-sm text-slate-600 hidden sm:block max-w-[14ch] truncate">
        {user.email}
      </span>
      <button
        type="button"
        onClick={handleSignOut}
        className="inline-flex items-center gap-1 text-sm font-medium text-slate-500 hover:text-danger-fg transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand-500 rounded"
      >
        <LogOut className="w-4 h-4" aria-hidden="true" />
        Salir
      </button>
    </div>
  )
}
