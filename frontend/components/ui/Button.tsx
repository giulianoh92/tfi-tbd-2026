import { forwardRef, type ButtonHTMLAttributes } from 'react'
import { cva, type VariantProps } from 'class-variance-authority'
import { cn } from '@/lib/cn'

/**
 * Button — primitive base del design system.
 *
 * Convenciones:
 *  - focus-visible con ring brand-500 (no el blue default).
 *  - disabled bloqueo visual + cursor + aria.
 *  - loading muestra spinner inline, deshabilita interaccion.
 *  - asChild ausente a proposito: si necesitas un Link "como boton", usa
 *    `buttonVariants` para componer las clases.
 */
const buttonVariants = cva(
  // Base: layout + tipografia + transicion + focus consistente
  [
    'inline-flex items-center justify-center gap-2',
    'rounded-lg font-medium select-none',
    'transition-colors duration-150',
    'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand-500 focus-visible:ring-offset-2 focus-visible:ring-offset-surface-default',
    'disabled:opacity-50 disabled:cursor-not-allowed disabled:pointer-events-none',
  ],
  {
    variants: {
      variant: {
        primary: [
          'bg-brand-600 text-white shadow-sm',
          'hover:bg-brand-700',
          'active:bg-brand-700',
        ],
        secondary: [
          'bg-white text-slate-900 border border-slate-200 shadow-sm',
          'hover:bg-slate-50 hover:border-slate-300',
        ],
        ghost: [
          'bg-transparent text-slate-700',
          'hover:bg-slate-100 hover:text-slate-900',
        ],
        destructive: [
          'bg-danger-fg text-white shadow-sm',
          'hover:bg-red-800',
        ],
        link: [
          'bg-transparent text-brand-700 underline-offset-4',
          'hover:underline hover:text-brand-700',
          'p-0 h-auto',
        ],
      },
      size: {
        sm: 'h-8 px-3 text-sm',
        md: 'h-10 px-4 text-sm',
        lg: 'h-11 px-5 text-base',
        icon: 'h-9 w-9 p-0',
      },
    },
    defaultVariants: {
      variant: 'primary',
      size: 'md',
    },
  }
)

export interface ButtonProps
  extends ButtonHTMLAttributes<HTMLButtonElement>,
    VariantProps<typeof buttonVariants> {
  loading?: boolean
}

export const Button = forwardRef<HTMLButtonElement, ButtonProps>(
  ({ className, variant, size, loading = false, disabled, children, ...props }, ref) => {
    return (
      <button
        ref={ref}
        className={cn(buttonVariants({ variant, size }), className)}
        disabled={disabled || loading}
        aria-busy={loading || undefined}
        {...props}
      >
        {loading && <Spinner />}
        {children}
      </button>
    )
  }
)
Button.displayName = 'Button'

function Spinner() {
  return (
    <svg
      className="h-4 w-4 animate-spin"
      xmlns="http://www.w3.org/2000/svg"
      fill="none"
      viewBox="0 0 24 24"
      aria-hidden="true"
    >
      <circle
        className="opacity-25"
        cx="12"
        cy="12"
        r="10"
        stroke="currentColor"
        strokeWidth="4"
      />
      <path
        className="opacity-75"
        fill="currentColor"
        d="M4 12a8 8 0 018-8v4a4 4 0 00-4 4H4z"
      />
    </svg>
  )
}

export { buttonVariants }
