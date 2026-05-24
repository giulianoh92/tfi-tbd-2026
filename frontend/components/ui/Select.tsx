import { forwardRef, type SelectHTMLAttributes } from 'react'
import { cn } from '@/lib/cn'

/**
 * Select nativo con styling del design system.
 * Para listas largas (clientes / vehiculos) usar Combobox en su lugar (F7).
 */
export type SelectProps = SelectHTMLAttributes<HTMLSelectElement>

export const Select = forwardRef<HTMLSelectElement, SelectProps>(
  ({ className, children, ...props }, ref) => {
    return (
      <select
        ref={ref}
        className={cn(
          'w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm text-slate-900 shadow-sm appearance-none',
          'bg-[url("data:image/svg+xml;charset=utf-8,%3Csvg%20xmlns%3D%22http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg%22%20viewBox%3D%220%200%2020%2020%22%20fill%3D%22%2364748b%22%3E%3Cpath%20fill-rule%3D%22evenodd%22%20d%3D%22M10%2012a1%201%200%2001-.7-.3l-3-3a1%201%200%20011.4-1.4L10%209.6l2.3-2.3a1%201%200%20011.4%201.4l-3%203a1%201%200%2001-.7.3z%22%20clip-rule%3D%22evenodd%22%2F%3E%3C%2Fsvg%3E")] bg-no-repeat bg-[right_0.5rem_center] bg-[length:1.25em] pr-9',
          'focus:outline-none focus:ring-2 focus:ring-brand-500 focus:border-brand-500',
          'disabled:bg-slate-50 disabled:text-slate-500 disabled:cursor-not-allowed',
          'aria-[invalid=true]:border-danger-border aria-[invalid=true]:focus:ring-danger-fg',
          className
        )}
        {...props}
      >
        {children}
      </select>
    )
  }
)
Select.displayName = 'Select'
