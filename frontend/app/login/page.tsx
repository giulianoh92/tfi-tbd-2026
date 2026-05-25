'use client'

import { useState } from 'react'
import { useRouter, useSearchParams } from 'next/navigation'
import { createClient } from '@/lib/supabase/client'
import { Button } from '@/components/ui/Button'
import { Input } from '@/components/ui/Input'
import { Label } from '@/components/ui/Label'
import { Card, CardContent } from '@/components/ui/Card'
import { cn } from '@/lib/cn'

type Tab = 'ingresar' | 'registrarse'

export default function LoginPage() {
  const supabase = createClient()
  const router = useRouter()
  const searchParams = useSearchParams()
  const redirectTo = searchParams.get('redirect') ?? '/mis-reservas'

  const [tab, setTab] = useState<Tab>('ingresar')
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [nombre, setNombre] = useState('')
  const [apellido, setApellido] = useState('')
  const [dni, setDni] = useState('')
  const [telefono, setTelefono] = useState('')
  const [direccion, setDireccion] = useState('')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [message, setMessage] = useState<string | null>(null)

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    setLoading(true)
    setError(null)
    setMessage(null)

    if (tab === 'ingresar') {
      const { error } = await supabase.auth.signInWithPassword({ email, password })
      if (error) {
        setError(traducirError(error.message))
      } else {
        router.push(redirectTo)
        router.refresh()
      }
    } else {
      // Validacion basica: DNI numerico, campos obligatorios.
      const dniLimpio = dni.replace(/\s+/g, '')
      if (!/^\d{7,9}$/.test(dniLimpio)) {
        setError('El DNI debe tener entre 7 y 9 dígitos.')
        setLoading(false)
        return
      }
      if (!nombre.trim() || !apellido.trim()) {
        setError('Nombre y apellido son obligatorios.')
        setLoading(false)
        return
      }

      // Los datos personales viajan en `options.data` y quedan disponibles en
      // raw_user_meta_data del registro de auth.users. El trigger
      // fn_handle_new_auth_user los lee al crear la fila correspondiente en
      // public.cliente, asi se popula el perfil real en lugar de placeholders.
      const { error } = await supabase.auth.signUp({
        email,
        password,
        options: {
          data: {
            nombre: nombre.trim(),
            apellido: apellido.trim(),
            dni: dniLimpio,
            telefono: telefono.trim() || null,
            direccion: direccion.trim() || null,
          },
        },
      })
      if (error) {
        setError(traducirError(error.message))
      } else {
        setMessage(
          'Cuenta creada. Revisá tu email para confirmar (si tenés confirmación habilitada) y después ingresá.'
        )
      }
    }

    setLoading(false)
  }

  return (
    <div className="max-w-md mx-auto mt-8">
      <h1 className="font-display text-3xl font-bold text-slate-900 mb-1 text-center">
        {tab === 'ingresar' ? 'Ingresá a tu cuenta' : 'Creá tu cuenta'}
      </h1>
      <p className="text-sm text-muted-fg text-center mb-8">
        {tab === 'ingresar'
          ? 'Accedé a tus reservas y alquileres en curso.'
          : 'En menos de un minuto tenés tu cuenta lista.'}
      </p>

      <Card variant="raised">
        <CardContent className="p-6 pt-6">
          {/* Tabs */}
          <div
            className="flex border-b border-slate-200 mb-6"
            role="tablist"
            aria-label="Tipo de acción"
          >
            <TabButton
              active={tab === 'ingresar'}
              onClick={() => {
                setTab('ingresar')
                setError(null)
                setMessage(null)
              }}
            >
              Ingresar
            </TabButton>
            <TabButton
              active={tab === 'registrarse'}
              onClick={() => {
                setTab('registrarse')
                setError(null)
                setMessage(null)
              }}
            >
              Crear cuenta
            </TabButton>
          </div>

          <form onSubmit={handleSubmit} className="space-y-4" noValidate>
            <div>
              <Label htmlFor="email" required>
                Email
              </Label>
              <Input
                id="email"
                type="email"
                required
                autoComplete="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="vos@ejemplo.com"
                aria-invalid={error ? true : undefined}
                aria-describedby={error ? 'login-error' : undefined}
              />
            </div>

            <div>
              <Label htmlFor="password" required>
                Contraseña
              </Label>
              <Input
                id="password"
                type="password"
                required
                minLength={6}
                autoComplete={tab === 'ingresar' ? 'current-password' : 'new-password'}
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="Mínimo 6 caracteres"
                aria-invalid={error ? true : undefined}
                aria-describedby={error ? 'login-error' : undefined}
              />
            </div>

            {tab === 'registrarse' && (
              <fieldset className="space-y-4 rounded-lg border border-slate-200 p-4">
                <legend className="px-2 text-sm font-medium text-slate-700">
                  Datos personales
                </legend>

                <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                  <div>
                    <Label htmlFor="nombre" required>
                      Nombre
                    </Label>
                    <Input
                      id="nombre"
                      type="text"
                      required
                      autoComplete="given-name"
                      value={nombre}
                      onChange={(e) => setNombre(e.target.value)}
                      placeholder="Juan"
                    />
                  </div>
                  <div>
                    <Label htmlFor="apellido" required>
                      Apellido
                    </Label>
                    <Input
                      id="apellido"
                      type="text"
                      required
                      autoComplete="family-name"
                      value={apellido}
                      onChange={(e) => setApellido(e.target.value)}
                      placeholder="Pérez"
                    />
                  </div>
                </div>

                <div>
                  <Label htmlFor="dni" required>
                    DNI
                  </Label>
                  <Input
                    id="dni"
                    type="text"
                    inputMode="numeric"
                    required
                    value={dni}
                    onChange={(e) => setDni(e.target.value)}
                    placeholder="38123456"
                  />
                </div>

                <div>
                  <Label htmlFor="telefono">Teléfono</Label>
                  <Input
                    id="telefono"
                    type="tel"
                    autoComplete="tel"
                    value={telefono}
                    onChange={(e) => setTelefono(e.target.value)}
                    placeholder="+54 11 1234-5678 (opcional)"
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
                    placeholder="Av. Siempreviva 742 (opcional)"
                  />
                </div>
              </fieldset>
            )}

            {error && (
              <div
                id="login-error"
                role="alert"
                className="rounded-lg bg-danger-bg border border-danger-border px-4 py-3"
              >
                <p className="text-danger-fg text-sm">{error}</p>
              </div>
            )}

            {message && (
              <div
                role="status"
                className="rounded-lg bg-success-bg border border-success-border px-4 py-3"
              >
                <p className="text-success-fg text-sm">{message}</p>
              </div>
            )}

            <Button
              type="submit"
              variant="primary"
              size="lg"
              className="w-full"
              loading={loading}
            >
              {loading
                ? 'Procesando...'
                : tab === 'ingresar'
                ? 'Ingresar'
                : 'Crear cuenta'}
            </Button>
          </form>
        </CardContent>
      </Card>
    </div>
  )
}

function TabButton({
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
        'flex-1 py-2 text-sm font-medium transition-colors',
        'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand-500 focus-visible:ring-offset-2 rounded-t',
        active
          ? 'text-brand-700 border-b-2 border-brand-600'
          : 'text-slate-500 hover:text-slate-700 border-b-2 border-transparent'
      )}
    >
      {children}
    </button>
  )
}

function traducirError(msg: string): string {
  if (msg.includes('Invalid login credentials')) return 'Email o contraseña incorrectos.'
  if (msg.includes('Email not confirmed')) return 'Confirmá tu email antes de ingresar.'
  if (msg.includes('User already registered')) return 'Ya existe una cuenta con ese email.'
  if (msg.includes('Password should be at least')) return 'La contraseña debe tener al menos 6 caracteres.'
  return msg
}
