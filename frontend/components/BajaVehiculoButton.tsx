'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { createClient } from '@/lib/supabase/client'
import { rpcCall } from '@/lib/supabase/rpc'
import { Trash2 } from 'lucide-react'
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
  idVehiculo: number
  patente: string
}

/**
 * Boton + modal para dar de baja un vehiculo.
 * Sprint 3 (R3): invoca `pa_baja_vehiculo(p_id_vehiculo, p_motivo)`.
 * Solo se renderiza para vehiculos cuyo estado != 'baja'.
 */
export function BajaVehiculoButton({ idVehiculo, patente }: Props) {
  const supabase = createClient()
  const router = useRouter()

  const [open, setOpen] = useState(false)
  const [motivo, setMotivo] = useState('')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  async function handleBaja() {
    setLoading(true)
    setError(null)

    const { data, error: rpcError } = await rpcCall(supabase, 'pa_baja_vehiculo', {
      p_id_vehiculo: idVehiculo,
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
      setError(result?.p_mensaje ?? 'No se pudo dar de baja el vehiculo.')
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
        <Button type="button" variant="ghost" size="sm" className="text-danger-fg hover:text-red-800 hover:bg-danger-bg">
          <Trash2 className="w-4 h-4" aria-hidden="true" />
          Dar de baja
        </Button>
      </DialogTrigger>

      <DialogContent
        onPointerDownOutside={(e) => loading && e.preventDefault()}
        onEscapeKeyDown={(e) => loading && e.preventDefault()}
      >
        <DialogHeader>
          <DialogTitle>Dar de baja vehiculo {patente}</DialogTitle>
          <DialogDescription>
            Esta accion transiciona el vehiculo al estado &quot;baja&quot;. No se puede
            ejecutar si hay alquileres activos o reservas pendientes.
          </DialogDescription>
        </DialogHeader>

        <Textarea
          value={motivo}
          onChange={(e) => setMotivo(e.target.value)}
          placeholder="Motivo de la baja..."
          rows={4}
          maxLength={180}
          disabled={loading}
          aria-label="Motivo de la baja"
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
            onClick={handleBaja}
            loading={loading}
          >
            {loading ? 'Procesando...' : 'Confirmar baja'}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}
