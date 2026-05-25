'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { createClient } from '@/lib/supabase/client'
import { rpcCall } from '@/lib/supabase/rpc'
import type { TipoReserva } from '@/types/database'
import { isoLocal } from '@/lib/format'
import { Button } from '@/components/ui/Button'
import { Input } from '@/components/ui/Input'
import { Select } from '@/components/ui/Select'
import { Label } from '@/components/ui/Label'
import { Card } from '@/components/ui/Card'

interface ReservaFormProps {
  idVehiculo: number
  vehiculoNombre: string
  tiposReserva: TipoReserva[]
}

/**
 * Formulario para crear una reserva.
 * Sprint 2 (R7): invoca `pa_registrar_reserva` vía RPC. El procedure
 * devuelve `{ p_estado, p_mensaje, p_id_generado }`. Se mapea por estado:
 * 'OK' redirige a /mis-reservas; cualquier otro código se muestra al
 * usuario con el mensaje legible que viene del SP.
 */
export function ReservaForm({ idVehiculo, vehiculoNombre, tiposReserva }: ReservaFormProps) {
  const supabase = createClient()
  const router = useRouter()

  // Fechas en zona LOCAL del cliente para que el min del input no se corra
  // un dia por offset UTC (bug clasico Argentina UTC-3 despues de las 21:00).
  const today = isoLocal(new Date())
  const tomorrow = isoLocal(new Date(Date.now() + 86_400_000))

  const [fechaInicio, setFechaInicio] = useState(today)
  const [fechaFin, setFechaFin] = useState(tomorrow)
  const [idTipoReserva, setIdTipoReserva] = useState<number>(
    tiposReserva[0]?.id_tipo_reserva ?? 1
  )
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [fieldErrors, setFieldErrors] = useState<{ fechaInicio?: string; fechaFin?: string }>({})
  const [toast, setToast] = useState<string | null>(null)

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    setLoading(true)
    setError(null)
    setFieldErrors({})
    setToast(null)

    // Validación de UX (la DB la repite con fn_validar_periodo).
    if (new Date(fechaFin) <= new Date(fechaInicio)) {
      setFieldErrors({ fechaFin: 'Debe ser posterior a la fecha de inicio.' })
      setLoading(false)
      return
    }

    // Resolver id_cliente del usuario autenticado. El procedure exige
    // id_cliente explicito (parametro IN). La policy cliente_self_read
    // restringe el SELECT a la propia fila del usuario.
    const { data: clienteRow, error: clienteError } = await supabase
      .from('cliente')
      .select('id_cliente')
      .maybeSingle<{ id_cliente: number }>()

    if (clienteError || !clienteRow) {
      setError(
        clienteError?.message ??
          'No se encontro tu perfil de cliente. Cerra sesion y volve a entrar.',
      )
      setLoading(false)
      return
    }

    // RPC al procedure de Sprint 2. PostgREST serializa los OUT como
    // objeto JSON con las claves p_estado, p_mensaje, p_id_generado.
    const { data, error: rpcError } = await rpcCall(supabase, 'pa_registrar_reserva', {
      p_id_cliente: clienteRow.id_cliente,
      p_id_vehiculo: idVehiculo,
      p_id_tipo_reserva: idTipoReserva,
      p_fecha_inicio: `${fechaInicio}T00:00:00`,
      p_fecha_fin: `${fechaFin}T23:59:59`,
    })

    if (rpcError) {
      // Error de transporte / RLS: el SP ni siquiera se ejecuto. No deberia
      // pasar porque authenticated tiene EXECUTE, pero defensa en profundidad.
      setError(rpcError.message)
      setLoading(false)
      return
    }

    const result = data as
      | { p_estado: string; p_mensaje: string; p_id_generado: number | null }
      | null

    if (!result || result.p_estado !== 'OK') {
      const mensaje = result?.p_mensaje ?? 'No se pudo registrar la reserva.'
      // ERROR_VALIDACION + mensaje de superposicion -> toast amigable;
      // resto -> error principal.
      if (
        result?.p_estado === 'ERROR_VALIDACION' &&
        /superpone|overlap/i.test(mensaje)
      ) {
        setToast('El vehículo ya está reservado en esas fechas. Probá con otras fechas.')
      } else {
        setError(mensaje)
      }
      setLoading(false)
      return
    }

    router.push('/mis-reservas')
    router.refresh()
  }

  return (
    <Card variant="raised" className="p-6">
      {toast && (
        <div
          role="status"
          className="mb-4 rounded-lg bg-warning-bg border border-warning-border px-4 py-3"
        >
          <p className="text-warning-fg text-sm font-medium">{toast}</p>
        </div>
      )}

      <form onSubmit={handleSubmit} className="space-y-5" noValidate>
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
          <div>
            <Label htmlFor="fecha_inicio" required>
              Fecha de inicio
            </Label>
            <Input
              id="fecha_inicio"
              type="date"
              required
              min={today}
              value={fechaInicio}
              onChange={(e) => setFechaInicio(e.target.value)}
              aria-invalid={fieldErrors.fechaInicio ? true : undefined}
              aria-describedby={fieldErrors.fechaInicio ? 'fecha_inicio-error' : undefined}
            />
            {fieldErrors.fechaInicio && (
              <p id="fecha_inicio-error" className="mt-1 text-xs text-danger-fg">
                {fieldErrors.fechaInicio}
              </p>
            )}
          </div>

          <div>
            <Label htmlFor="fecha_fin" required>
              Fecha de fin prevista
            </Label>
            <Input
              id="fecha_fin"
              type="date"
              required
              min={fechaInicio}
              value={fechaFin}
              onChange={(e) => setFechaFin(e.target.value)}
              aria-invalid={fieldErrors.fechaFin ? true : undefined}
              aria-describedby={fieldErrors.fechaFin ? 'fecha_fin-error' : undefined}
            />
            {fieldErrors.fechaFin && (
              <p id="fecha_fin-error" className="mt-1 text-xs text-danger-fg">
                {fieldErrors.fechaFin}
              </p>
            )}
          </div>
        </div>

        <div>
          <Label htmlFor="tipo_reserva" required>
            Tipo de reserva
          </Label>
          <Select
            id="tipo_reserva"
            required
            value={idTipoReserva}
            onChange={(e) => setIdTipoReserva(Number(e.target.value))}
          >
            {tiposReserva.map((t) => (
              <option key={t.id_tipo_reserva} value={t.id_tipo_reserva}>
                {capitalizar(t.nombre)}
                {t.requiere_garantia ? ' (requiere garantía)' : ''}
                {t.descripcion ? ` — ${t.descripcion}` : ''}
              </option>
            ))}
          </Select>
        </div>

        {error && (
          <div
            role="alert"
            className="rounded-lg bg-danger-bg border border-danger-border px-4 py-3"
          >
            <p className="text-danger-fg text-sm">{error}</p>
          </div>
        )}

        <div className="flex gap-3 pt-2">
          <Button
            type="button"
            variant="secondary"
            className="flex-1"
            onClick={() => router.back()}
          >
            Cancelar
          </Button>
          <Button
            type="submit"
            variant="primary"
            className="flex-1"
            loading={loading}
          >
            {loading ? 'Reservando...' : 'Confirmar reserva'}
          </Button>
        </div>
      </form>

      <p className="text-muted-fg text-xs mt-4">
        Vehículo: <span className="font-medium text-slate-700">{vehiculoNombre}</span>
      </p>
    </Card>
  )
}

function capitalizar(s: string): string {
  return s.charAt(0).toUpperCase() + s.slice(1)
}
