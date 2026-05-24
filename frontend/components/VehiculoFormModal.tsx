'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { createClient } from '@/lib/supabase/client'
import type { Sucursal, TipoVehiculo, Vehiculo } from '@/types/database'

type Modo = 'crear' | 'editar'

interface Props {
  modo: Modo
  vehiculo?: Vehiculo // requerido en modo 'editar'
  sucursales: Sucursal[]
  tiposVehiculo: TipoVehiculo[]
  open: boolean
  onClose: () => void
}

/**
 * Modal con form para crear o editar un vehiculo.
 * Sprint 3 (R3): invoca `pa_crear_vehiculo` o `pa_actualizar_vehiculo` segun
 * modo. Patente, sucursal_origen, tipo y km solo se setean al crear (luego
 * se gobiernan por triggers / no son editables desde aqui).
 */
export function VehiculoFormModal({
  modo,
  vehiculo,
  sucursales,
  tiposVehiculo,
  open,
  onClose,
}: Props) {
  const supabase = createClient()
  const router = useRouter()

  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const [marca, setMarca] = useState(vehiculo?.marca ?? '')
  const [modelo, setModelo] = useState(vehiculo?.modelo ?? '')
  const [anio, setAnio] = useState<string>(
    vehiculo?.anio?.toString() ?? new Date().getFullYear().toString(),
  )
  const [detalleConfort, setDetalleConfort] = useState(vehiculo?.detalle_confort ?? '')

  // Solo en modo crear:
  const [idSucursal, setIdSucursal] = useState<string>(
    vehiculo?.id_sucursal_origen?.toString() ??
      sucursales[0]?.id_sucursal?.toString() ??
      '',
  )
  const [idTipo, setIdTipo] = useState<string>(
    vehiculo?.id_tipo?.toString() ?? tiposVehiculo[0]?.id_tipo?.toString() ?? '',
  )
  const [patente, setPatente] = useState(vehiculo?.patente ?? '')
  const [kmActuales, setKmActuales] = useState<string>(
    vehiculo?.km_actuales?.toString() ?? '0',
  )

  if (!open) return null

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    setError(null)

    const anioNum = parseInt(anio, 10)
    if (isNaN(anioNum)) {
      setError('Año invalido.')
      return
    }

    setLoading(true)

    if (modo === 'crear') {
      const idSucNum = parseInt(idSucursal, 10)
      const idTipoNum = parseInt(idTipo, 10)
      const kmNum = parseInt(kmActuales, 10)
      if (isNaN(idSucNum) || isNaN(idTipoNum) || isNaN(kmNum)) {
        setError('Sucursal, tipo y km deben ser numericos.')
        setLoading(false)
        return
      }

      const { data, error: rpcError } = await supabase.rpc('pa_crear_vehiculo', {
        p_id_sucursal_origen: idSucNum,
        p_id_tipo: idTipoNum,
        p_marca: marca,
        p_modelo: modelo,
        p_anio: anioNum,
        p_patente: patente,
        p_km_actuales: kmNum,
        p_detalle_confort: detalleConfort || null,
      })

      if (rpcError) {
        setError(rpcError.message)
        setLoading(false)
        return
      }

      const result = data as
        | { p_estado: string; p_mensaje: string; p_id_generado: number | null }
        | null

      if (!result || result.p_estado !== 'OK') {
        setError(result?.p_mensaje ?? 'No se pudo crear el vehiculo.')
        setLoading(false)
        return
      }
    } else {
      if (!vehiculo) {
        setError('Falta el vehiculo a editar.')
        setLoading(false)
        return
      }
      const { data, error: rpcError } = await supabase.rpc(
        'pa_actualizar_vehiculo',
        {
          p_id_vehiculo: vehiculo.id_vehiculo,
          p_marca: marca,
          p_modelo: modelo,
          p_anio: anioNum,
          p_detalle_confort: detalleConfort || null,
        },
      )

      if (rpcError) {
        setError(rpcError.message)
        setLoading(false)
        return
      }

      const result = data as { p_estado: string; p_mensaje: string } | null

      if (!result || result.p_estado !== 'OK') {
        setError(result?.p_mensaje ?? 'No se pudo actualizar el vehiculo.')
        setLoading(false)
        return
      }
    }

    setLoading(false)
    onClose()
    router.refresh()
  }

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 px-4"
      onClick={() => !loading && onClose()}
    >
      <div
        className="w-full max-w-lg rounded-xl bg-white shadow-xl p-6"
        onClick={(e) => e.stopPropagation()}
      >
        <h2 className="text-lg font-semibold text-gray-900">
          {modo === 'crear' ? 'Nuevo vehiculo' : `Editar vehiculo #${vehiculo?.id_vehiculo}`}
        </h2>

        <form onSubmit={handleSubmit} className="mt-4 flex flex-col gap-4">
          {modo === 'crear' && (
            <>
              <div className="grid grid-cols-2 gap-3">
                <div className="flex flex-col gap-1">
                  <label className="text-xs font-medium text-gray-600">Sucursal origen</label>
                  <select
                    required
                    value={idSucursal}
                    onChange={(e) => setIdSucursal(e.target.value)}
                    className="border border-gray-300 rounded-md px-2 py-1.5 text-sm bg-white"
                  >
                    {sucursales.map((s) => (
                      <option key={s.id_sucursal} value={s.id_sucursal}>
                        {s.nombre}
                      </option>
                    ))}
                  </select>
                </div>
                <div className="flex flex-col gap-1">
                  <label className="text-xs font-medium text-gray-600">Tipo</label>
                  <select
                    required
                    value={idTipo}
                    onChange={(e) => setIdTipo(e.target.value)}
                    className="border border-gray-300 rounded-md px-2 py-1.5 text-sm bg-white"
                  >
                    {tiposVehiculo.map((t) => (
                      <option key={t.id_tipo} value={t.id_tipo}>
                        {t.nombre}
                      </option>
                    ))}
                  </select>
                </div>
              </div>
              <div className="grid grid-cols-2 gap-3">
                <div className="flex flex-col gap-1">
                  <label className="text-xs font-medium text-gray-600">Patente</label>
                  <input
                    type="text"
                    required
                    maxLength={15}
                    value={patente}
                    onChange={(e) => setPatente(e.target.value.toUpperCase())}
                    className="border border-gray-300 rounded-md px-2 py-1.5 text-sm uppercase"
                  />
                </div>
                <div className="flex flex-col gap-1">
                  <label className="text-xs font-medium text-gray-600">Km actuales</label>
                  <input
                    type="number"
                    min={0}
                    step={1}
                    required
                    value={kmActuales}
                    onChange={(e) => setKmActuales(e.target.value)}
                    className="border border-gray-300 rounded-md px-2 py-1.5 text-sm"
                  />
                </div>
              </div>
            </>
          )}

          <div className="grid grid-cols-2 gap-3">
            <div className="flex flex-col gap-1">
              <label className="text-xs font-medium text-gray-600">Marca</label>
              <input
                type="text"
                required
                maxLength={50}
                value={marca}
                onChange={(e) => setMarca(e.target.value)}
                className="border border-gray-300 rounded-md px-2 py-1.5 text-sm"
              />
            </div>
            <div className="flex flex-col gap-1">
              <label className="text-xs font-medium text-gray-600">Modelo</label>
              <input
                type="text"
                required
                maxLength={50}
                value={modelo}
                onChange={(e) => setModelo(e.target.value)}
                className="border border-gray-300 rounded-md px-2 py-1.5 text-sm"
              />
            </div>
          </div>

          <div className="flex flex-col gap-1">
            <label className="text-xs font-medium text-gray-600">Año</label>
            <input
              type="number"
              min={1900}
              max={new Date().getFullYear() + 1}
              required
              value={anio}
              onChange={(e) => setAnio(e.target.value)}
              className="border border-gray-300 rounded-md px-2 py-1.5 text-sm w-32"
            />
          </div>

          <div className="flex flex-col gap-1">
            <label className="text-xs font-medium text-gray-600">Detalle de confort</label>
            <textarea
              value={detalleConfort}
              onChange={(e) => setDetalleConfort(e.target.value)}
              rows={3}
              className="border border-gray-300 rounded-md px-2 py-1.5 text-sm resize-none"
              placeholder="Aire acondicionado, GPS, etc."
            />
          </div>

          {error && (
            <div className="rounded-md bg-red-50 border border-red-200 px-3 py-2">
              <p className="text-red-700 text-xs">{error}</p>
            </div>
          )}

          <div className="flex gap-2 justify-end mt-2">
            <button
              type="button"
              onClick={onClose}
              disabled={loading}
              className="px-4 py-2 text-sm font-medium text-gray-700 border border-gray-300 rounded-lg hover:bg-gray-50 disabled:opacity-50"
            >
              Cancelar
            </button>
            <button
              type="submit"
              disabled={loading}
              className="px-4 py-2 text-sm font-medium text-white bg-blue-600 rounded-lg hover:bg-blue-700 disabled:opacity-50"
            >
              {loading ? 'Guardando...' : modo === 'crear' ? 'Crear' : 'Guardar cambios'}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}
