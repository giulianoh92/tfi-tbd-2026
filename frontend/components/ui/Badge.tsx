import { forwardRef, type HTMLAttributes } from 'react'
import { cva, type VariantProps } from 'class-variance-authority'
import { cn } from '@/lib/cn'

const badgeVariants = cva(
  'inline-flex items-center gap-1 rounded-full border px-2.5 py-0.5 text-xs font-medium whitespace-nowrap',
  {
    variants: {
      variant: {
        success: 'bg-success-bg text-success-fg border-success-border',
        danger:  'bg-danger-bg  text-danger-fg  border-danger-border',
        warning: 'bg-warning-bg text-warning-fg border-warning-border',
        info:    'bg-info-bg    text-info-fg    border-info-border',
        muted:   'bg-muted-bg   text-muted-fg   border-slate-200',
        brand:   'bg-brand-50   text-brand-700  border-brand-200',
        staff:   'bg-brand-staff-bg text-brand-staff-fg border-brand-staff-border',
      },
    },
    defaultVariants: {
      variant: 'muted',
    },
  }
)

export interface BadgeProps
  extends HTMLAttributes<HTMLSpanElement>,
    VariantProps<typeof badgeVariants> {}

export const Badge = forwardRef<HTMLSpanElement, BadgeProps>(
  ({ className, variant, ...props }, ref) => {
    return (
      <span
        ref={ref}
        className={cn(badgeVariants({ variant }), className)}
        {...props}
      />
    )
  }
)
Badge.displayName = 'Badge'

export { badgeVariants }
