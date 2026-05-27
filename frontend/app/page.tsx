import Link from 'next/link'
import { ArrowLeft, ArrowRight, SlidersHorizontal } from 'lucide-react'
import { createClient } from '@/lib/supabase/server'
import { VehiculoCard } from '@/components/VehiculoCard'
import { Card } from '@/components/ui/Card'
import { Button } from '@/components/ui/Button'
import { Input } from '@/components/ui/Input'
import { Select } from '@/components/ui/Select'
import { Label } from '@/components/ui/Label'
import type { Vehiculo, TipoVehiculo, ImagenVehiculo, Tarifa, Sucursal } from '@/types/database'

// Tipo compuesto para la landing: vehiculo enriquecido con joins
export type VehiculoConDetalles = Vehiculo & {
  tipo_vehiculo: Pick<TipoVehiculo, 'nombre'> | null
  imagen_portada: string | null
  precio_por_dia: number | null
}

const PAGE_SIZE = 12

interface SearchParams {
  tipo?: string
  sucursal?: string
  precio_min?: string
  precio_max?: string
  page?: string
}

export default async function HomePage({
  searchParams,
}: {
  searchParams: Promise<SearchParams>
}) {
  const params = await searchParams
  const supabase = await createClient()

  const pagina = Math.max(1, parseInt(params.page ?? '1', 10) || 1)
  const from = (pagina - 1) * PAGE_SIZE
  const to = from + PAGE_SIZE - 1

  const filtroTipo = params.tipo ?? ''
  const filtroSucursal = params.sucursal ?? ''
  const precioMin = params.precio_min ? Number(params.precio_min) : null
  const precioMax = params.precio_max ? Number(params.precio_max) : null

  // 1) Resolver id_estado 'disponible' para filtrar la flota visible al cliente.
  const estadoDispRes = await supabase
    .from('estado_vehiculo')
    .select('id_estado')
    .eq('nombre', 'disponible')
    .maybeSingle<{ id_estado: number }>()

  const idEstadoDisp = estadoDispRes.data?.id_estado ?? null

  // 2) Catalogos para filtros + queries principales en paralelo.
  let vehiculoQuery = supabase
    .from('vehiculo')
    .select(
      `
        *,
        tipo_vehiculo ( nombre ),
        imagen_vehiculo ( url_imagen, orden ),
        estado_vehiculo ( nombre )
      `,
      { count: 'exact' }
    )
    .order('id_vehiculo', { ascending: false })
    .range(from, to)

  // Filtro de disponibilidad (R5 home): solo vehiculos en estado "disponible"
  if (idEstadoDisp !== null) {
    vehiculoQuery = vehiculoQuery.eq('id_estado', idEstadoDisp)
  }

  if (filtroTipo) {
    vehiculoQuery = vehiculoQuery.eq('id_tipo', Number(filtroTipo))
  }
  if (filtroSucursal) {
    vehiculoQuery = vehiculoQuery.eq('id_sucursal_origen', Number(filtroSucursal))
  }

  const [vehiculosRes, tarifasRes, tiposRes, sucursalesRes, stockRes] = await Promise.all([
    vehiculoQuery,
    supabase.from('tarifa').select('precio_por_dia, id_sucursal, id_tipo'),
    supabase.from('tipo_vehiculo').select('id_tipo, nombre').order('nombre'),
    supabase.from('sucursal').select('id_sucursal, nombre').order('nombre'),
    supabase.from('vw_stock_por_modelo').select('marca, modelo, anio, unidades_disponibles'),
  ])

  // Tipamos manualmente la respuesta de la query con joins embedded: el
  // type inference de postgrest-js@2.106 colapsa a `never` cuando hay JOINs
  // complejos. La forma del shape esta dictada por el `.select(...)` arriba.
  type VehiculoRow = Vehiculo & {
    tipo_vehiculo: Pick<TipoVehiculo, 'nombre'> | null
    imagen_vehiculo: Pick<ImagenVehiculo, 'url_imagen' | 'orden'>[] | null
    estado_vehiculo: { nombre: string } | null
  }
  const vehiculos = (vehiculosRes.data ?? []) as VehiculoRow[]
  const tarifasAll = tarifasRes.data ?? []
  const tipos = (tiposRes.data ?? []) as Pick<TipoVehiculo, 'id_tipo' | 'nombre'>[]
  const sucursales = (sucursalesRes.data ?? []) as Pick<Sucursal, 'id_sucursal' | 'nombre'>[]
  const error = vehiculosRes.error ?? tarifasRes.error

  // Mapa de stock por modelo: clave `marca|modelo|anio` → unidades_disponibles
  type StockRow = { marca: string; modelo: string; anio: number; unidades_disponibles: number }
  const stockRows = (stockRes.data ?? []) as StockRow[]
  const mapaStock = new Map<string, number>()
  for (const s of stockRows) {
    mapaStock.set(`${s.marca}|${s.modelo}|${s.anio}`, s.unidades_disponibles)
  }

  if (error) {
    return (
      <div role="alert" className="rounded-lg bg-danger-bg border border-danger-border p-6">
        <p className="text-danger-fg font-medium">Error al cargar vehículos</p>
        <p className="text-danger-fg/80 text-sm mt-1">{error.message}</p>
        <p className="text-muted-fg text-xs mt-2">
          ¿Tenés el stack local corriendo? Corré{' '}
          <code className="bg-danger-bg/40 px-1 rounded">bash scripts/dev-frontend.sh</code>
        </p>
      </div>
    )
  }

  // Resolver tarifa por (tipo, sucursal) con fallback a tipo solo.
  const vehiculosNormalizados: VehiculoConDetalles[] = vehiculos.map((v) => {
    const imgs = v.imagen_vehiculo ?? []
    const portada = imgs.find((i) => i.orden === 1)?.url_imagen ?? null

    const tarifa =
      (tarifasAll as Tarifa[]).find(
        (t) => t.id_tipo === v.id_tipo && t.id_sucursal === v.id_sucursal_origen
      ) ?? (tarifasAll as Tarifa[]).find((t) => t.id_tipo === v.id_tipo) ?? null

    return {
      ...v,
      tipo_vehiculo: v.tipo_vehiculo,
      imagen_portada: portada,
      precio_por_dia: tarifa?.precio_por_dia ?? null,
    }
  })

  // Filtro de precio client-side: depende de tarifas calculadas arriba.
  const filtrados = vehiculosNormalizados.filter((v) => {
    if (precioMin != null && (v.precio_por_dia ?? Infinity) < precioMin) return false
    if (precioMax != null && (v.precio_por_dia ?? -Infinity) > precioMax) return false
    return true
  })

  const totalFlota = vehiculosRes.count ?? 0
  const totalPaginas = Math.max(1, Math.ceil(totalFlota / PAGE_SIZE))

  const buildHref = (overrides: Partial<SearchParams>) => {
    const qs = new URLSearchParams()
    const merged: SearchParams = {
      tipo: filtroTipo,
      sucursal: filtroSucursal,
      precio_min: params.precio_min ?? '',
      precio_max: params.precio_max ?? '',
      ...overrides,
    }
    if (merged.tipo) qs.set('tipo', merged.tipo)
    if (merged.sucursal) qs.set('sucursal', merged.sucursal)
    if (merged.precio_min) qs.set('precio_min', merged.precio_min)
    if (merged.precio_max) qs.set('precio_max', merged.precio_max)
    if (overrides.page && overrides.page !== '1') qs.set('page', overrides.page)
    const tail = qs.toString()
    return tail ? `/?${tail}` : '/'
  }

  return (
    <div>
      <div className="mb-8">
        <h1 className="font-display text-4xl font-bold text-slate-900 tracking-tight">
          Vehículos disponibles
        </h1>
        <p className="text-muted-fg mt-1">
          Elegí el vehículo que más se adapta a tu viaje.
        </p>
      </div>

      {/* Filtros */}
      <Card variant="raised" className="p-4 mb-6">
        <form
          key={`${filtroTipo}|${filtroSucursal}|${params.precio_min ?? ''}|${params.precio_max ?? ''}`}
          method="get"
          className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-5 gap-4 items-end"
        >
          <div>
            <Label htmlFor="tipo">
              <span className="inline-flex items-center gap-1.5">
                <SlidersHorizontal className="w-3.5 h-3.5" aria-hidden="true" />
                Tipo
              </span>
            </Label>
            <Select id="tipo" name="tipo" defaultValue={filtroTipo}>
              <option value="">Todos</option>
              {tipos.map((t) => (
                <option key={t.id_tipo} value={t.id_tipo}>{t.nombre}</option>
              ))}
            </Select>
          </div>

          <div>
            <Label htmlFor="sucursal">Sucursal</Label>
            <Select id="sucursal" name="sucursal" defaultValue={filtroSucursal}>
              <option value="">Todas</option>
              {sucursales.map((s) => (
                <option key={s.id_sucursal} value={s.id_sucursal}>{s.nombre}</option>
              ))}
            </Select>
          </div>

          <div>
            <Label htmlFor="precio_min">Precio mínimo</Label>
            <Input
              id="precio_min"
              type="number"
              name="precio_min"
              min={0}
              step={1000}
              defaultValue={params.precio_min ?? ''}
              placeholder="0"
            />
          </div>

          <div>
            <Label htmlFor="precio_max">Precio máximo</Label>
            <Input
              id="precio_max"
              type="number"
              name="precio_max"
              min={0}
              step={1000}
              defaultValue={params.precio_max ?? ''}
              placeholder="Sin límite"
            />
          </div>

          <div className="flex gap-2">
            <Button type="submit" variant="primary" className="flex-1">
              Filtrar
            </Button>
            <Link
              href="/"
              className="inline-flex items-center justify-center rounded-lg border border-slate-300 bg-white text-slate-700 text-sm font-medium px-4 py-2 hover:bg-slate-50 transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand-500"
            >
              Limpiar
            </Link>
          </div>
        </form>
      </Card>

      {filtrados.length === 0 ? (
        <EmptyState />
      ) : (
        <>
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
            {filtrados.map((v, idx) => (
              <VehiculoCard
                key={v.id_vehiculo}
                vehiculo={v}
                priority={idx < 3}
                unidadesDisponibles={mapaStock.get(`${v.marca}|${v.modelo}|${v.anio}`) ?? undefined}
              />
            ))}
          </div>

          {/* Paginacion server-side */}
          {totalPaginas > 1 && (
            <div className="flex items-center justify-between mt-8">
              <div className="text-sm text-muted-fg">
                Mostrando {from + 1}-{Math.min(to + 1, totalFlota)} de {totalFlota}
              </div>
              <div className="flex items-center gap-2">
                <PageNav
                  href={pagina > 1 ? buildHref({ page: String(pagina - 1) }) : null}
                  dir="prev"
                />
                <span className="text-sm text-muted-fg px-2 tabular-nums">
                  {pagina} / {totalPaginas}
                </span>
                <PageNav
                  href={pagina < totalPaginas ? buildHref({ page: String(pagina + 1) }) : null}
                  dir="next"
                />
              </div>
            </div>
          )}
        </>
      )}
    </div>
  )
}

