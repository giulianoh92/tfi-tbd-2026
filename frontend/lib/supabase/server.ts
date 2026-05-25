import { createServerClient, type CookieOptions } from '@supabase/ssr'
import { cookies } from 'next/headers'
import type { Database } from '@/types/database'

// Tipo de cookie que setAll recibe en @supabase/ssr@0.5
type CookieToSet = { name: string; value: string; options: CookieOptions }

/**
 * Cliente Supabase para uso en Server Components y Route Handlers de Next.js 14.
 * Lee/escribe cookies HttpOnly para que el JWT no quede expuesto al JS del browser.
 *
 * IMPORTANTE: esta función debe llamarse dentro de un Server Component o Route Handler,
 * nunca a nivel de módulo (cookies() es una API dinámica de Next.js).
 */
export async function createClient() {
  const cookieStore = await cookies()

  return createServerClient<Database>(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return cookieStore.getAll()
        },
        setAll(cookiesToSet: CookieToSet[]) {
          try {
            cookiesToSet.forEach(({ name, value, options }) =>
              cookieStore.set(name, value, options)
            )
          } catch {
            // En Server Components el set falla silenciosamente.
            // El middleware se encarga del refresh real.
          }
        },
      },
    }
  )
}
