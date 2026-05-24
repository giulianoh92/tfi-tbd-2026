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
      const { error } = await supabase.auth.signUp({ email, password })
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
