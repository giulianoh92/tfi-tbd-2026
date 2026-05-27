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
  initial: {
    id_cliente: number
    nombre: string
    apellido: string
    dni: string
    telefono: string | null
    direccion: string | null
  }
}

/**
 * Form de edicion de datos personales del cliente autenticado.
 * Invoca pa_actualizar_cliente(nombre, apellido, dni, telefono, direccion).
 * El procedure resuelve la fila objetivo desde el JWT, no recibe id_cliente.
 */
export function PerfilForm({ initial }: Props) {
  const supabase = createClient()
  const router = useRouter()

  const [nombre, setNombre] = useState(initial.nombre)
  const [apellido, setApellido] = useState(initial.apellido)
  const [dni, setDni] = useState(initial.dni)
  const [telefono, setTelefono] = useState(initial.telefono ?? '')
  const [direccion, setDireccion] = useState(initial.direccion ?? '')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [success, setSuccess] = useState<string | null>(null)

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    setError(null)
    setSuccess(null)

    const dniLimpio = dni.replace(/\s+/g, '')
    if (!/^\d{7,9}$/.test(dniLimpio)) {
      setError('El DNI debe ser solo dígitos, sin puntos ni espacios (ej: 38123456).')
      return
    }
    if (!nombre.trim() || !apellido.trim()) {
      setError('Nombre y apellido son obligatorios.')
      return
    }

    setLoading(true)
    const { data, error: rpcError } = await rpcCall(
      supabase,
      'pa_actualizar_cliente',
      {
        p_nombre: nombre.trim(),
        p_apellido: apellido.trim(),
        p_dni: dniLimpio,
        p_telefono: telefono.trim() || null,
        p_direccion: direccion.trim() || null,
      } as FnArgs<'pa_actualizar_cliente'>,
    )

    if (rpcError) {
      setError(rpcError.message)
      setLoading(false)
      return
    }

    const result = data as { p_estado: string; p_mensaje: string } | null
    if (!result || result.p_estado !== 'OK') {
      setError(result?.p_mensaje ?? 'No se pudo actualizar el perfil.')
      setLoading(false)
      return
    }

    setSuccess('Datos personales actualizados.')
    setLoading(false)
    router.refresh()
  }

  return (
    <Card variant="raised" className="p-6">
      <form onSubmit={handleSubmit} className="space-y-4" noValidate>
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
          <div>
            <Label htmlFor="nombre" required>Nombre</Label>
            <Input
              id="nombre"
              type="text"
              required
              autoComplete="given-name"
              value={nombre}
              onChange={(e) => setNombre(e.target.value)}
            />
          </div>
          <div>
            <Label htmlFor="apellido" required>Apellido</Label>
            <Input
              id="apellido"
              type="text"
              required
              autoComplete="family-name"
              value={apellido}
              onChange={(e) => setApellido(e.target.value)}
            />
          </div>
        </div>

        <div>
          <Label htmlFor="dni" required>DNI</Label>
          <Input
            id="dni"
            type="text"
            inputMode="numeric"
            required
            value={dni}
            onChange={(e) => setDni(e.target.value)}
            placeholder="38123456"
          />
          <p className="text-xs text-muted-fg mt-1">Solo dígitos, sin puntos ni espacios.</p>
        </div>

        <div>
          <Label htmlFor="telefono">Teléfono</Label>
          <Input
            id="telefono"
            type="tel"
            autoComplete="tel"
            value={telefono}
            onChange={(e) => setTelefono(e.target.value)}
            placeholder="+54 11 1234-5678"
          />
        </div>

        <div>
          <Label htmlFor="direccion">Dirección</Label>
          <Input
            id="direccion"
            type="text"
            autoComplete="street-address"
            value={direccion}
            onChange={(e) => setDireccion(e.target.value)}
            placeholder="Av. Siempreviva 742"
          />
        </div>

        {error && (
          <div
            role="alert"
            className="rounded-lg bg-danger-bg border border-danger-border px-4 py-3"
          >
            <p className="text-danger-fg text-sm">{error}</p>
          </div>
        )}

        {success && (
          <div
            role="status"
            className="rounded-lg bg-success-bg border border-success-border px-4 py-3"
          >
            <p className="text-success-fg text-sm">{success}</p>
          </div>
        )}

        <Button
          type="submit"
          variant="primary"
          loading={loading}
          className="w-full"
        >
          {loading ? 'Guardando...' : 'Guardar cambios'}
        </Button>
      </form>
    </Card>
  )
}
