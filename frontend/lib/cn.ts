import { clsx, type ClassValue } from 'clsx'
import { twMerge } from 'tailwind-merge'

/**
 * `cn` — combina clsx (concat condicional) + tailwind-merge (dedupe Tailwind).
 * Convencion: la ultima clase Tailwind del mismo bucket gana.
 *
 * @example
 *   cn('px-2 py-1', condition && 'px-4')  // -> 'py-1 px-4'
 */
export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}
