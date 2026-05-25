'use client'

import { useMemo, useState } from 'react'
import { useRouter } from 'next/navigation'
import { createClient } from '@/lib/supabase/client'
import { rpcCall } from '@/lib/supabase/rpc'
import type { Sucursal, Taller } from '@/types/database'
import type {
  UbicacionVigente,
  VehiculoDisponible,
} from '@/app/admin/mantenimientos/nuevo/page'
import { Card } from '@/components/ui/Card'
import { Button } from '@/components/ui/Button'
import { Label } from '@/components/ui/Label'
import { Combobox } from '@/components/ui/Combobox'
import { Textarea } from '@/components/ui/Textarea'

interface Props {
  vehiculos: VehiculoDisponible[]
  talleres: Taller[]
  sucursales: Sucursal[]
  ubicacionesVigentes: UbicacionVigente[]
}

/**
 * Form de envio a mantenimiento (CU-07).
 *
 * Invoca pa_enviar_mantenimiento_programado(p_id_vehiculo, p_id_taller, p_observaciones).
 * El procedure exige p_observaciones TEXT; pasamos cadena vacia si el usuario
 * deja el campo vacio (el SP acepta el valor pero lo guarda como NULL no aplica:
 * pasamos string vacio que pega como '').
 *
 * UX:
 *   - En el select de vehiculo mostramos su sucursal actual (segun ubicacion
 *     vigente, fallback a id_sucursal_origen) para ayudar a elegir taller.
 *   - Tras OK redirige a /admin/mantenimientos y refresca.
 */
export function NuevoMantenimientoForm({
  vehiculos,
  talleres,
  sucursales,
  ubicacionesVigentes,
}: Props) {
  const supabase = createClient()
  const router = useRouter()

  const [idVehiculo, setIdVehiculo] = useState<number | null>(null)
  const [idTaller, setIdTaller] = useState<number | null>(talleres[0]?.id_taller ?? null)
  const [observaciones, setObservaciones] = useState('')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  // Mapea id_vehiculo -> nombre de sucursal actual (vigente o origen como fallback).
  const sucursalPorVehiculo = useMemo(() => {
    const sucMap = new Map(sucursales.map((s) => [s.id_sucursal, s.nombre]))
    const vigente = new Map<number, number>()
    for (const u of ubicacionesVigentes) {
      vigente.set(u.id_vehiculo, u.id_sucursal)
    }
    const out = new Map<number, string>()
    for (const v of vehiculos) {
      const idSuc = vigente.get(v.id_vehiculo) ?? v.id_sucursal_origen
      out.set(v.id_vehiculo, sucMap.get(idSuc) ?? `Sucursal ${idSuc}`)
    }
    return out
  }, [vehiculos, sucursales, ubicacionesVigentes])

  const vehiculoItems = useMemo(
    () =>
      vehiculos.map((v) => ({
        value: v.id_vehiculo,
        label: `${v.marca} ${v.modelo} (${v.patente})`,
        hint: `${sucursalPorVehiculo.get(v.id_vehiculo) ?? '—'} · ${v.km_actuales.toLocaleString('es-AR')} km`,
      })),
    [vehiculos, sucursalPorVehiculo],
  )

  const tallerItems = useMemo(
    () =>
      talleres.map((t) => ({
        value: t.id_taller,
        label: t.nombre,
        hint: t.direccion,
      })),
    [talleres],
  )

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    setError(null)

    if (idVehiculo == null) {
      setError('Seleccioná el vehículo a enviar.')
      return
    }
    if (idTaller == null) {
      setError('Seleccioná el taller de destino.')
      return
    }

    setLoading(true)
    const { data, error: rpcError } = await rpcCall(
      supabase,
      'pa_enviar_mantenimiento_programado',
      {
        p_id_vehiculo: idVehiculo,
        p_id_taller: idTaller,
        p_observaciones: observaciones.trim(),
      },
    )

    if (rpcError) {
      setError(rpcError.message)
      setLoading(false)
      return
    }

    const result = data as
      | { p_estado: string; p_mensaje: string }
      | null

    if (!result || result.p_estado !== 'OK') {
      setError(result?.p_mensaje ?? 'No se pudo registrar el envío.')
      setLoading(false)
      return
    }

    router.push('/admin/mantenimientos')
    router.refresh()
  }

  const submitDisabled = loading || idVehiculo == null || idTaller == null

  return (
    <Card variant="raised" className="p-6">
      <form onSubmit={handleSubmit} className="flex flex-col gap-5" noValidate>
        <div>
          <Label htmlFor="vehiculo" required>
            Vehículo
          </Label>
          {vehiculos.length === 0 ? (
            <p className="text-sm text-muted-fg italic">
              No hay vehículos disponibles para enviar a mantenimiento.
            </p>
          ) : (
            <Combobox
              id="vehiculo"
              items={vehiculoItems}
              value={idVehiculo}
              onChange={setIdVehiculo}
              placeholder="Seleccioná un vehículo..."
              searchPlaceholder="Buscar por marca, modelo o patente..."
            />
          )}
          <p className="mt-1 text-xs text-muted-fg">
            Solo se listan vehículos en estado <strong>disponible</strong>. La
            etiqueta indica dónde está ubicado hoy el vehículo.
          </p>
        </div>

        <div>
          <Label htmlFor="taller" required>
            Taller
          </Label>
          {talleres.length === 0 ? (
            <p className="text-sm text-muted-fg italic">
              No hay talleres cargados. Pedile al admin que cree alguno.
            </p>
          ) : (
            <Combobox
              id="taller"
              items={tallerItems}
              value={idTaller}
              onChange={setIdTaller}
              placeholder="Seleccioná un taller..."
              searchPlaceholder="Buscar por nombre o dirección..."
            />
          )}
        </div>

        <div>
          <Label htmlFor="observaciones">Observaciones</Label>
          <Textarea
            id="observaciones"
            value={observaciones}
            onChange={(e) => setObservaciones(e.target.value)}
            placeholder="Motivo del envío, síntomas, kilometraje aproximado de cambio de aceite, etc."
            rows={4}
            maxLength={1000}
          />
          <p className="mt-1 text-xs text-muted-fg">
            Opcional. Útil para que el taller sepa qué revisar.
          </p>
        </div>

        {error && (
          <div
            role="alert"
            className="rounded-lg bg-danger-bg border border-danger-border p-3"
          >
            <p className="text-danger-fg text-sm">{error}</p>
          </div>
        )}

        <Button
          type="submit"
          variant="primary"
          loading={loading}
          disabled={submitDisabled}
          className="w-full"
        >
          {loading ? 'Registrando...' : 'Confirmar envío a taller'}
        </Button>

        <p className="text-xs text-muted-fg text-center">
          El vehículo quedará en estado <strong>en mantenimiento</strong> hasta
          que se registre la devolución.
        </p>
      </form>
    </Card>
  )
}
