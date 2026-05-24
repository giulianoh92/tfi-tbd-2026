import type { Config } from 'tailwindcss'

/**
 * Design system tokens — Sprint 6.
 *
 * Filosofia:
 *  - Brand teal/emerald (NO el blue-600 default de Tailwind): da identidad propia.
 *  - Surface en escala de elevacion (default -> raised -> elevated -> paper).
 *  - Estados semanticos (success/danger/warning/info/muted) con triada bg/fg/border
 *    para que componentes consuman tokens, no colores crudos.
 *  - Brand-staff slate/indigo para banner admin (no compite con amber pendiente).
 */
const config: Config = {
  content: [
    './pages/**/*.{js,ts,jsx,tsx,mdx}',
    './components/**/*.{js,ts,jsx,tsx,mdx}',
    './app/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    extend: {
      colors: {
        // Brand teal — diferencia clara contra el blue-600 default
        brand: {
          50:  '#ecfdf5',
          100: '#d1fae5',
          200: '#a7f3d0',
          500: '#10b981',
          600: '#059669',
          700: '#047857',
        },
        // Surfaces: jerarquia de elevacion sobre fondo neutral
        surface: {
          default:  '#f8fafc',  // slate-50: fondo de la app
          raised:   '#ffffff',  // cards sobre default
          elevated: '#ffffff',  // popovers, modales (con shadow-lg)
          paper:    '#fefce8',  // facturas / documentos
        },
        // Estados semanticos
        success: {
          bg:     '#ecfdf5',
          fg:     '#047857',
          border: '#a7f3d0',
        },
        danger: {
          bg:     '#fef2f2',
          fg:     '#b91c1c',
          border: '#fecaca',
        },
        warning: {
          bg:     '#fffbeb',
          fg:     '#b45309',
          border: '#fde68a',
        },
        info: {
          bg:     '#eff6ff',
          fg:     '#1d4ed8',
          border: '#bfdbfe',
        },
        muted: {
          fg: '#475569',  // slate-600 (contraste WCAG AA sobre blanco)
          bg: '#f1f5f9',  // slate-100
        },
        // Banner staff: slate / indigo, no amber para no colisionar con "pendiente"
        'brand-staff': {
          bg:     '#eef2ff',  // indigo-50
          fg:     '#3730a3',  // indigo-800
          border: '#c7d2fe',  // indigo-200
        },
      },
      fontFamily: {
        sans:    ['var(--font-sans)', 'system-ui', 'sans-serif'],
        display: ['var(--font-display)', 'system-ui', 'sans-serif'],
      },
      // Densidad de tablas (Sprint F10)
      spacing: {
        '4.5': '1.125rem',
      },
      // Numeros tabulares para precios / facturas
      fontFeatureSettings: {
        tabular: ['tnum', 'lnum'],
      },
    },
  },
  plugins: [],
}
export default config
