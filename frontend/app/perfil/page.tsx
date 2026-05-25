import { redirect } from 'next/navigation'
import { createClient } from '@/lib/supabase/server'
import { PerfilForm } from '@/components/PerfilForm'
import type { Cliente } from '@/types/database'

/**
 * Vista del perfil del cliente autenticado.
 * Carga la fila propia de `cliente` (filtrada por RLS) y delega la
 * edicion al Client Component `PerfilForm`, que invoca el RPC
 * pa_actualizar_cliente.
 */
export default async function PerfilPage() {
  const supabase = await createClient()
  const {
    data: { user },
  } = await supabase.auth.getUser()

  if (!user) {
    redirect('/login?redirect=/perfil')
  }

  const { data: cliente, error } = await supabase
    .from('cliente')
    .select('id_cliente, nombre, apellido, dni, telefono, direccion')
    .eq('auth_user_id', user.id)
    .maybeSingle<
      Pick<Cliente, 'id_cliente' | 'nombre' | 'apellido' | 'dni' | 'telefono' | 'direccion'>
    >()

  if (error || !cliente) {
    return (
      <div className="max-w-2xl mx-auto mt-8">
        <h1 className="font-display text-3xl font-bold text-slate-900 mb-2">
          Mi perfil
        </h1>
        <p className="text-sm text-danger-fg">
          No se encontró un perfil de cliente vinculado a tu cuenta. Cerrá
          sesión y volvé a ingresar.
        </p>
      </div>
    )
  }

  return (
    <div className="max-w-2xl mx-auto mt-8 px-4">
      <h1 className="font-display text-3xl font-bold text-slate-900 mb-1">
        Mi perfil
      </h1>
      <p className="text-sm text-muted-fg mb-8">
        Editá tus datos personales. {user.email}
      </p>

      <PerfilForm initial={cliente} />
    </div>
  )
}
