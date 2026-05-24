import type { Metadata } from 'next'
import { Inter, Inter_Tight } from 'next/font/google'
import './globals.css'
import { Nav } from '@/components/Nav'

// Fuente body (Inter) + fuente display (Inter Tight) para H1/H2 con caracter propio.
// Variables CSS expuestas a Tailwind (fontFamily.sans / fontFamily.display).
const sans = Inter({
  subsets: ['latin'],
  variable: '--font-sans',
  display: 'swap',
})

const display = Inter_Tight({
  subsets: ['latin'],
  variable: '--font-display',
  display: 'swap',
  weight: ['500', '600', '700'],
})

export const metadata: Metadata = {
  title: 'AutoRenta — Alquiler de Vehículos',
  description: 'Sistema de alquiler de vehículos — TBD TFI 2026',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="es" className={`${sans.variable} ${display.variable}`}>
      <body className="font-sans bg-surface-default min-h-screen text-slate-900 antialiased">
        <Nav />
        <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
          {children}
        </main>
      </body>
    </html>
  )
}
