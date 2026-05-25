'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { createClient } from '@/lib/supabase/client'
import { rpcCall, type FnArgs } from '@/lib/supabase/rpc'
import { Card } from '@/components/ui/Card'
import { Button } from '@/components/ui/Button'
import { Input } from '@/components/ui/Input'
import { Label } from '@/components/ui/Label'

interface Props {
  idVehiculo: number
  kmActuales: number
}

/**
 * Form de devolucion de mantenimiento (CU-08).
 *
 * Invoca pa_registrar_devolucion_mantenimiento(p_id_vehiculo, p_km_salida_taller).
 *
 * El parametro p_km_salida_taller es opcional en el SP. Si el staff no reporta
 * km dejamos el campo vacio y mandamos NULL explicito al RPC (Supabase mapea
 * undefined a "param omitido" en algunas firmas; null asegura que la columna
 * quede sin actualizar y el SP entienda "no reportar km").
 *
 * Si se reporta, el SP valida km_salida_taller >= km_actuales del vehiculo.
 * El check de >= (no >) tolera que el vehiculo vuelva con los mismos km.
 */
export function DevolucionMantenimientoForm({ idVehiculo, kmActuales }: Props) {
  const supabase = createClient()
  const router = useRouter()

  const [kmSalida, setKmSalida] = useState<string>('')
  const [loading, setLoading] = useState(false)
  const [errorMsg, setErrorMsg] = useState<string | null>(null)
  const [fieldErrors, setFieldErrors] = useState<{ km?: string }>({})

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    setErrorMsg(null)
    setFieldErrors({})

    const trimmed = kmSalida.trim()
    let kmSalidaNum: number | null = null
    if (trimmed !== '') {
      const parsed = parseInt(trimmed, 10)
      if (isNaN(parsed) || parsed < 0) {
        setFieldErrors({ km: 'Ingresá un kilometraje válido o dejá vacío.' })
        return
      }
      if (parsed < kmActuales) {
        setFieldErrors({
          km: `Debe ser ≥ ${kmActuales.toLocaleString('es-AR')} km (km actuales del vehículo).`,
        })
        return
      }
      kmSalidaNum = parsed
    }

    setLoading(true)
    // Pasamos null explicito si no se reporta km — undefined puede causar que
    // postgrest omita el param y caiga al default 'NULL' de todos modos, pero
    // null es mas seguro y explicito. Cast a FnArgs porque el types regenerado
    // marca p_km_salida_taller como required, pero el SP acepta NULL.
    const { data, error: rpcError } = await rpcCall(
      supabase,
      'pa_registrar_devolucion_mantenimiento',
      {
        p_id_vehiculo: idVehiculo,
        p_km_salida_taller: kmSalidaNum,
      } as FnArgs<'pa_registrar_devolucion_mantenimiento'>,
    )

    if (rpcError) {
      let msg = rpcError.message
      if (msg.includes('row-level security')) {
        msg = 'No tenés permisos para registrar la devolución (RLS). Verificá que tu usuario tenga rol staff.'
      }
      setErrorMsg(msg)
      setLoading(false)
      return
    }

    const result = data as { p_estado: string; p_mensaje: string } | null

    if (!result || result.p_estado !== 'OK') {
      setErrorMsg(result?.p_mensaje ?? 'No se pudo registrar la devolución.')
      setLoading(false)
      return
    }

    router.push('/admin/mantenimientos')
    router.refresh()
  }

  return (
    <Card variant="raised" className="p-6">
      <form onSubmit={handleSubmit} className="flex flex-col gap-5" noValidate>
        <h2 className="font-display text-lg font-semibold text-slate-900">
          Datos de la devolución
        </h2>

        <div>
          <Label htmlFor="km_salida">Kilómetros al salir del taller</Label>
          <Input
            id="km_salida"
            type="number"
            min={kmActuales}
            step={1}
            value={kmSalida}
            onChange={(e) => setKmSalida(e.target.value)}
            placeholder={`Dejar vacío si no se reportaron km`}
            aria-invalid={fieldErrors.km ? true : undefined}
            aria-describedby={fieldErrors.km ? 'km_salida-error' : 'km_salida-help'}
          />
          {fieldErrors.km ? (
            <p id="km_salida-error" className="mt-1 text-xs text-danger-fg">
              {fieldErrors.km}
            </p>
          ) : (
            <p id="km_salida-help" className="mt-1 text-xs text-muted-fg">
              Km registrados al envío: {kmActuales.toLocaleString('es-AR')} km. Si
              el taller no reportó nuevos km, dejalo vacío.
            </p>
          )}
        </div>

        {errorMsg && (
          <div
            role="alert"
            className="rounded-lg bg-danger-bg border border-danger-border p-3"
          >
            <p className="text-danger-fg text-sm font-medium">
              Error al registrar la devolución
            </p>
            <p className="text-danger-fg/80 text-xs mt-1">{errorMsg}</p>
          </div>
        )}

        <Button
          type="submit"
          variant="primary"
          loading={loading}
          className="w-full bg-orange-600 hover:bg-orange-700"
        >
          {loading ? 'Procesando...' : 'Confirmar devolución'}
        </Button>

        <p className="text-xs text-muted-fg text-center">
          El vehículo vuelve a estado <strong>disponible</strong> y queda listo
          para nuevos alquileres.
        </p>
      </form>
    </Card>
  )
}
