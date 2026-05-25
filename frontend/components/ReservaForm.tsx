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
  const [garantiaTipo, setGarantiaTipo] = useState<string>('Visa')
  const [garantiaTitular, setGarantiaTitular] = useState('')
  const [garantiaNumero, setGarantiaNumero] = useState('')
  const [garantiaVencimiento, setGarantiaVencimiento] = useState('')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [fieldErrors, setFieldErrors] = useState<{
    fechaInicio?: string
    fechaFin?: string
    garantiaTitular?: string
    garantiaNumero?: string
    garantiaVencimiento?: string
  }>({})
  const [toast, setToast] = useState<string | null>(null)

  const tipoSeleccionado = tiposReserva.find((t) => t.id_tipo_reserva === idTipoReserva)
  const requiereGarantia = tipoSeleccionado?.requiere_garantia ?? false

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

    // Validación de garantía (sólo si el tipo de reserva la exige).
    if (requiereGarantia) {
      const errs: typeof fieldErrors = {}
      if (!garantiaTitular.trim()) {
        errs.garantiaTitular = 'Campo obligatorio para reservas con garantía.'
      }
      const numeroLimpio = garantiaNumero.replace(/\s+/g, '')
      if (!/^\d{13,19}$/.test(numeroLimpio)) {
        errs.garantiaNumero = 'Ingresá entre 13 y 19 dígitos.'
      }
      if (!garantiaVencimiento) {
        errs.garantiaVencimiento = 'Campo obligatorio.'
      } else {
        // input type="month" devuelve YYYY-MM; convertimos al último día del mes.
        const [y, m] = garantiaVencimiento.split('-').map(Number)
        const ultimoDiaMes = new Date(y, m, 0)
        const hoy = new Date()
        hoy.setHours(0, 0, 0, 0)
        if (ultimoDiaMes < hoy) {
          errs.garantiaVencimiento = 'La tarjeta está vencida.'
        }
      }
      if (Object.keys(errs).length > 0) {
        setFieldErrors(errs)
        setLoading(false)
        return
      }
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

    // Si el tipo exige garantía, convertimos el vencimiento YYYY-MM
    // (input type="month") al último día del mes en formato YYYY-MM-DD.
    let garantiaVencimientoDate: string | undefined
    if (requiereGarantia && garantiaVencimiento) {
      const [y, m] = garantiaVencimiento.split('-').map(Number)
      const ultimoDia = new Date(y, m, 0)
      garantiaVencimientoDate = ultimoDia.toISOString().slice(0, 10)
    }

    // RPC al procedure de reserva. PostgREST serializa los OUT como
    // objeto JSON con las claves p_estado, p_mensaje, p_id_generado.
    // Los params de garantia se omiten cuando el tipo de reserva no la
    // exige; el procedure los toma como DEFAULT NULL en el server.
    const { data, error: rpcError } = await rpcCall(supabase, 'pa_registrar_reserva', {
      p_id_cliente: clienteRow.id_cliente,
      p_id_vehiculo: idVehiculo,
      p_id_tipo_reserva: idTipoReserva,
      p_fecha_inicio: `${fechaInicio}T00:00:00`,
      p_fecha_fin: `${fechaFin}T23:59:59`,
      p_garantia_tipo: requiereGarantia ? garantiaTipo : undefined,
      p_garantia_titular: requiereGarantia ? garantiaTitular.trim() : undefined,
      p_garantia_numero_tarjeta: requiereGarantia
        ? garantiaNumero.replace(/\s+/g, '')
        : undefined,
      p_garantia_vencimiento: garantiaVencimientoDate,
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

        {requiereGarantia && (
          <fieldset className="rounded-lg border border-slate-200 p-4 space-y-4">
            <legend className="px-2 text-sm font-medium text-slate-700">
              Garantía con tarjeta de crédito
            </legend>
            <p className="text-xs text-muted-fg">
              Este tipo de reserva exige una tarjeta como garantía. No se cobra ningún
              monto al reservar; sólo se valida la tarjeta. El número se almacena
              hasheado, nunca en texto plano.
            </p>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div>
                <Label htmlFor="garantia_tipo" required>
                  Tipo de tarjeta
                </Label>
                <Select
                  id="garantia_tipo"
                  required
                  value={garantiaTipo}
                  onChange={(e) => setGarantiaTipo(e.target.value)}
                >
                  <option value="Visa">Visa</option>
                  <option value="Mastercard">Mastercard</option>
                  <option value="American Express">American Express</option>
                  <option value="Otra">Otra</option>
                </Select>
              </div>

              <div>
                <Label htmlFor="garantia_titular" required>
                  Titular
                </Label>
                <Input
                  id="garantia_titular"
                  type="text"
                  required
                  autoComplete="cc-name"
                  placeholder="Como figura en la tarjeta"
                  value={garantiaTitular}
                  onChange={(e) => setGarantiaTitular(e.target.value)}
                  aria-invalid={fieldErrors.garantiaTitular ? true : undefined}
                />
                {fieldErrors.garantiaTitular && (
                  <p className="mt-1 text-xs text-danger-fg">{fieldErrors.garantiaTitular}</p>
                )}
              </div>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div>
                <Label htmlFor="garantia_numero" required>
                  Número de tarjeta
                </Label>
                <Input
                  id="garantia_numero"
                  type="text"
                  inputMode="numeric"
                  required
                  autoComplete="cc-number"
                  placeholder="1234 5678 9012 3456"
                  value={garantiaNumero}
                  onChange={(e) => setGarantiaNumero(e.target.value)}
                  aria-invalid={fieldErrors.garantiaNumero ? true : undefined}
                />
                {fieldErrors.garantiaNumero && (
                  <p className="mt-1 text-xs text-danger-fg">{fieldErrors.garantiaNumero}</p>
                )}
              </div>

              <div>
                <Label htmlFor="garantia_vencimiento" required>
                  Vencimiento
                </Label>
                <Input
                  id="garantia_vencimiento"
                  type="month"
                  required
                  autoComplete="cc-exp"
                  value={garantiaVencimiento}
                  onChange={(e) => setGarantiaVencimiento(e.target.value)}
                  aria-invalid={fieldErrors.garantiaVencimiento ? true : undefined}
                />
                {fieldErrors.garantiaVencimiento && (
                  <p className="mt-1 text-xs text-danger-fg">{fieldErrors.garantiaVencimiento}</p>
                )}
              </div>
            </div>
          </fieldset>
        )}

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