function EmptyState() {
  return (
    <Card variant="flat" className="text-center py-16">
      <svg
        className="mx-auto h-20 w-20 text-slate-300"
        viewBox="0 0 64 64"
        fill="none"
        stroke="currentColor"
        strokeWidth="1.5"
        aria-hidden="true"
      >
        <rect x="8" y="22" width="48" height="22" rx="4" />
        <circle cx="20" cy="50" r="5" />
        <circle cx="44" cy="50" r="5" />
        <path d="M14 22l4-10h28l4 10" />
      </svg>
      <h2 className="mt-4 font-display text-lg font-semibold text-slate-900">
        No encontramos vehículos con esos filtros
      </h2>
      <p className="mt-1 text-sm text-muted-fg">
        Probá ampliar el rango de precio o quitar la sucursal.
      </p>
      <Link
        href="/"
        className="mt-5 inline-flex items-center gap-1 px-4 py-2 rounded-lg bg-brand-600 text-white text-sm font-medium hover:bg-brand-700 transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand-500 focus-visible:ring-offset-2"
      >
        Limpiar filtros
      </Link>
    </Card>
  )
}

function PageNav({ href, dir }: { href: string | null; dir: 'prev' | 'next' }) {
  const label = dir === 'prev' ? 'Anterior' : 'Siguiente'
  const Icon = dir === 'prev' ? ArrowLeft : ArrowRight
  const inner = (
    <span className="inline-flex items-center gap-1">
      {dir === 'prev' && <Icon className="w-4 h-4" aria-hidden="true" />}
      {label}
      {dir === 'next' && <Icon className="w-4 h-4" aria-hidden="true" />}
    </span>
  )
  if (!href) {
    return (
      <span className="rounded-lg border border-slate-200 text-slate-300 text-sm font-medium px-3 py-1.5 cursor-not-allowed">
        {inner}
      </span>
    )
  }
  return (
    <Link
      href={href}
      className="rounded-lg border border-slate-300 bg-white text-slate-700 text-sm font-medium px-3 py-1.5 hover:bg-slate-50 transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand-500"
    >
      {inner}
    </Link>
  )
}
