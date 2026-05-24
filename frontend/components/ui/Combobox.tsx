'use client'

import { useEffect, useMemo, useRef, useState, type KeyboardEvent } from 'react'
import * as Popover from '@radix-ui/react-popover'
import { Check, ChevronsUpDown, Search } from 'lucide-react'
import { cn } from '@/lib/cn'

/**
 * Combobox — input con autocomplete + lista filtrable.
 *
 * Trade-off vs cmdk: composicion manual sobre Radix Popover. Mas codigo,
 * cero dependencias extra, control total del filter. Suficiente para listas
 * de hasta ~5k items (sin virtualizacion).
 *
 * Teclado:
 *   - ArrowUp / ArrowDown: navegar opciones
 *   - Enter: seleccionar resaltada
 *   - Escape: cerrar
 *   - Tab: cerrar y seguir foco normal
 */
export interface ComboboxItem<V extends string | number> {
  value: V
  label: string
  hint?: string
}

export interface ComboboxProps<V extends string | number> {
  items: ComboboxItem<V>[]
  value: V | null
  onChange: (v: V) => void
  placeholder?: string
  emptyMessage?: string
  searchPlaceholder?: string
  /** id para asociar Label externo. */
  id?: string
  /** Marca aria-invalid (estilo error). */
  ariaInvalid?: boolean
  /** Aria-describedby para conectar mensaje de error. */
  ariaDescribedBy?: string
  disabled?: boolean
  className?: string
  /** Texto cuando no hay seleccion. */
  notSelectedLabel?: string
}

export function Combobox<V extends string | number>({
  items,
  value,
  onChange,
  placeholder = 'Seleccioná una opción...',
  emptyMessage = 'Sin resultados.',
  searchPlaceholder = 'Buscar...',
  id,
  ariaInvalid,
  ariaDescribedBy,
  disabled,
  className,
  notSelectedLabel,
}: ComboboxProps<V>) {
  const [open, setOpen] = useState(false)
  const [query, setQuery] = useState('')
  const [highlight, setHighlight] = useState(0)
  const listRef = useRef<HTMLUListElement>(null)

  const selected = items.find((i) => i.value === value) ?? null

  const filtered = useMemo(() => {
    if (!query.trim()) return items
    const q = query.toLowerCase()
    return items.filter(
      (i) =>
        i.label.toLowerCase().includes(q) ||
        (i.hint?.toLowerCase().includes(q) ?? false)
    )
  }, [items, query])

  // Reset highlight cuando cambia filtrado
  useEffect(() => {
    setHighlight(0)
  }, [query])

  // Scroll item resaltado a la vista
  useEffect(() => {
    if (!open || !listRef.current) return
    const el = listRef.current.querySelector<HTMLLIElement>(
      `[data-index="${highlight}"]`
    )
    el?.scrollIntoView({ block: 'nearest' })
  }, [highlight, open])

  function handleSelect(v: V) {
    onChange(v)
    setOpen(false)
    setQuery('')
  }

  function handleKey(e: KeyboardEvent<HTMLInputElement>) {
    if (e.key === 'ArrowDown') {
      e.preventDefault()
      setHighlight((h) => Math.min(h + 1, Math.max(filtered.length - 1, 0)))
    } else if (e.key === 'ArrowUp') {
      e.preventDefault()
      setHighlight((h) => Math.max(h - 1, 0))
    } else if (e.key === 'Enter') {
      e.preventDefault()
      const item = filtered[highlight]
      if (item) handleSelect(item.value)
    } else if (e.key === 'Escape') {
      e.preventDefault()
      setOpen(false)
    }
  }

  return (
    <Popover.Root open={open} onOpenChange={setOpen}>
      <Popover.Trigger asChild>
        <button
          type="button"
          id={id}
          disabled={disabled}
          aria-invalid={ariaInvalid || undefined}
          aria-describedby={ariaDescribedBy}
          role="combobox"
          aria-expanded={open}
          className={cn(
            'flex w-full items-center justify-between gap-2 rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm text-left shadow-sm',
            'focus:outline-none focus:ring-2 focus:ring-brand-500 focus:border-brand-500',
            'disabled:bg-slate-50 disabled:text-slate-500 disabled:cursor-not-allowed',
            'aria-[invalid=true]:border-danger-border aria-[invalid=true]:focus:ring-danger-fg',
            className
          )}
        >
          <span className={cn('truncate', !selected && 'text-slate-400')}>
            {selected ? selected.label : (notSelectedLabel ?? placeholder)}
          </span>
          <ChevronsUpDown className="h-4 w-4 shrink-0 text-slate-400" aria-hidden="true" />
        </button>
      </Popover.Trigger>

      <Popover.Portal>
        <Popover.Content
          align="start"
          sideOffset={4}
          className={cn(
            'z-50 w-[--radix-popover-trigger-width] rounded-lg border border-slate-200 bg-white p-1 shadow-lg',
            'data-[state=open]:animate-in data-[state=open]:fade-in-0 data-[state=open]:zoom-in-95'
          )}
        >
          <div className="flex items-center gap-2 border-b border-slate-100 px-2 pb-1.5 pt-1">
            <Search className="h-4 w-4 text-slate-400 shrink-0" aria-hidden="true" />
            <input
              autoFocus
              type="text"
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              onKeyDown={handleKey}
              placeholder={searchPlaceholder}
              className="w-full bg-transparent text-sm outline-none placeholder:text-slate-400"
              aria-label={searchPlaceholder}
            />
          </div>

          {filtered.length === 0 ? (
            <p className="px-3 py-6 text-center text-sm text-muted-fg">
              {emptyMessage}
            </p>
          ) : (
            <ul
              ref={listRef}
              role="listbox"
              className="max-h-64 overflow-y-auto py-1"
            >
              {filtered.map((item, idx) => {
                const isSel = item.value === value
                const isHl = idx === highlight
                return (
                  <li key={String(item.value)} data-index={idx}>
                    <button
                      type="button"
                      role="option"
                      aria-selected={isSel}
                      onClick={() => handleSelect(item.value)}
                      onMouseEnter={() => setHighlight(idx)}
                      className={cn(
                        'flex w-full items-center justify-between gap-2 rounded-md px-2.5 py-1.5 text-left text-sm transition-colors',
                        isHl ? 'bg-brand-50 text-brand-700' : 'text-slate-800 hover:bg-slate-50'
                      )}
                    >
                      <span className="flex flex-col min-w-0">
                        <span className="truncate font-medium">{item.label}</span>
                        {item.hint && (
                          <span className="truncate text-xs text-muted-fg">
                            {item.hint}
                          </span>
                        )}
                      </span>
                      {isSel && <Check className="h-4 w-4 shrink-0 text-brand-600" aria-hidden="true" />}
                    </button>
                  </li>
                )
              })}
            </ul>
          )}
        </Popover.Content>
      </Popover.Portal>
    </Popover.Root>
  )
}
