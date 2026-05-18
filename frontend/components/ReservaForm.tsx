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
 * Implementa el flujo §6.1 del documento de arquitectura:
 * INSERT en `reserva` via PostgREST con JWT en header (lo maneja supabase-js).
 * El trigger `trg_reserva_no_overlap` devuelve 409 si hay solapamiento.
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

    // Validación básica de fechas (el constraint chk_reserva_fechas también lo valida en DB)
    if (new Date(fechaFin) <= new Date(fechaInicio)) {
      setError('La fecha de fin debe ser posterior a la fecha de inicio.')
      setLoading(false)
      return
    }

    // NOTA sobre id_cliente:
    // La RLS policy `reserva_owner_crud` (schema/06_permissions) valida que
    // id_cliente pertenezca al usuario autenticado. Si la policy usa una función
    // helper `fn_cliente_del_usuario()` o similar, el INSERT puede omitir id_cliente
    // y la DB lo resuelve. Si la policy requiere el id explícito, necesitás hacer
    // un SELECT previo: supabase.from('cliente').select('id_cliente').eq('id_usuario', user.id).single()
    // y pasar ese valor acá.
    //
    // Para el PoC asumimos que id_cliente tiene un DEFAULT basado en el JWT o que
    // la policy lo maneja. Ajustar según la implementación final de la policy.
    const { error: insertError } = await supabase.from('reserva').insert({
      id_vehiculo: idVehiculo,
      id_tipo_reserva: idTipoReserva,
      // Las timestamps deben incluir hora; usamos inicio/fin del día
      fecha_inicio: `${fechaInicio}T00:00:00`,
      fecha_fin_prevista: `${fechaFin}T23:59:59`,
      // id_cliente: resolverlo con SELECT si la policy lo requiere explícito
    } as { id_vehiculo: number; id_tipo_reserva: number; fecha_inicio: string; fecha_fin_prevista: string })

    if (insertError) {
      if (insertError.code === '23P01' || insertError.message?.includes('overlap')) {
        // trg_reserva_no_overlap devuelve exclusion constraint violation
        setToast('El vehículo ya está reservado en esas fechas. Probá con otras fechas.')
      } else if (insertError.message?.includes('409') || insertError.code === 'PGRST') {
        setToast('Conflicto de fechas. El vehículo ya está reservado en ese periodo.')
      } else {
        setError(insertError.message)
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
