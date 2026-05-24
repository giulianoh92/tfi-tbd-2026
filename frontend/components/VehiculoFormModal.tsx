'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { createClient } from '@/lib/supabase/client'
import type { Sucursal, TipoVehiculo, Vehiculo } from '@/types/database'
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/Dialog'
import { Button } from '@/components/ui/Button'
import { Input } from '@/components/ui/Input'
import { Select } from '@/components/ui/Select'
import { Textarea } from '@/components/ui/Textarea'
import { Label } from '@/components/ui/Label'

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
    <Dialog open={open} onOpenChange={(o) => !o && !loading && onClose()}>
      <DialogContent
        // Evita que click fuera cierre cuando hay submit en curso.
        onPointerDownOutside={(e) => loading && e.preventDefault()}
        onEscapeKeyDown={(e) => loading && e.preventDefault()}
      >
        <DialogHeader>
          <DialogTitle>
            {modo === 'crear' ? 'Nuevo vehiculo' : `Editar vehiculo #${vehiculo?.id_vehiculo}`}
          </DialogTitle>
          <DialogDescription>
            {modo === 'crear'
              ? 'Da de alta un vehiculo en la flota. Patente y sucursal no son editables despues.'
              : 'Solo marca, modelo, año y confort son editables. El resto se gobierna desde la operacion.'}
          </DialogDescription>
        </DialogHeader>

        <form onSubmit={handleSubmit} className="flex flex-col gap-4" noValidate>
          {modo === 'crear' && (
            <>
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <Label htmlFor="vfm-sucursal" required>Sucursal origen</Label>
                  <Select
                    id="vfm-sucursal"
                    required
                    value={idSucursal}
                    onChange={(e) => setIdSucursal(e.target.value)}
                  >
                    {sucursales.map((s) => (
                      <option key={s.id_sucursal} value={s.id_sucursal}>
                        {s.nombre}
                      </option>
                    ))}
                  </Select>
                </div>
                <div>
                  <Label htmlFor="vfm-tipo" required>Tipo</Label>
                  <Select
                    id="vfm-tipo"
                    required
                    value={idTipo}
                    onChange={(e) => setIdTipo(e.target.value)}
                  >
                    {tiposVehiculo.map((t) => (
                      <option key={t.id_tipo} value={t.id_tipo}>
                        {t.nombre}
                      </option>
                    ))}
                  </Select>
                </div>
              </div>
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <Label htmlFor="vfm-patente" required>Patente</Label>
                  <Input
                    id="vfm-patente"
                    type="text"
                    required
                    maxLength={15}
                    value={patente}
                    onChange={(e) => setPatente(e.target.value.toUpperCase())}
                    className="uppercase"
                  />
                </div>
                <div>
                  <Label htmlFor="vfm-km" required>Km actuales</Label>
                  <Input
                    id="vfm-km"
                    type="number"
                    min={0}
                    step={1}
                    required
                    value={kmActuales}
                    onChange={(e) => setKmActuales(e.target.value)}
                  />
                </div>
              </div>
            </>
          )}

          <div className="grid grid-cols-2 gap-3">
            <div>
              <Label htmlFor="vfm-marca" required>Marca</Label>
              <Input
                id="vfm-marca"
                type="text"
                required
                maxLength={50}
                value={marca}
                onChange={(e) => setMarca(e.target.value)}
              />
            </div>
            <div>
              <Label htmlFor="vfm-modelo" required>Modelo</Label>
              <Input
                id="vfm-modelo"
                type="text"
                required
                maxLength={50}
                value={modelo}
                onChange={(e) => setModelo(e.target.value)}
              />
            </div>
          </div>

          <div>
            <Label htmlFor="vfm-anio" required>Año</Label>
            <Input
              id="vfm-anio"
              type="number"
              min={1900}
              max={new Date().getFullYear() + 1}
              required
              value={anio}
              onChange={(e) => setAnio(e.target.value)}
              className="w-32"
            />
          </div>

          <div>
            <Label htmlFor="vfm-confort">Detalle de confort</Label>
            <Textarea
              id="vfm-confort"
              value={detalleConfort}
              onChange={(e) => setDetalleConfort(e.target.value)}
              rows={3}
              placeholder="Aire acondicionado, GPS, etc."
            />
          </div>

          {error && (
            <div
              role="alert"
              className="rounded-md bg-danger-bg border border-danger-border px-3 py-2"
            >
              <p className="text-danger-fg text-xs">{error}</p>
            </div>
          )}

          <DialogFooter>
            <Button
              type="button"
              variant="secondary"
              onClick={onClose}
              disabled={loading}
            >
              Cancelar
            </Button>
            <Button type="submit" variant="primary" loading={loading}>
              {loading ? 'Guardando...' : modo === 'crear' ? 'Crear' : 'Guardar cambios'}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  )
}
