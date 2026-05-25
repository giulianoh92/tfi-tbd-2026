import { createServerClient, type CookieOptions } from '@supabase/ssr'
import { NextResponse, type NextRequest } from 'next/server'
import type { Database } from '@/types/database'

// Tipo de cookie que setAll recibe en @supabase/ssr@0.5
type CookieToSet = { name: string; value: string; options: CookieOptions }

/**
 * Refresca la sesión de Supabase en cada request del middleware.
 * Necesario para que los Server Components lean una sesión fresca.
 * Retorna la respuesta con las cookies actualizadas.
 */
export async function updateSession(request: NextRequest) {
  let supabaseResponse = NextResponse.next({ request })

  const supabase = createServerClient<Database>(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return request.cookies.getAll()
        },
        setAll(cookiesToSet: CookieToSet[]) {
          cookiesToSet.forEach(({ name, value }) =>
            request.cookies.set(name, value)
          )
          supabaseResponse = NextResponse.next({ request })
          cookiesToSet.forEach(({ name, value, options }) =>
            supabaseResponse.cookies.set(name, value, options)
          )
        },
      },
    }
  )

  // Refresca la sesión — no usar getUser() en Server Components directamente.
  const {
    data: { user },
  } = await supabase.auth.getUser()

  // Rutas que requieren autenticación.
  // NOTA: /admin solo chequea sesión acá; la verificación de rol staff
  // la hace app/admin/layout.tsx (doble barrera).
  const protectedPaths = ['/mis-reservas', '/reservar', '/admin']
  const isProtected = protectedPaths.some((path) =>
    request.nextUrl.pathname.startsWith(path)
  )

  if (isProtected && !user) {
    const loginUrl = request.nextUrl.clone()
    loginUrl.pathname = '/login'
    loginUrl.searchParams.set('redirect', request.nextUrl.pathname)
    return NextResponse.redirect(loginUrl)
  }

  return supabaseResponse
}
