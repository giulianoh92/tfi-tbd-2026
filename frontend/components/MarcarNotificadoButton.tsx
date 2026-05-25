'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { createClient } from '@/lib/supabase/client'

interface Props {
  idDevolucionVencida: number
  notificado: boolean
}

/**
 * Toggle del flag `notificado` sobre una fila de `devolucion_vencida`.
 * Sprint 4 (R9).
 *
 * El UPDATE pasa por RLS (`devolucion_vencida_staff_update`) y solo se
 * permite si el JWT tiene `app_metadata.role = 'staff'`. La columna
 * `notificado` es la unica updateable en `Database['public']['Tables']
 * ['devolucion_vencida']['Update']`.
 */
export function MarcarNotificadoButton({ idDevolucionVencida, notificado }: Props) {
  const supabase = createClient()
  const router = useRouter()

  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  async function toggle() {
    setLoading(true)
    setError(null)

    // Cast `as never` evita bug de inferencia en postgrest-js@2.106 donde el
    // generic Row default a never colapsa el args a `never`. Equivalente al
    // workaround del helper rpcCall.
    const { error: updError } = await supabase
      .from('devolucion_vencida')
      .update({ notificado: !notificado } as never)
      .eq('id_devolucion_vencida', idDevolucionVencida)

    if (updError) {
      setError(updError.message)
      setLoading(false)
      return
    }

    setLoading(false)
    router.refresh()
  }

  if (notificado) {
    return (
      <button
        type="button"
        onClick={toggle}
        disabled={loading}
        title="Click para volver a marcar como pendiente"
        className="text-xs font-medium text-gray-500 hover:text-gray-700 underline-offset-2 hover:underline disabled:opacity-50"
      >
        {loading ? '...' : 'Deshacer'}
      </button>
    )
  }

  return (
    <div className="flex flex-col items-end gap-1">
      <button
        type="button"
        onClick={toggle}
        disabled={loading}
        className="text-xs font-medium text-blue-600 hover:text-blue-800 underline-offset-2 hover:underline disabled:opacity-50"
      >
        {loading ? 'Marcando...' : 'Marcar notificado'}
      </button>
      {error && <p className="text-xs text-red-600">{error}</p>}
    </div>
  )
}
