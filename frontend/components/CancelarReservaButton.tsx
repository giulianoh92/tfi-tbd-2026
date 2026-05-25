'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { createClient } from '@/lib/supabase/client'
import { rpcCall } from '@/lib/supabase/rpc'
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from '@/components/ui/Dialog'
import { Button } from '@/components/ui/Button'
import { Textarea } from '@/components/ui/Textarea'

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

    const { data, error: rpcError } = await rpcCall(supabase, 'pa_cancelar_reserva', {
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
    <Dialog open={open} onOpenChange={(o) => !loading && setOpen(o)}>
      <DialogTrigger asChild>
        <button
          type="button"
          className="text-xs font-medium text-danger-fg hover:text-red-800 underline-offset-2 hover:underline focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand-500 rounded"
        >
          Cancelar reserva
        </button>
      </DialogTrigger>

      <DialogContent
        onPointerDownOutside={(e) => loading && e.preventDefault()}
        onEscapeKeyDown={(e) => loading && e.preventDefault()}
      >
        <DialogHeader>
          <DialogTitle>Cancelar reserva</DialogTitle>
          <DialogDescription>
            Esta acción no puede deshacerse. Contanos por qué la cancelás (opcional).
          </DialogDescription>
        </DialogHeader>

        <Textarea
          value={motivo}
          onChange={(e) => setMotivo(e.target.value)}
          placeholder="Motivo de la cancelación..."
          rows={4}
          maxLength={500}
          disabled={loading}
          aria-label="Motivo de la cancelación"
        />

        {error && (
          <div
            role="alert"
            className="rounded-lg bg-danger-bg border border-danger-border px-3 py-2"
          >
            <p className="text-danger-fg text-xs">{error}</p>
          </div>
        )}

        <DialogFooter>
          <Button
            type="button"
            variant="secondary"
            onClick={() => setOpen(false)}
            disabled={loading}
          >
            Volver
          </Button>
          <Button
            type="button"
            variant="destructive"
            onClick={handleCancelar}
            loading={loading}
          >
            {loading ? 'Cancelando...' : 'Confirmar cancelación'}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}
