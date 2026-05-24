'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { createClient } from '@/lib/supabase/client'
import type { TipoReserva } from '@/types/database'

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

  const today = new Date().toISOString().split('T')[0]
  const tomorrow = new Date(Date.now() + 86400000).toISOString().split('T')[0]

  const [fechaInicio, setFechaInicio] = useState(today)
  const [fechaFin, setFechaFin] = useState(tomorrow)
  const [idTipoReserva, setIdTipoReserva] = useState<number>(
    tiposReserva[0]?.id_tipo_reserva ?? 1
  )
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [toast, setToast] = useState<string | null>(null)

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    setLoading(true)
    setError(null)
    setToast(null)

    // Validación de UX (la DB la repite con fn_validar_periodo).
    if (new Date(fechaFin) <= new Date(fechaInicio)) {
      setError('La fecha de fin debe ser posterior a la fecha de inicio.')
      setLoading(false)
      return
    }

    // Resolver id_cliente del usuario autenticado. El procedure exige
    // id_cliente explicito (parametro IN). La policy cliente_self_read
    // restringe el SELECT a la propia fila del usuario.
    const { data: clienteRow, error: clienteError } = await supabase
      .from('cliente')
      .select('id_cliente')
      .maybeSingle()

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
    const { data, error: rpcError } = await supabase.rpc('pa_registrar_reserva', {
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
    <div className="bg-white rounded-xl border border-gray-200 shadow-sm p-6">
      {toast && (
        <div className="mb-4 rounded-lg bg-yellow-50 border border-yellow-200 px-4 py-3">
          <p className="text-yellow-800 text-sm font-medium">{toast}</p>
        </div>
      )}

      <form onSubmit={handleSubmit} className="space-y-5">
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
          <div>
            <label htmlFor="fecha_inicio" className="block text-sm font-medium text-gray-700 mb-1">
              Fecha de inicio
            </label>
            <input
              id="fecha_inicio"
              type="date"
              required
              min={today}
              value={fechaInicio}
              onChange={(e) => setFechaInicio(e.target.value)}
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500 text-sm"
            />
          </div>

          <div>
            <label htmlFor="fecha_fin" className="block text-sm font-medium text-gray-700 mb-1">
              Fecha de fin prevista
            </label>
            <input
              id="fecha_fin"
              type="date"
              required
              min={fechaInicio}
              value={fechaFin}
              onChange={(e) => setFechaFin(e.target.value)}
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500 text-sm"
            />
          </div>
        </div>

        <div>
          <label htmlFor="tipo_reserva" className="block text-sm font-medium text-gray-700 mb-1">
            Tipo de reserva
          </label>
          <select
            id="tipo_reserva"
            required
            value={idTipoReserva}
            onChange={(e) => setIdTipoReserva(Number(e.target.value))}
            className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500 text-sm bg-white"
          >
            {tiposReserva.map((t) => (
              <option key={t.id_tipo_reserva} value={t.id_tipo_reserva}>
                {capitalizar(t.nombre)}
                {t.requiere_garantia ? ' (requiere garantía)' : ''}
                {t.descripcion ? ` — ${t.descripcion}` : ''}
              </option>
            ))}
          </select>
        </div>

        {error && (
          <div className="rounded-lg bg-red-50 border border-red-200 px-4 py-3">
            <p className="text-red-700 text-sm">{error}</p>
          </div>
        )}

        <div className="flex gap-3 pt-2">
          <button
            type="button"
            onClick={() => router.back()}
            className="flex-1 py-2 px-4 border border-gray-300 text-gray-700 rounded-lg text-sm font-medium hover:bg-gray-50 transition-colors"
          >
            Cancelar
          </button>
          <button
            type="submit"
            disabled={loading}
            className="flex-1 py-2 px-4 bg-blue-600 text-white rounded-lg text-sm font-medium hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
          >
            {loading ? 'Reservando...' : 'Confirmar reserva'}
          </button>
        </div>
      </form>

      <p className="text-gray-400 text-xs mt-4">
        Vehículo: <span className="font-medium text-gray-600">{vehiculoNombre}</span>
      </p>
    </div>
  )
}

function capitalizar(s: string): string {
  return s.charAt(0).toUpperCase() + s.slice(1)
}
