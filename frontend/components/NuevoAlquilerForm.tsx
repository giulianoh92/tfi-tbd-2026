'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { createClient } from '@/lib/supabase/client'
import type { Cliente, Vehiculo, Tarifa, Reserva } from '@/types/database'

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
 * Como el navegador puede tener clock skew vs. server, se documenta el caso
 * y se deja al usuario ajustarlo si lo necesita.
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
  const [idReserva, setIdReserva] = useState<string>(
    reservasPendientes[0]?.id_reserva?.toString() ?? '',
  )

  // --- Rama "walk-in" ---
  const ahoraIso = isoLocal(new Date(Date.now() + 60_000)) // +1 minuto
  const en24hIso = isoLocal(new Date(Date.now() + 86_400_000 + 60_000))
  const [idClienteW, setIdClienteW] = useState<string>(
    clientes[0]?.id_cliente?.toString() ?? '',
  )
  const [idVehiculoW, setIdVehiculoW] = useState<string>(
    vehiculos[0]?.id_vehiculo?.toString() ?? '',
  )
  const [fechaInicioW, setFechaInicioW] = useState<string>(ahoraIso)
  const [fechaFinW, setFechaFinW] = useState<string>(en24hIso)

  // --- Comunes ---
  const [idTarifa, setIdTarifa] = useState<string>(
    tarifas[0]?.id_tarifa?.toString() ?? '',
  )
  const [kmInicio, setKmInicio] = useState<string>('')

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    setError(null)

    const kmInicioNum = parseInt(kmInicio, 10)
    if (isNaN(kmInicioNum) || kmInicioNum < 0) {
      setError('Ingresa un kilometraje inicial valido (>= 0).')
      return
    }

    const idTarifaNum = parseInt(idTarifa, 10)
    if (isNaN(idTarifaNum)) {
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
      const idResNum = parseInt(idReserva, 10)
      if (isNaN(idResNum)) {
        setError('Seleccioná una reserva.')
        return
      }
      const reserva = reservasPendientes.find((r) => r.id_reserva === idResNum)
      if (!reserva) {
        setError('Reserva no encontrada (recargá la pagina).')
        return
      }
      // En la rama "con reserva" las fechas y el cliente/vehiculo los dicta
      // la reserva. El procedure valida que coincidan (defensa en
      // profundidad).
      args = {
        p_id_reserva: idResNum,
        p_id_cliente: reserva.id_cliente,
        p_id_vehiculo: reserva.id_vehiculo,
        p_id_tarifa: idTarifaNum,
        p_fecha_inicio: reserva.fecha_inicio,
        p_fecha_fin: reserva.fecha_fin_prevista,
        p_km_inicio: kmInicioNum,
      }
    } else {
      const idClienteNum = parseInt(idClienteW, 10)
      const idVehiculoNum = parseInt(idVehiculoW, 10)
      if (isNaN(idClienteNum) || isNaN(idVehiculoNum)) {
        setError('Seleccioná cliente y vehiculo.')
        return
      }
      if (new Date(fechaFinW) <= new Date(fechaInicioW)) {
        setError('La fecha de fin debe ser posterior a la de inicio.')
        return
      }
      args = {
        p_id_reserva: null,
        p_id_cliente: idClienteNum,
        p_id_vehiculo: idVehiculoNum,
        p_id_tarifa: idTarifaNum,
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
    <form onSubmit={handleSubmit} className="bg-white rounded-xl border border-gray-200 shadow-sm p-6 flex flex-col gap-5">
      {/* Toggle de modalidad */}
      <div className="flex gap-2 bg-gray-100 rounded-lg p-1">
        <button
          type="button"
          onClick={() => setModo('con_reserva')}
          className={`flex-1 py-2 text-sm font-medium rounded-md transition-colors ${
            modo === 'con_reserva'
              ? 'bg-white text-blue-700 shadow-sm'
              : 'text-gray-600 hover:text-gray-900'
          }`}
        >
          Con reserva previa
        </button>
        <button
          type="button"
          onClick={() => setModo('walk_in')}
          className={`flex-1 py-2 text-sm font-medium rounded-md transition-colors ${
            modo === 'walk_in'
              ? 'bg-white text-blue-700 shadow-sm'
              : 'text-gray-600 hover:text-gray-900'
          }`}
        >
          Sin reserva (walk-in)
        </button>
      </div>

      {/* Rama "con reserva" */}
      {modo === 'con_reserva' && (
        <div className="flex flex-col gap-1.5">
          <label htmlFor="reserva" className="text-sm font-medium text-gray-700">
            Reserva pendiente <span className="text-red-500">*</span>
          </label>
          {reservasPendientes.length === 0 ? (
            <p className="text-sm text-gray-500 italic">
              No hay reservas pendientes. Usá modo walk-in.
            </p>
          ) : (
            <select
              id="reserva"
              required
              value={idReserva}
              onChange={(e) => setIdReserva(e.target.value)}
              className="border border-gray-300 rounded-lg px-3 py-2 text-sm text-gray-900 bg-white focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            >
              {reservasPendientes.map((r) => (
                <option key={r.id_reserva} value={r.id_reserva}>
                  #{r.id_reserva} —{' '}
                  {r.cliente
                    ? `${r.cliente.nombre} ${r.cliente.apellido}`
                    : `Cliente ${r.id_cliente}`}{' '}
                  /{' '}
                  {r.vehiculo
                    ? `${r.vehiculo.marca} ${r.vehiculo.modelo} (${r.vehiculo.patente})`
                    : `Vehiculo ${r.id_vehiculo}`}{' '}
                  — {formatearFecha(r.fecha_inicio)} a{' '}
                  {formatearFecha(r.fecha_fin_prevista)}
                </option>
              ))}
            </select>
          )}
        </div>
      )}

      {/* Rama "walk-in" */}
      {modo === 'walk_in' && (
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
          <div className="flex flex-col gap-1.5 sm:col-span-2">
            <label htmlFor="cliente" className="text-sm font-medium text-gray-700">
              Cliente <span className="text-red-500">*</span>
            </label>
            <select
              id="cliente"
              required
              value={idClienteW}
              onChange={(e) => setIdClienteW(e.target.value)}
              className="border border-gray-300 rounded-lg px-3 py-2 text-sm text-gray-900 bg-white focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            >
              {clientes.map((c) => (
                <option key={c.id_cliente} value={c.id_cliente}>
                  {c.nombre} {c.apellido} — DNI {c.dni}
                </option>
              ))}
            </select>
          </div>

          <div className="flex flex-col gap-1.5 sm:col-span-2">
            <label htmlFor="vehiculo" className="text-sm font-medium text-gray-700">
              Vehiculo disponible <span className="text-red-500">*</span>
            </label>
            <select
              id="vehiculo"
              required
              value={idVehiculoW}
              onChange={(e) => {
                setIdVehiculoW(e.target.value)
                const v = vehiculos.find((x) => x.id_vehiculo === parseInt(e.target.value, 10))
                if (v) setKmInicio(v.km_actuales.toString())
              }}
              className="border border-gray-300 rounded-lg px-3 py-2 text-sm text-gray-900 bg-white focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            >
              {vehiculos.map((v) => (
                <option key={v.id_vehiculo} value={v.id_vehiculo}>
                  {v.marca} {v.modelo} ({v.patente}) — {v.km_actuales.toLocaleString('es-AR')} km
                </option>
              ))}
            </select>
          </div>

          <div className="flex flex-col gap-1.5">
            <label htmlFor="fecha_inicio" className="text-sm font-medium text-gray-700">
              Fecha y hora de inicio <span className="text-red-500">*</span>
            </label>
            <input
              id="fecha_inicio"
              type="datetime-local"
              required
              value={fechaInicioW}
              onChange={(e) => setFechaInicioW(e.target.value)}
              className="border border-gray-300 rounded-lg px-3 py-2 text-sm text-gray-900 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            />
          </div>

          <div className="flex flex-col gap-1.5">
            <label htmlFor="fecha_fin" className="text-sm font-medium text-gray-700">
              Fecha y hora de fin <span className="text-red-500">*</span>
            </label>
            <input
              id="fecha_fin"
              type="datetime-local"
              required
              value={fechaFinW}
              onChange={(e) => setFechaFinW(e.target.value)}
              className="border border-gray-300 rounded-lg px-3 py-2 text-sm text-gray-900 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            />
          </div>
        </div>
      )}

      {/* Tarifa + km — comunes */}
      <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
        <div className="flex flex-col gap-1.5">
          <label htmlFor="tarifa" className="text-sm font-medium text-gray-700">
            Tarifa <span className="text-red-500">*</span>
          </label>
          <select
            id="tarifa"
            required
            value={idTarifa}
            onChange={(e) => setIdTarifa(e.target.value)}
            className="border border-gray-300 rounded-lg px-3 py-2 text-sm text-gray-900 bg-white focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
          >
            {tarifas.map((t) => (
              <option key={t.id_tarifa} value={t.id_tarifa}>
                #{t.id_tarifa} — ${Number(t.precio_por_dia).toLocaleString('es-AR')} /dia
              </option>
            ))}
          </select>
        </div>

        <div className="flex flex-col gap-1.5">
          <label htmlFor="km_inicio" className="text-sm font-medium text-gray-700">
            Km al inicio <span className="text-red-500">*</span>
          </label>
          <input
            id="km_inicio"
            type="number"
            min={0}
            step={1}
            required
            value={kmInicio}
            onChange={(e) => setKmInicio(e.target.value)}
            placeholder="0"
            className="border border-gray-300 rounded-lg px-3 py-2 text-sm text-gray-900 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
          />
        </div>
      </div>

      {error && (
        <div className="rounded-lg bg-red-50 border border-red-200 p-3">
          <p className="text-red-700 text-sm">{error}</p>
        </div>
      )}

      <button
        type="submit"
        disabled={loading}
        className="w-full py-2.5 bg-blue-600 text-white text-sm font-semibold rounded-lg hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
      >
        {loading ? 'Registrando...' : 'Registrar alquiler'}
      </button>
    </form>
  )
}

// Formatea Date a "YYYY-MM-DDTHH:mm" en hora local para datetime-local inputs.
function isoLocal(d: Date): string {
  const pad = (n: number) => String(n).padStart(2, '0')
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}T${pad(d.getHours())}:${pad(d.getMinutes())}`
}

function formatearFecha(iso: string): string {
  return new Date(iso).toLocaleString('es-AR', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  })
}
