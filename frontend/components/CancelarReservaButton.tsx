'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { createClient } from '@/lib/supabase/client'

interface Props {
  idReserva: number
}

/**
 * Boton + modal para cancelar una reserva. Sprint 2 (R8).
 * Invoca `pa_cancelar_reserva(p_id_reserva, p_motivo)` via RPC.
 *
 * Contrato del SP:
 *   IN    p_id_reserva BIGINT
 *   INOUT p_motivo     TEXT  (se devuelve enriquecido con timestamp + uuid)
 *   OUT   p_estado     TEXT  ('OK' | 'ERROR_ESTADO' | 'ERROR_REFERENCIAL' | ...)
 *   OUT   p_mensaje    TEXT
 *
 * Solo se muestra cuando la reserva esta en estado 'pendiente' (el
 * server-side decide eso).
 */
export function CancelarReservaButton({ idReserva }: Props) {
  const supabase = createClient()
  const router = useRouter()

  const [open, setOpen] = useState(false)
  const [motivo, setMotivo] = useState('')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  async function handleCancelar() {
    setLoading(true)
    setError(null)

    const { data, error: rpcError } = await supabase.rpc('pa_cancelar_reserva', {
      p_id_reserva: idReserva,
      p_motivo: motivo,
    })

    if (rpcError) {
      setError(rpcError.message)
      setLoading(false)
      return
    }

    const result = data as
      | { p_estado: string; p_mensaje: string; p_motivo: string | null }
      | null

    if (!result || result.p_estado !== 'OK') {
      setError(result?.p_mensaje ?? 'No se pudo cancelar la reserva.')
      setLoading(false)
      return
    }

    setOpen(false)
    setLoading(false)
    router.refresh()
  }

  return (
    <>
      <button
        type="button"
        onClick={() => setOpen(true)}
        className="text-xs font-medium text-red-600 hover:text-red-800 underline-offset-2 hover:underline"
      >
        Cancelar reserva
      </button>

      {open && (
        <div
          className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 px-4"
          onClick={() => !loading && setOpen(false)}
        >
          <div
            className="w-full max-w-md rounded-xl bg-white shadow-xl p-6"
            onClick={(e) => e.stopPropagation()}
          >
            <h2 className="text-lg font-semibold text-gray-900">Cancelar reserva</h2>
            <p className="text-sm text-gray-500 mt-1">
              Esta acción no puede deshacerse. Contanos por qué la cancelas
              (opcional).
            </p>

            <textarea
              value={motivo}
              onChange={(e) => setMotivo(e.target.value)}
              placeholder="Motivo de la cancelación..."
              rows={4}
              maxLength={500}
              className="mt-4 w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-red-500 focus:border-red-500 resize-none"
              disabled={loading}
            />

            {error && (
              <div className="mt-3 rounded-lg bg-red-50 border border-red-200 px-3 py-2">
                <p className="text-red-700 text-xs">{error}</p>
              </div>
            )}

            <div className="mt-5 flex gap-2 justify-end">
              <button
                type="button"
                onClick={() => setOpen(false)}
                disabled={loading}
                className="px-4 py-2 text-sm font-medium text-gray-700 border border-gray-300 rounded-lg hover:bg-gray-50 disabled:opacity-50"
              >
                Volver
              </button>
              <button
                type="button"
                onClick={handleCancelar}
                disabled={loading}
                className="px-4 py-2 text-sm font-medium text-white bg-red-600 rounded-lg hover:bg-red-700 disabled:opacity-50"
              >
                {loading ? 'Cancelando...' : 'Confirmar cancelación'}
              </button>
            </div>
          </div>
        </div>
      )}
    </>
  )
}
