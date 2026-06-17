'use client'

import { Download, Printer } from 'lucide-react'
import { Button } from '@/components/ui/Button'

/**
 * Botones de export del cierre mensual (detalle de reportes-mensuales).
 *
 *  - CSV: arma el archivo en cliente (encabezados + filas + fila TOTAL) y dispara
 *    descarga via Blob + URL.createObjectURL. Montos numericos crudos (punto
 *    decimal, sin separador de miles) para que Excel/Sheets los lea como numero.
 *  - PDF: window.print() — el print CSS oculta nav/sidebar y deja solo el reporte.
 *
 * Recibe filas serializables (no el objeto Supabase completo) para poder vivir
 * en un client component sin arrastrar dependencias del server.
 */
export type ReporteFila = {
  sucursal: string
  facturas_emitidas: number
  total_costo_base: number
  total_recargos: number
  total_facturado: number
  km_recorridos: number
}

interface Props {
  filas: ReporteFila[]
  periodo: string // 'yyyy-mm-dd'
  mesLabel: string // "Mayo de 2026"
}

/** Escapa un campo para CSV (comillas dobles si contiene coma, comilla o salto). */
function csvCell(value: string | number): string {
  const s = String(value)
  if (/[",\n]/.test(s)) {
    return `"${s.replace(/"/g, '""')}"`
  }
  return s
}

export function ReporteExportButtons({ filas, periodo, mesLabel }: Props) {
  const handleCsv = () => {
    const headers = [
      'Sucursal',
      'Facturas emitidas',
      'Costo base',
      'Recargos',
      'Total facturado',
      'Km recorridos',
    ]

    const totales = filas.reduce(
      (acc, f) => ({
        facturas_emitidas: acc.facturas_emitidas + f.facturas_emitidas,
        total_costo_base: acc.total_costo_base + f.total_costo_base,
        total_recargos: acc.total_recargos + f.total_recargos,
        total_facturado: acc.total_facturado + f.total_facturado,
        km_recorridos: acc.km_recorridos + f.km_recorridos,
      }),
      {
        facturas_emitidas: 0,
        total_costo_base: 0,
        total_recargos: 0,
        total_facturado: 0,
        km_recorridos: 0,
      }
    )

    const rows = filas.map((f) => [
      f.sucursal,
      f.facturas_emitidas,
      f.total_costo_base,
      f.total_recargos,
      f.total_facturado,
      f.km_recorridos,
    ])

    const totalRow = [
      'TOTAL',
      totales.facturas_emitidas,
      totales.total_costo_base,
      totales.total_recargos,
      totales.total_facturado,
      totales.km_recorridos,
    ]

    const lines = [headers, ...rows, totalRow].map((cols) =>
      cols.map(csvCell).join(',')
    )
    const csv = lines.join('\r\n')

    const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' })
    const url = URL.createObjectURL(blob)
    const a = document.createElement('a')
    a.href = url
    a.download = `cierre-${periodo}.csv`
    document.body.appendChild(a)
    a.click()
    document.body.removeChild(a)
    URL.revokeObjectURL(url)
  }

  return (
    <div className="inline-flex items-center gap-2 print:hidden">
      <Button
        type="button"
        variant="secondary"
        size="sm"
        onClick={handleCsv}
        aria-label={`Exportar cierre de ${mesLabel} a CSV`}
      >
        <Download className="w-3.5 h-3.5" aria-hidden="true" />
        CSV
      </Button>
      <Button
        type="button"
        variant="secondary"
        size="sm"
        onClick={() => window.print()}
        aria-label={`Imprimir o guardar como PDF el cierre de ${mesLabel}`}
      >
        <Printer className="w-3.5 h-3.5" aria-hidden="true" />
        PDF
      </Button>
    </div>
  )
}
