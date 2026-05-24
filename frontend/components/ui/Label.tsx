import { forwardRef, type LabelHTMLAttributes } from 'react'
import { cn } from '@/lib/cn'

export interface LabelProps extends LabelHTMLAttributes<HTMLLabelElement> {
  required?: boolean
}

export const Label = forwardRef<HTMLLabelElement, LabelProps>(
  ({ className, required, children, ...props }, ref) => {
    return (
      <label
        ref={ref}
        className={cn('block text-sm font-medium text-slate-700 mb-1', className)}
        {...props}
      >
        {children}
        {required && (
          <span className="text-danger-fg ml-0.5" aria-hidden="true">
            *
          </span>
        )}
      </label>
    )
  }
)
Label.displayName = 'Label'
