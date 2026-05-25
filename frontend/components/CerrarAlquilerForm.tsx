'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { createClient } from '@/lib/supabase/client'
import { rpcCall, type FnArgs } from '@/lib/supabase/rpc'
import type { Sucursal } from '@/types/database'
import { Card } from '@/components/ui/Card'
import { Button } from '@/components/ui/Button'
import { Input } from '@/components/ui/Input'
import { Select } from '@/components/ui/Select'
import { Label } from '@/components/ui/Label'

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
  const [fieldErrors, setFieldErrors] = useState<{ kmFin?: string; sucursal?: string }>({})

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    setErrorMsg(null)
    setFieldErrors({})

    const kmFinNum = parseInt(kmFin, 10)
    const sucursalNum = parseInt(idSucursal, 10)

    if (isNaN(kmFinNum) || kmFinNum <= kmInicio) {
      setFieldErrors({
        kmFin: `Debe ser mayor a ${kmInicio.toLocaleString('es-AR')} km.`,
      })
      return
    }
    if (isNaN(sucursalNum)) {
      setFieldErrors({ sucursal: 'Seleccioná una sucursal de devolución.' })
      return
    }

    setLoading(true)

    // pa_finalizar_alquiler tiene 3 IN params opcionales (DEFAULT NULL en el SP)
    // que los types regenerados marcan como required. Casteamos para sortear
    // esa discrepancia entre schema real y types/database.ts.
    const { data: rpcData, error: rpcError } = await rpcCall(
      supabase,
      'pa_finalizar_alquiler',
      {
        p_id_alquiler: idAlquiler,
        p_km_fin: kmFinNum,
        p_id_sucursal_devolucion: sucursalNum,
      } as FnArgs<'pa_finalizar_alquiler'>,
    )

    if (rpcError) {
      let msg = rpcError.message
      if (msg.includes('row-level security')) {
        msg = 'No tenés permisos para cerrar este alquiler (RLS). Verificá que tu usuario tenga rol staff.'
      }
      setErrorMsg(msg)
      setLoading(false)
      return
    }

    const result = rpcData as
      | { p_estado: string; p_mensaje: string; p_id_factura: number | null }
      | null

    if (result && result.p_estado !== 'OK') {
      setErrorMsg(result.p_mensaje ?? 'No se pudo cerrar el alquiler.')
      setLoading(false)
      return
    }

    const idFactura = result?.p_id_factura ?? null

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
      .single<{ id_factura: number }>()

    if (facturaError || !facturaData) {
      router.push('/admin/facturas')
      return
    }

    router.push(`/admin/facturas/${facturaData.id_factura}`)
  }

  return (
    <Card variant="raised" className="p-6">
      <form onSubmit={handleSubmit} className="flex flex-col gap-5" noValidate>
        <h2 className="font-display text-lg font-semibold text-slate-900">
          Datos de devolución
        </h2>

        {/* Km final */}
        <div>
          <Label htmlFor="km_fin" required>
            Kilómetros al cierre
          </Label>
          <Input
            id="km_fin"
            type="number"
            min={kmInicio + 1}
            step={1}
            required
            value={kmFin}
            onChange={(e) => setKmFin(e.target.value)}
            placeholder={`Mínimo ${(kmInicio + 1).toLocaleString('es-AR')}`}
            aria-invalid={fieldErrors.kmFin ? true : undefined}
            aria-describedby={fieldErrors.kmFin ? 'km_fin-error' : 'km_fin-help'}
          />
          {fieldErrors.kmFin ? (
            <p id="km_fin-error" className="mt-1 text-xs text-danger-fg">
              {fieldErrors.kmFin}
            </p>
          ) : (
            <p id="km_fin-help" className="mt-1 text-xs text-muted-fg">
              Km de inicio registrado: {kmInicio.toLocaleString('es-AR')} km
            </p>
          )}
        </div>

        {/* Sucursal de devolución */}
        <div>
          <Label htmlFor="id_sucursal_devolucion" required>
            Sucursal de devolución
          </Label>
          <Select
            id="id_sucursal_devolucion"
            required
            value={idSucursal}
            onChange={(e) => setIdSucursal(e.target.value)}
            aria-invalid={fieldErrors.sucursal ? true : undefined}
            aria-describedby={fieldErrors.sucursal ? 'sucursal-error' : undefined}
          >
            <option value="" disabled>
              Seleccioná una sucursal...
            </option>
            {sucursales.map((s) => (
              <option key={s.id_sucursal} value={s.id_sucursal}>
                {s.nombre}
              </option>
            ))}
          </Select>
          {fieldErrors.sucursal && (
            <p id="sucursal-error" className="mt-1 text-xs text-danger-fg">
              {fieldErrors.sucursal}
            </p>
          )}
        </div>

        {/* Error */}
        {errorMsg && (
          <div
            role="alert"
            className="rounded-lg bg-danger-bg border border-danger-border p-3"
          >
            <p className="text-danger-fg text-sm font-medium">Error al cerrar alquiler</p>
            <p className="text-danger-fg/80 text-xs mt-1">{errorMsg}</p>
          </div>
        )}

        <Button
          type="submit"
          variant="primary"
          loading={loading}
          className="w-full bg-orange-600 hover:bg-orange-700"
        >
          {loading ? 'Procesando cierre...' : 'Confirmar cierre'}
        </Button>

        <p className="text-xs text-muted-fg text-center">
          Esta acción es irreversible. Se emitirá la factura automáticamente.
        </p>
      </form>
    </Card>
  )
}
