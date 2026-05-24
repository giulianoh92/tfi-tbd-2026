'use client'

import { useEffect, useState } from 'react'
import { Maximize2, Minimize2 } from 'lucide-react'
import { cn } from '@/lib/cn'

/**
 * Toggle de densidad de tablas — comfortable | compact.
 *
 * Persiste en localStorage (`autorenta:density`) y agrega clase
 * `density-compact` al `<body>` para que reglas CSS opcionales puedan
 * apretar paddings. Tambien expone data-density="..." para selectors
 * de tabla (.density-compact td { @apply py-1.5; } via globals.css).
 */
type Density = 'comfortable' | 'compact'

const STORAGE_KEY = 'autorenta:density'

export function DensityToggle() {
  const [density, setDensity] = useState<Density>('comfortable')
  const [mounted, setMounted] = useState(false)

  useEffect(() => {
    setMounted(true)
    const saved = localStorage.getItem(STORAGE_KEY) as Density | null
    if (saved === 'compact' || saved === 'comfortable') {
      setDensity(saved)
    }
  }, [])

  useEffect(() => {
    if (!mounted) return
    document.body.dataset.density = density
    localStorage.setItem(STORAGE_KEY, density)
  }, [density, mounted])

  if (!mounted) return null

  return (
    <div
      role="radiogroup"
      aria-label="Densidad de tablas"
      className="inline-flex items-center gap-0.5 rounded-lg border border-slate-200 bg-white p-0.5"
    >
      <DensityButton
        value="comfortable"
        current={density}
        onClick={() => setDensity('comfortable')}
        icon={<Maximize2 className="w-3.5 h-3.5" aria-hidden="true" />}
        label="Cómodo"
      />
      <DensityButton
        value="compact"
        current={density}
        onClick={() => setDensity('compact')}
        icon={<Minimize2 className="w-3.5 h-3.5" aria-hidden="true" />}
        label="Compacto"
      />
    </div>
  )
}

function DensityButton({
  value,
  current,
  onClick,
  icon,
  label,
}: {
  value: Density
  current: Density
  onClick: () => void
  icon: React.ReactNode
  label: string
}) {
  const active = current === value
  return (
    <button
      type="button"
      role="radio"
      aria-checked={active}
      onClick={onClick}
      className={cn(
        'inline-flex items-center gap-1.5 px-2.5 py-1 rounded text-xs font-medium transition-colors',
        'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand-500',
        active
          ? 'bg-brand-50 text-brand-700'
          : 'text-slate-600 hover:text-slate-900'
      )}
    >
      {icon}
      {label}
    </button>
  )
}
