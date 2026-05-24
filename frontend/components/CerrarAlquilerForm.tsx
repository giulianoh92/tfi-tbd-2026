'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { createClient } from '@/lib/supabase/client'
import type { Sucursal } from '@/types/database'

interface Props {
  idAlquiler: number
  kmInicio: number
  sucursales: Sucursal[]
}

/**
 * Formulario de cierre de alquiler.
 * Llama al procedure pa_finalizar_alquiler vía RPC.
 * Si cierra OK → busca la factura generada y redirige a su detalle.
 */
export function CerrarAlquilerForm({ idAlquiler, kmInicio, sucursales }: Props) {
  const router = useRouter()
  const supabase = createClient()

  const [kmFin, setKmFin] = useState<string>('')
  const [idSucursal, setIdSucursal] = useState<string>('')
  const [loading, setLoading] = useState(false)
  const [errorMsg, setErrorMsg] = useState<string | null>(null)

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    setErrorMsg(null)

    const kmFinNum = parseInt(kmFin, 10)
    const sucursalNum = parseInt(idSucursal, 10)

    if (isNaN(kmFinNum) || kmFinNum <= kmInicio) {
      setErrorMsg(`El km final debe ser mayor a ${kmInicio.toLocaleString('es-AR')} km (km de inicio).`)
      return
    }
    if (isNaN(sucursalNum)) {
      setErrorMsg('Seleccioná una sucursal de devolución.')
      return
    }

    setLoading(true)

    // Llama al stored procedure que cierra el alquiler y emite la factura.
    // Sprint 5 (R2): el procedure ahora devuelve { p_estado, p_mensaje,
    // p_id_factura } via OUT params. Solo lanza error HTTP si hay un fallo
    // de transporte / RLS; las violaciones de regla de negocio vienen como
    // p_estado != 'OK' con p_mensaje legible.
    const { data: rpcData, error: rpcError } = await supabase.rpc('pa_finalizar_alquiler', {
      p_id_alquiler: idAlquiler,
      p_km_fin: kmFinNum,
      p_id_sucursal_devolucion: sucursalNum,
    })

    if (rpcError) {
      let msg = rpcError.message
      if (msg.includes('row-level security')) {
        msg = 'No tenés permisos para cerrar este alquiler (RLS). Verificá que tu usuario tenga rol staff.'
      }
      setErrorMsg(msg)
      setLoading(false)
      return
    }

    if (rpcData && rpcData.p_estado !== 'OK') {
      setErrorMsg(rpcData.p_mensaje ?? 'No se pudo cerrar el alquiler.')
      setLoading(false)
      return
    }

    // p_id_factura viene del procedure (fn_calcular_factura). Si por algun
    // motivo viniera nulo, fallback a buscarla por id_alquiler.
    const idFactura = rpcData?.p_id_factura ?? null

    if (idFactura) {
      router.push(`/admin/facturas/${idFactura}`)
      return
    }

    const { data: facturaData, error: facturaError } = await supabase
      .from('factura')
      .select('id_factura')
      .eq('id_alquiler', idAlquiler)
      .order('id_factura', { ascending: false })
      .limit(1)
      .single()

    if (facturaError || !facturaData) {
      router.push('/admin/facturas')
      return
    }

    router.push(`/admin/facturas/${facturaData.id_factura}`)
  }

  return (
    <form onSubmit={handleSubmit} className="bg-white rounded-xl border border-gray-200 shadow-sm p-6 flex flex-col gap-5">
      <h2 className="text-lg font-semibold text-gray-900">Datos de devolución</h2>

      {/* Km final */}
      <div className="flex flex-col gap-1.5">
        <label htmlFor="km_fin" className="text-sm font-medium text-gray-700">
          Kilómetros al cierre <span className="text-red-500">*</span>
        </label>
        <input
          id="km_fin"
          type="number"
          min={kmInicio + 1}
          step={1}
          required
          value={kmFin}
          onChange={(e) => setKmFin(e.target.value)}
          placeholder={`Mínimo ${(kmInicio + 1).toLocaleString('es-AR')}`}
          className="border border-gray-300 rounded-lg px-3 py-2 text-sm text-gray-900 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
        />
        <p className="text-xs text-gray-400">
          Km de inicio registrado: {kmInicio.toLocaleString('es-AR')} km
        </p>
      </div>

      {/* Sucursal de devolución */}
      <div className="flex flex-col gap-1.5">
        <label htmlFor="id_sucursal_devolucion" className="text-sm font-medium text-gray-700">
          Sucursal de devolución <span className="text-red-500">*</span>
        </label>
        <select
          id="id_sucursal_devolucion"
          required
          value={idSucursal}
          onChange={(e) => setIdSucursal(e.target.value)}
          className="border border-gray-300 rounded-lg px-3 py-2 text-sm text-gray-900 bg-white focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
        >
          <option value="" disabled>
            Seleccioná una sucursal...
          </option>
          {sucursales.map((s) => (
            <option key={s.id_sucursal} value={s.id_sucursal}>
              {s.nombre}
            </option>
          ))}
        </select>
      </div>

      {/* Error */}
      {errorMsg && (
        <div className="rounded-lg bg-red-50 border border-red-200 p-3">
          <p className="text-red-700 text-sm font-medium">Error al cerrar alquiler</p>
          <p className="text-red-500 text-xs mt-1">{errorMsg}</p>
        </div>
      )}

      {/* Submit */}
      <button
        type="submit"
        disabled={loading}
        className="w-full py-2.5 bg-orange-600 text-white text-sm font-semibold rounded-lg hover:bg-orange-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
      >
        {loading ? 'Procesando cierre...' : 'Confirmar cierre'}
      </button>

      <p className="text-xs text-gray-400 text-center">
        Esta acción es irreversible. Se emitirá la factura automáticamente.
      </p>
    </form>
  )
}
