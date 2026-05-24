'use client'

import { useEffect } from 'react'
import { AlertTriangle, RotateCw } from 'lucide-react'
import { Card } from '@/components/ui/Card'
import { Button } from '@/components/ui/Button'

/**
 * Error boundary global. Captura excepciones de Server Components y
 * Client Components que escalen hasta acá.
 */
export default function GlobalError({
  error,
  reset,
}: {
  error: Error & { digest?: string }
  reset: () => void
}) {
  useEffect(() => {
    // Log para developers / Vercel error tracking
    // eslint-disable-next-line no-console
    console.error('[GlobalError]', error)
  }, [error])

  return (
    <Card variant="raised" className="max-w-xl mx-auto mt-12 p-8 text-center">
      <div className="mx-auto w-12 h-12 rounded-full bg-danger-bg flex items-center justify-center">
        <AlertTriangle className="w-6 h-6 text-danger-fg" aria-hidden="true" />
      </div>
      <h1 className="mt-4 font-display text-xl font-semibold text-slate-900">
        Algo salió mal
      </h1>
      <p className="mt-2 text-sm text-muted-fg">
        Tuvimos un problema cargando esta sección. Probá de nuevo en un momento.
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
