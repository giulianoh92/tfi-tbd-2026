'use client'

import { useMemo, useState } from 'react'
import { useRouter } from 'next/navigation'
import { createClient } from '@/lib/supabase/client'
import type { Cliente, Vehiculo, Tarifa, Reserva } from '@/types/database'
import { Card } from '@/components/ui/Card'
import { Button } from '@/components/ui/Button'
import { Input } from '@/components/ui/Input'
import { Label } from '@/components/ui/Label'
import { Combobox } from '@/components/ui/Combobox'
import { formatARS, formatDateTimeAR } from '@/lib/format'
import { cn } from '@/lib/cn'

interface ReservaPendiente
  extends Pick<Reserva, 'id_reserva' | 'id_cliente' | 'id_vehiculo' | 'fecha_inicio' | 'fecha_fin_prevista'> {
  cliente: Pick<Cliente, 'nombre' | 'apellido' | 'dni'> | null
  vehiculo: Pick<Vehiculo, 'marca' | 'modelo' | 'patente' | 'km_actuales'> | null
}

interface VehiculoLite extends Pick<Vehiculo, 'id_vehiculo' | 'marca' | 'modelo' | 'patente' | 'km_actuales'> {}

interface Props {
  reservasPendientes: ReservaPendiente[]
  clientes: Pick<Cliente, 'id_cliente' | 'nombre' | 'apellido' | 'dni'>[]
  vehiculos: VehiculoLite[]
  tarifas: Tarifa[]
}

type Modo = 'con_reserva' | 'walk_in'

/**
 * Formulario de alta de alquiler.
 * Sprint 3 (R3, R6): invoca `pa_registrar_alquiler` via RPC, soportando
 * ambas modalidades (con reserva previa / walk-in) con un solo toggle.
 *
 * Para walk-in se setea fecha_inicio con 1 minuto de gracia sobre el "ahora"
 * del navegador, porque fn_validar_periodo exige p_fecha_inicio > NOW().
 */
