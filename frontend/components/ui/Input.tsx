import { forwardRef, type InputHTMLAttributes } from 'react'
import { cn } from '@/lib/cn'

/**
 * Input — text/number/email/etc.
 *
 * - `aria-invalid="true"` activa borde rojo + ring danger.
 * - focus ring brand-500.
 * - Para errores inline ver patron en F6.4: pasar `aria-invalid` + `aria-describedby`
 *   apuntando al `<p id="..-error">` con el mensaje.
 */
export type InputProps = InputHTMLAttributes<HTMLInputElement>

export const Input = forwardRef<HTMLInputElement, InputProps>(
  ({ className, type = 'text', ...props }, ref) => {
    return (
      <input
        ref={ref}
        type={type}
        className={cn(
          'w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm text-slate-900 shadow-sm',
          'placeholder:text-slate-400',
          'focus:outline-none focus:ring-2 focus:ring-brand-500 focus:border-brand-500',
          'disabled:bg-slate-50 disabled:text-slate-500 disabled:cursor-not-allowed',
          'aria-[invalid=true]:border-danger-border aria-[invalid=true]:focus:ring-danger-fg aria-[invalid=true]:focus:border-danger-fg',
          className
        )}
        {...props}
      />
    )
  }
)
Input.displayName = 'Input'
