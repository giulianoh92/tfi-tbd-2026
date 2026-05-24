'use client'

import { useEffect } from 'react'
import { AlertTriangle, RotateCw } from 'lucide-react'
import { Card } from '@/components/ui/Card'
import { Button } from '@/components/ui/Button'

/**
 * Error boundary del panel staff.
 */
export default function AdminError({
  error,
  reset,
}: {
  error: Error & { digest?: string }
  reset: () => void
}) {
  useEffect(() => {
    // eslint-disable-next-line no-console
    console.error('[AdminError]', error)
  }, [error])

  return (
    <Card variant="raised" className="max-w-xl mt-6 p-8 text-center">
      <div className="mx-auto w-12 h-12 rounded-full bg-danger-bg flex items-center justify-center">
        <AlertTriangle className="w-6 h-6 text-danger-fg" aria-hidden="true" />
      </div>
      <h1 className="mt-4 font-display text-xl font-semibold text-slate-900">
        No pudimos cargar esta sección
      </h1>
      <p className="mt-2 text-sm text-muted-fg">
        Reintentá o volvé al panel. Si el problema persiste, verificá el log del backend.
      </p>
      {error.digest && (
        <p className="mt-3 text-xs text-muted-fg font-mono">
          Referencia: {error.digest}
        </p>
      )}
      <div className="mt-6 flex items-center justify-center gap-3">
        <Button type="button" variant="primary" onClick={reset}>
          <RotateCw className="w-4 h-4" aria-hidden="true" />
          Reintentar
        </Button>
      </div>
    </Card>
  )
}