export function NuevoAlquilerForm({
  reservasPendientes,
  clientes,
  vehiculos,
  tarifas,
}: Props) {
  const supabase = createClient()
  const router = useRouter()

  const [modo, setModo] = useState<Modo>('con_reserva')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  // --- Rama "con reserva" ---
  const [idReserva, setIdReserva] = useState<number | null>(
    reservasPendientes[0]?.id_reserva ?? null
  )

  // --- Rama "walk-in" ---
  const ahoraIso = isoLocalDt(new Date(Date.now() + 60_000)) // +1 minuto
  const en24hIso = isoLocalDt(new Date(Date.now() + 86_400_000 + 60_000))
  const [idClienteW, setIdClienteW] = useState<number | null>(
    clientes[0]?.id_cliente ?? null
  )
  const [idVehiculoW, setIdVehiculoW] = useState<number | null>(
    vehiculos[0]?.id_vehiculo ?? null
  )
  const [fechaInicioW, setFechaInicioW] = useState<string>(ahoraIso)
  const [fechaFinW, setFechaFinW] = useState<string>(en24hIso)

  // --- Comunes ---
  const [idTarifa, setIdTarifa] = useState<number | null>(
    tarifas[0]?.id_tarifa ?? null
  )
  const [kmInicio, setKmInicio] = useState<string>('')

  // Items para Combobox
  const reservaItems = useMemo(
    () =>
      reservasPendientes.map((r) => ({
        value: r.id_reserva,
        label: `#${r.id_reserva} — ${
          r.cliente ? `${r.cliente.nombre} ${r.cliente.apellido}` : `Cliente ${r.id_cliente}`
        }`,
        hint: `${
          r.vehiculo
            ? `${r.vehiculo.marca} ${r.vehiculo.modelo} (${r.vehiculo.patente})`
            : `Vehiculo ${r.id_vehiculo}`
        } — ${formatDateTimeAR(r.fecha_inicio)} a ${formatDateTimeAR(r.fecha_fin_prevista)}`,
      })),
    [reservasPendientes]
  )

  const clienteItems = useMemo(
    () =>
      clientes.map((c) => ({
        value: c.id_cliente,
        label: `${c.nombre} ${c.apellido}`,
        hint: `DNI ${c.dni}`,
      })),
    [clientes]
  )

  const vehiculoItems = useMemo(
    () =>
      vehiculos.map((v) => ({
        value: v.id_vehiculo,
        label: `${v.marca} ${v.modelo} (${v.patente})`,
        hint: `${v.km_actuales.toLocaleString('es-AR')} km`,
      })),
    [vehiculos]
  )

  const tarifaItems = useMemo(
    () =>
      tarifas.map((t) => ({
        value: t.id_tarifa,
        label: `#${t.id_tarifa} — ${formatARS(Number(t.precio_por_dia))} / día`,
      })),
    [tarifas]
  )

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    setError(null)

    const kmInicioNum = parseInt(kmInicio, 10)
    if (isNaN(kmInicioNum) || kmInicioNum < 0) {
      setError('Ingresa un kilometraje inicial valido (mayor o igual a 0).')
      return
    }

    if (idTarifa == null) {
      setError('Seleccioná una tarifa.')
      return
    }

    let args: {
      p_id_reserva: number | null
      p_id_cliente: number
      p_id_vehiculo: number
      p_id_tarifa: number
      p_fecha_inicio: string
      p_fecha_fin: string
      p_km_inicio: number
    }

    if (modo === 'con_reserva') {
      if (idReserva == null) {
        setError('Seleccioná una reserva.')
        return
      }
      const reserva = reservasPendientes.find((r) => r.id_reserva === idReserva)
      if (!reserva) {
        setError('Reserva no encontrada (recargá la página).')
        return
      }
      args = {
        p_id_reserva: idReserva,
        p_id_cliente: reserva.id_cliente,
        p_id_vehiculo: reserva.id_vehiculo,
        p_id_tarifa: idTarifa,
        p_fecha_inicio: reserva.fecha_inicio,
        p_fecha_fin: reserva.fecha_fin_prevista,
        p_km_inicio: kmInicioNum,
      }
    } else {
      if (idClienteW == null || idVehiculoW == null) {
        setError('Seleccioná cliente y vehículo.')
        return
      }
      if (new Date(fechaFinW) <= new Date(fechaInicioW)) {
        setError('La fecha de fin debe ser posterior a la de inicio.')
        return
      }
      args = {
        p_id_reserva: null,
        p_id_cliente: idClienteW,
        p_id_vehiculo: idVehiculoW,
        p_id_tarifa: idTarifa,
        p_fecha_inicio: fechaInicioW,
        p_fecha_fin: fechaFinW,
        p_km_inicio: kmInicioNum,
      }
    }

    setLoading(true)
    const { data, error: rpcError } = await supabase.rpc(
      'pa_registrar_alquiler',
      args,
    )

    if (rpcError) {
      setError(rpcError.message)
      setLoading(false)
      return
    }

    const result = data as
      | { p_estado: string; p_mensaje: string; p_id_generado: number | null }
      | null

    if (!result || result.p_estado !== 'OK') {
      setError(result?.p_mensaje ?? 'No se pudo registrar el alquiler.')
      setLoading(false)
      return
    }

    router.push('/admin/alquileres')
    router.refresh()
  }

  return (
    <Card variant="raised" className="p-6">
      <form onSubmit={handleSubmit} className="flex flex-col gap-5" noValidate>
        {/* Toggle de modalidad */}
        <div role="tablist" aria-label="Modalidad de alquiler" className="flex gap-1 bg-slate-100 rounded-lg p-1">
          <ModeButton active={modo === 'con_reserva'} onClick={() => setModo('con_reserva')}>
            Con reserva previa
          </ModeButton>
          <ModeButton active={modo === 'walk_in'} onClick={() => setModo('walk_in')}>
            Sin reserva (walk-in)
          </ModeButton>
        </div>

        {/* Rama "con reserva" */}
        {modo === 'con_reserva' && (
          <div>
            <Label htmlFor="reserva" required>Reserva pendiente</Label>
            {reservasPendientes.length === 0 ? (
              <p className="text-sm text-muted-fg italic">
                No hay reservas pendientes. Usá modo walk-in.
              </p>
            ) : (
              <Combobox
                id="reserva"
                items={reservaItems}
                value={idReserva}
                onChange={setIdReserva}
                placeholder="Seleccioná una reserva..."
                searchPlaceholder="Buscar por nombre, vehiculo o id..."
              />
            )}
          </div>
        )}

        {/* Rama "walk-in" */}
        {modo === 'walk_in' && (
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div className="sm:col-span-2">
              <Label htmlFor="cliente" required>Cliente</Label>
              <Combobox
                id="cliente"
                items={clienteItems}
                value={idClienteW}
                onChange={setIdClienteW}
                placeholder="Seleccioná un cliente..."
                searchPlaceholder="Buscar por nombre o DNI..."
              />
            </div>

            <div className="sm:col-span-2">
              <Label htmlFor="vehiculo" required>Vehículo disponible</Label>
              <Combobox
                id="vehiculo"
                items={vehiculoItems}
                value={idVehiculoW}
                onChange={(val) => {
                  setIdVehiculoW(val)
                  const v = vehiculos.find((x) => x.id_vehiculo === val)
                  if (v) setKmInicio(v.km_actuales.toString())
                }}
                placeholder="Seleccioná un vehículo..."
                searchPlaceholder="Buscar por marca, modelo o patente..."
              />
            </div>

            <div>
              <Label htmlFor="fecha_inicio" required>Fecha y hora de inicio</Label>
              <Input
                id="fecha_inicio"
                type="datetime-local"
                required
                value={fechaInicioW}
                onChange={(e) => setFechaInicioW(e.target.value)}
              />
            </div>

            <div>
              <Label htmlFor="fecha_fin" required>Fecha y hora de fin</Label>
              <Input
                id="fecha_fin"
                type="datetime-local"
                required
                value={fechaFinW}
                onChange={(e) => setFechaFinW(e.target.value)}
              />
            </div>
          </div>
        )}

        {/* Tarifa + km — comunes */}
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
          <div>
            <Label htmlFor="tarifa" required>Tarifa</Label>
            <Combobox
              id="tarifa"
              items={tarifaItems}
              value={idTarifa}
              onChange={setIdTarifa}
              placeholder="Seleccioná una tarifa..."
              searchPlaceholder="Buscar tarifa..."
            />
          </div>

          <div>
            <Label htmlFor="km_inicio" required>Km al inicio</Label>
            <Input
              id="km_inicio"
              type="number"
              min={0}
              step={1}
              required
              value={kmInicio}
              onChange={(e) => setKmInicio(e.target.value)}
              placeholder="0"
            />
          </div>
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
          className="w-full"
        >
          {loading ? 'Registrando...' : 'Registrar alquiler'}
        </Button>
      </form>
    </Card>
  )
}

function ModeButton({
  active,
  onClick,
  children,
}: {
  active: boolean
  onClick: () => void
  children: React.ReactNode
}) {
  return (
    <button
      type="button"
      role="tab"
      aria-selected={active}
      onClick={onClick}
      className={cn(
        'flex-1 py-2 text-sm font-medium rounded-md transition-colors',
        'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand-500',
        active
          ? 'bg-white text-brand-700 shadow-sm'
          : 'text-slate-600 hover:text-slate-900'
      )}
    >
      {children}
    </button>
  )
}

// Formatea Date a "YYYY-MM-DDTHH:mm" en hora local para datetime-local inputs.
function isoLocalDt(d: Date): string {
  const pad = (n: number) => String(n).padStart(2, '0')
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}T${pad(d.getHours())}:${pad(d.getMinutes())}`
}
