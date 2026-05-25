'use client'

import { useEffect, useMemo, useState } from 'react'
import { useRouter } from 'next/navigation'
import { createClient } from '@/lib/supabase/client'
import type { Cliente, Reserva, Sucursal, Vehiculo } from '@/types/database'
import type {
  TarifaEnriquecida,
  UbicacionVigente,
  VehiculoLite,
} from '@/app/admin/alquileres/nuevo/page'
import { Card } from '@/components/ui/Card'
import { Button } from '@/components/ui/Button'
import { Input } from '@/components/ui/Input'
import { Label } from '@/components/ui/Label'
import { Combobox } from '@/components/ui/Combobox'
import { formatARS, formatDateTimeAR } from '@/lib/format'
import { cn } from '@/lib/cn'

interface ReservaPendiente
  extends Pick<Reserva, 'id_reserva' | 'id_cliente' | 'id_vehiculo' | 'fecha_inicio' | 'fecha_fin_prevista'> {
  cliente: Pick<Cliente, 'nombre' | 'apellido' | 'dni'> | null
  vehiculo: Pick<Vehiculo, 'marca' | 'modelo' | 'patente' | 'km_actuales'> | null
}

interface Props {
  reservasPendientes: ReservaPendiente[]
  clientes: Pick<Cliente, 'id_cliente' | 'nombre' | 'apellido' | 'dni'>[]
  vehiculos: VehiculoLite[]
  tarifas: TarifaEnriquecida[]
  sucursales: Sucursal[]
  ubicacionesVigentes: UbicacionVigente[]
}

type Modo = 'con_reserva' | 'walk_in'

/**
 * Formulario de alta de alquiler.
 *
 * Sprint 3 (R3, R6): invoca `pa_registrar_alquiler` via RPC, soportando
 * ambas modalidades (con reserva previa / walk-in).
 *
 * Sprint 6 hotfix UX:
 *   1. Cliente walk-in inline: boton "+ Crear cliente nuevo" expande un
 *      sub-form en la misma Card y llama `pa_registrar_cliente_walkin`.
 *      No usa Dialog ni modal — preserva el contexto del flujo de alquiler.
 *   2. Sucursal de retiro como primer campo: filtra los vehiculos por
 *      ubicacion vigente (`ubicacion_vehiculo.fecha_hasta IS NULL`). En la
 *      rama "con reserva" valida que el vehiculo de la reserva este en la
 *      sucursal elegida (warning + bloqueo de submit).
 *   3. Tarifa derivada automaticamente del vehiculo. Se busca la unica
 *      tarifa que matchea (vehiculo.id_sucursal_origen, vehiculo.id_tipo)
 *      — la tarifa la fija la flota, no la sucursal de retiro.
 *
 * Para walk-in se setea fecha_inicio con 1 minuto de gracia sobre el "ahora"
 * del navegador, porque fn_validar_periodo exige p_fecha_inicio > NOW().
 */
export function NuevoAlquilerForm({
  reservasPendientes,
  clientes: clientesInicial,
  vehiculos,
  tarifas,
  sucursales,
  ubicacionesVigentes,
}: Props) {
  const supabase = createClient()
  const router = useRouter()

  const [modo, setModo] = useState<Modo>('con_reserva')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  // Lista de clientes mutable — se actualiza tras crear walk-in.
  const [clientes, setClientes] = useState(clientesInicial)

  // --- Sucursal de retiro (comun a ambas ramas) ---
  const [idSucursal, setIdSucursal] = useState<number | null>(
    sucursales[0]?.id_sucursal ?? null
  )

  // --- Rama "con reserva" ---
  const [idReserva, setIdReserva] = useState<number | null>(
    reservasPendientes[0]?.id_reserva ?? null
  )

  // --- Rama "walk-in" ---
  const ahoraIso = isoLocalDt(new Date(Date.now() + 60_000)) // +1 minuto
  const en24hIso = isoLocalDt(new Date(Date.now() + 86_400_000 + 60_000))
  const [idClienteW, setIdClienteW] = useState<number | null>(null)
  const [idVehiculoW, setIdVehiculoW] = useState<number | null>(null)
  const [fechaInicioW, setFechaInicioW] = useState<string>(ahoraIso)
  const [fechaFinW, setFechaFinW] = useState<string>(en24hIso)

  // --- Sub-form de alta walk-in ---
  const [showAltaCliente, setShowAltaCliente] = useState(false)
  const [altaLoading, setAltaLoading] = useState(false)
  const [altaError, setAltaError] = useState<string | null>(null)
  const [altaDni, setAltaDni] = useState('')
  const [altaNombre, setAltaNombre] = useState('')
  const [altaApellido, setAltaApellido] = useState('')
  const [altaTelefono, setAltaTelefono] = useState('')
  const [altaDireccion, setAltaDireccion] = useState('')

  // --- Km inicio ---
  const [kmInicio, setKmInicio] = useState<string>('')

  // Index ubicaciones vigentes: id_vehiculo -> id_sucursal.
  const ubicacionPorVehiculo = useMemo(() => {
    const map = new Map<number, number>()
    for (const u of ubicacionesVigentes) {
      map.set(u.id_vehiculo, u.id_sucursal)
    }
    return map
  }, [ubicacionesVigentes])

  // Vehiculos filtrados por sucursal elegida (rama walk-in).
  const vehiculosEnSucursal = useMemo(() => {
    if (idSucursal == null) return []
    return vehiculos.filter(
      (v) => ubicacionPorVehiculo.get(v.id_vehiculo) === idSucursal
    )
  }, [vehiculos, ubicacionPorVehiculo, idSucursal])

  // Si la sucursal cambia y el vehiculo elegido ya no esta ahi -> resetear.
  useEffect(() => {
    if (idVehiculoW == null) return
    if (!vehiculosEnSucursal.some((v) => v.id_vehiculo === idVehiculoW)) {
      setIdVehiculoW(null)
      setKmInicio('')
    }
  }, [vehiculosEnSucursal, idVehiculoW])

  // Reserva seleccionada (rama con reserva).
  const reservaSel = useMemo(
    () => reservasPendientes.find((r) => r.id_reserva === idReserva) ?? null,
    [reservasPendientes, idReserva]
  )

  // Vehiculo activo segun la modalidad (para derivar tarifa + validar sucursal).
  const vehiculoActivo: VehiculoLite | null = useMemo(() => {
    if (modo === 'con_reserva') {
      if (!reservaSel) return null
      return (
        vehiculos.find((v) => v.id_vehiculo === reservaSel.id_vehiculo) ?? null
      )
    }
    return vehiculos.find((v) => v.id_vehiculo === idVehiculoW) ?? null
  }, [modo, reservaSel, idVehiculoW, vehiculos])

  // Tarifa derivada: la unica que matchea (id_sucursal_origen, id_tipo) del
  // vehiculo activo. Hay UNIQUE constraint (id_sucursal, id_tipo) en tarifa.
  const tarifaAplicable = useMemo(() => {
    if (!vehiculoActivo) return null
    return (
      tarifas.find(
        (t) =>
          t.id_sucursal === vehiculoActivo.id_sucursal_origen &&
          t.id_tipo === vehiculoActivo.id_tipo
      ) ?? null
    )
  }, [tarifas, vehiculoActivo])

  // Sucursal donde esta fisicamente el vehiculo (segun ubicacion vigente).
  const sucursalActualVehiculo = useMemo(() => {
    if (!vehiculoActivo) return null
    const idSuc = ubicacionPorVehiculo.get(vehiculoActivo.id_vehiculo)
    if (idSuc == null) return null
    return sucursales.find((s) => s.id_sucursal === idSuc) ?? null
  }, [vehiculoActivo, ubicacionPorVehiculo, sucursales])

  // Warning rama "con reserva": si la sucursal elegida no matchea con la
  // ubicacion actual del vehiculo reservado -> mostrar y bloquear submit.
  const mismatchSucursalReserva =
    modo === 'con_reserva' &&
    reservaSel != null &&
    idSucursal != null &&
    sucursalActualVehiculo != null &&
    sucursalActualVehiculo.id_sucursal !== idSucursal

  // Items para Combobox
  const sucursalItems = useMemo(
    () =>
      sucursales.map((s) => ({
        value: s.id_sucursal,
        label: s.nombre,
        hint: s.ciudad,
      })),
    [sucursales]
  )

  const reservaItems = useMemo(
    () =>
      reservasPendientes.map((r) => ({
        value: r.id_reserva,
        label: `#${r.id_reserva} — ${
          r.cliente ? `${r.cliente.nombre} ${r.cliente.apellido}` : `Cliente ${r.id_cliente}`
        }`,
        hint: `${
          r.vehiculo
            ? `${r.vehiculo.marca} ${r.vehiculo.modelo} (${r.vehiculo.patente})`
            : `Vehiculo ${r.id_vehiculo}`
        } — ${formatDateTimeAR(r.fecha_inicio)} a ${formatDateTimeAR(r.fecha_fin_prevista)}`,
      })),
    [reservasPendientes]
  )

  const clienteItems = useMemo(
    () =>
      clientes.map((c) => ({
        value: c.id_cliente,
        label: `${c.nombre} ${c.apellido}`,
        hint: `DNI ${c.dni}`,
      })),
    [clientes]
  )

  const vehiculoItems = useMemo(
    () =>
      vehiculosEnSucursal.map((v) => ({
        value: v.id_vehiculo,
        label: `${v.marca} ${v.modelo} (${v.patente})`,
        hint: `${v.km_actuales.toLocaleString('es-AR')} km`,
      })),
    [vehiculosEnSucursal]
  )

  function resetAltaForm() {
    setAltaDni('')
    setAltaNombre('')
    setAltaApellido('')
    setAltaTelefono('')
    setAltaDireccion('')
    setAltaError(null)
  }

  async function handleCrearCliente() {
    setAltaError(null)

    if (!altaDni.trim() || !altaNombre.trim() || !altaApellido.trim()) {
      setAltaError('DNI, nombre y apellido son obligatorios.')
      return
    }

    setAltaLoading(true)
    const { data, error: rpcError } = await supabase.rpc(
      'pa_registrar_cliente_walkin',
      {
        p_dni: altaDni.trim(),
        p_nombre: altaNombre.trim(),
        p_apellido: altaApellido.trim(),
        p_telefono: altaTelefono.trim() || undefined,
        p_direccion: altaDireccion.trim() || undefined,
      }
    )

    if (rpcError) {
      setAltaError(rpcError.message)
      setAltaLoading(false)
      return
    }

    const result = data as
      | { p_estado: string; p_mensaje: string; p_id_generado: number | null }
      | null

    if (!result || result.p_estado !== 'OK' || result.p_id_generado == null) {
      setAltaError(result?.p_mensaje ?? 'No se pudo crear el cliente.')
      setAltaLoading(false)
      return
    }

    // Insertar en la lista local y seleccionar.
    const nuevo = {
      id_cliente: result.p_id_generado,
      nombre: altaNombre.trim(),
      apellido: altaApellido.trim(),
      dni: altaDni.trim(),
    }
    setClientes((prev) =>
      [...prev, nuevo].sort((a, b) => a.apellido.localeCompare(b.apellido))
    )
    setIdClienteW(result.p_id_generado)
    setShowAltaCliente(false)
    setAltaLoading(false)
    resetAltaForm()
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    setError(null)

    if (idSucursal == null) {
      setError('Seleccioná la sucursal de retiro.')
      return
    }

    const kmInicioNum = parseInt(kmInicio, 10)
    if (isNaN(kmInicioNum) || kmInicioNum < 0) {
      setError('Ingresá un kilometraje inicial valido (mayor o igual a 0).')
      return
    }

    if (!tarifaAplicable) {
      setError(
        'No hay tarifa configurada para el vehiculo elegido. Avisar al admin.'
      )
      return
    }

    if (mismatchSucursalReserva) {
      setError(
        'El vehiculo de la reserva no esta en la sucursal de retiro elegida.'
      )
      return
    }

    let args: {
      p_id_reserva: number | null
      p_id_cliente: number
      p_id_vehiculo: number
      p_id_tarifa: number
      p_fecha_inicio: string
      p_fecha_fin: string
      p_km_inicio: number
    }

    if (modo === 'con_reserva') {
      if (idReserva == null || !reservaSel) {
        setError('Seleccioná una reserva.')
        return
      }
      args = {
        p_id_reserva: idReserva,
        p_id_cliente: reservaSel.id_cliente,
        p_id_vehiculo: reservaSel.id_vehiculo,
        p_id_tarifa: tarifaAplicable.id_tarifa,
        p_fecha_inicio: reservaSel.fecha_inicio,
        p_fecha_fin: reservaSel.fecha_fin_prevista,
        p_km_inicio: kmInicioNum,
      }
    } else {
      if (idClienteW == null || idVehiculoW == null) {
        setError('Seleccioná cliente y vehiculo.')
        return
      }
      if (new Date(fechaFinW) <= new Date(fechaInicioW)) {
        setError('La fecha de fin debe ser posterior a la de inicio.')
        return
      }
      args = {
        p_id_reserva: null,
        p_id_cliente: idClienteW,
        p_id_vehiculo: idVehiculoW,
        p_id_tarifa: tarifaAplicable.id_tarifa,
        p_fecha_inicio: fechaInicioW,
        p_fecha_fin: fechaFinW,
        p_km_inicio: kmInicioNum,
      }
    }

    setLoading(true)
    const { data, error: rpcError } = await supabase.rpc(
      'pa_registrar_alquiler',
      args,
    )

    if (rpcError) {
      setError(rpcError.message)
      setLoading(false)
      return
    }

    const result = data as
      | { p_estado: string; p_mensaje: string; p_id_generado: number | null }
      | null

    if (!result || result.p_estado !== 'OK') {
      setError(result?.p_mensaje ?? 'No se pudo registrar el alquiler.')
      setLoading(false)
      return
    }

    router.push('/admin/alquileres')
    router.refresh()
  }

  const submitDisabled =
    loading ||
    idSucursal == null ||
    !tarifaAplicable ||
    mismatchSucursalReserva

  return (
    <Card variant="raised" className="p-6">
      <form onSubmit={handleSubmit} className="flex flex-col gap-5" noValidate>
        {/* Sucursal de retiro — primer campo, comun a ambas ramas */}
        <div>
          <Label htmlFor="sucursal" required>Sucursal de retiro</Label>
          <Combobox
            id="sucursal"
            items={sucursalItems}
            value={idSucursal}
            onChange={setIdSucursal}
            placeholder="Seleccioná una sucursal..."
            searchPlaceholder="Buscar sucursal..."
          />
          <p className="mt-1 text-xs text-muted-fg">
            Solo se listan vehiculos fisicamente en esta sucursal.
          </p>
        </div>

        {/* Toggle de modalidad */}
        <div role="tablist" aria-label="Modalidad de alquiler" className="flex gap-1 bg-slate-100 rounded-lg p-1">
          <ModeButton active={modo === 'con_reserva'} onClick={() => setModo('con_reserva')}>
            Con reserva previa
          </ModeButton>
          <ModeButton active={modo === 'walk_in'} onClick={() => setModo('walk_in')}>
            Sin reserva (walk-in)
          </ModeButton>
        </div>

        {/* Rama "con reserva" */}
        {modo === 'con_reserva' && (
          <div>
            <Label htmlFor="reserva" required>Reserva pendiente</Label>
            {reservasPendientes.length === 0 ? (
              <p className="text-sm text-muted-fg italic">
                No hay reservas pendientes. Usá modo walk-in.
              </p>
            ) : (
              <Combobox
                id="reserva"
                items={reservaItems}
                value={idReserva}
                onChange={setIdReserva}
                placeholder="Seleccioná una reserva..."
                searchPlaceholder="Buscar por nombre, vehiculo o id..."
              />
            )}

            {mismatchSucursalReserva && sucursalActualVehiculo && (
              <div
                role="alert"
                className="mt-2 rounded-lg bg-warning-bg border border-warning-border p-3"
              >
                <p className="text-warning-fg text-sm">
                  El vehiculo reservado esta actualmente en{' '}
                  <strong>{sucursalActualVehiculo.nombre}</strong>, no en la
                  sucursal de retiro elegida. Cambiá la sucursal o coordiná el
                  traslado del vehiculo antes de registrar el alquiler.
                </p>
              </div>
            )}
          </div>
        )}

        {/* Rama "walk-in" */}
        {modo === 'walk_in' && (
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div className="sm:col-span-2">
              <div className="flex items-center justify-between gap-2 mb-1">
                <Label htmlFor="cliente" required className="mb-0">Cliente</Label>
                {!showAltaCliente && (
                  <Button
                    type="button"
                    variant="link"
                    size="sm"
                    onClick={() => setShowAltaCliente(true)}
                  >
                    + Crear cliente nuevo
                  </Button>
                )}
              </div>
              <Combobox
                id="cliente"
                items={clienteItems}
                value={idClienteW}
                onChange={setIdClienteW}
                placeholder="Seleccioná un cliente..."
                searchPlaceholder="Buscar por nombre o DNI..."
                disabled={showAltaCliente}
              />
            </div>

            {/* Sub-form de alta inline */}
            {showAltaCliente && (
              <div className="sm:col-span-2 rounded-lg border border-slate-200 bg-slate-50 p-4">
                <h3 className="font-display text-sm font-semibold text-slate-900 mb-3">
                  Nuevo cliente walk-in
                </h3>
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                  <div>
                    <Label htmlFor="alta_dni" required>DNI</Label>
                    <Input
                      id="alta_dni"
                      value={altaDni}
                      onChange={(e) => setAltaDni(e.target.value)}
                      placeholder="12345678"
                      autoComplete="off"
                    />
                  </div>
                  <div>
                    <Label htmlFor="alta_telefono">Telefono</Label>
                    <Input
                      id="alta_telefono"
                      value={altaTelefono}
                      onChange={(e) => setAltaTelefono(e.target.value)}
                      placeholder="3764..."
                      autoComplete="off"
                    />
                  </div>
                  <div>
                    <Label htmlFor="alta_nombre" required>Nombre</Label>
                    <Input
                      id="alta_nombre"
                      value={altaNombre}
                      onChange={(e) => setAltaNombre(e.target.value)}
                      autoComplete="off"
                    />
                  </div>
                  <div>
                    <Label htmlFor="alta_apellido" required>Apellido</Label>
                    <Input
                      id="alta_apellido"
                      value={altaApellido}
                      onChange={(e) => setAltaApellido(e.target.value)}
                      autoComplete="off"
                    />
                  </div>
                  <div className="sm:col-span-2">
                    <Label htmlFor="alta_direccion">Direccion</Label>
                    <Input
                      id="alta_direccion"
                      value={altaDireccion}
                      onChange={(e) => setAltaDireccion(e.target.value)}
                      autoComplete="off"
                    />
                  </div>
                </div>

                {altaError && (
                  <div
                    role="alert"
                    className="mt-3 rounded-md bg-danger-bg border border-danger-border p-2"
                  >
                    <p className="text-danger-fg text-xs">{altaError}</p>
                  </div>
                )}

                <div className="flex gap-2 mt-4">
                  <Button
                    type="button"
                    variant="primary"
                    size="sm"
                    loading={altaLoading}
                    onClick={handleCrearCliente}
                  >
                    Crear y seleccionar
                  </Button>
                  <Button
                    type="button"
                    variant="ghost"
                    size="sm"
                    disabled={altaLoading}
                    onClick={() => {
                      setShowAltaCliente(false)
                      resetAltaForm()
                    }}
                  >
                    Cancelar
                  </Button>
                </div>
              </div>
            )}

            <div className="sm:col-span-2">
              <Label htmlFor="vehiculo" required>Vehiculo disponible</Label>
              <Combobox
                id="vehiculo"
                items={vehiculoItems}
                value={idVehiculoW}
                onChange={(val) => {
                  setIdVehiculoW(val)
                  const v = vehiculos.find((x) => x.id_vehiculo === val)
                  if (v) setKmInicio(v.km_actuales.toString())
                }}
                placeholder={
                  idSucursal == null
                    ? 'Elegi sucursal primero'
                    : vehiculoItems.length === 0
                      ? 'Sin vehiculos disponibles en esta sucursal'
                      : 'Seleccioná un vehiculo...'
                }
                searchPlaceholder="Buscar por marca, modelo o patente..."
                disabled={idSucursal == null || vehiculoItems.length === 0}
              />
            </div>

            <div>
              <Label htmlFor="fecha_inicio" required>Fecha y hora de inicio</Label>
              <Input
                id="fecha_inicio"
                type="datetime-local"
                required
                value={fechaInicioW}
                onChange={(e) => setFechaInicioW(e.target.value)}
              />
            </div>

            <div>
              <Label htmlFor="fecha_fin" required>Fecha y hora de fin</Label>
              <Input
                id="fecha_fin"
                type="datetime-local"
                required
                value={fechaFinW}
                onChange={(e) => setFechaFinW(e.target.value)}
              />
            </div>
          </div>
        )}

        {/* Tarifa derivada (read-only) + km — comunes */}
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
          <div>
            <Label>Tarifa aplicable</Label>
            <div
              aria-live="polite"
              className={cn(
                'rounded-lg border px-3 py-2 text-sm',
                tarifaAplicable
                  ? 'bg-slate-50 border-slate-200 text-slate-800'
                  : vehiculoActivo
                    ? 'bg-warning-bg border-warning-border text-warning-fg'
                    : 'bg-slate-50 border-slate-200 text-muted-fg italic'
              )}
            >
              {tarifaAplicable ? (
                <>
                  <span className="font-medium">
                    {tarifaAplicable.tipo_vehiculo?.nombre ?? `Tipo ${tarifaAplicable.id_tipo}`}
                    {' / '}
                    {tarifaAplicable.sucursal?.nombre ?? `Sucursal ${tarifaAplicable.id_sucursal}`}
                  </span>{' '}
                  — {formatARS(Number(tarifaAplicable.precio_por_dia))} / dia
                  <span className="text-xs text-muted-fg block mt-0.5">
                    Recargo por hora excedida:{' '}
                    {Number(tarifaAplicable.porcentaje_recargo).toFixed(2)}%
                  </span>
                </>
              ) : vehiculoActivo ? (
                'No hay tarifa configurada para este vehiculo. Avisar al admin.'
              ) : (
                'Elegi un vehiculo para ver la tarifa.'
              )}
            </div>
          </div>

          <div>
            <Label htmlFor="km_inicio" required>Km al inicio</Label>
            <Input
              id="km_inicio"
              type="number"
              min={0}
              step={1}
              required
              value={kmInicio}
              onChange={(e) => setKmInicio(e.target.value)}
              placeholder="0"
            />
          </div>
        </div>

        {error && (
          <div
            role="alert"
            className="rounded-lg bg-danger-bg border border-danger-border p-3"
          >
            <p className="text-danger-fg text-sm">{error}</p>
          </div>
        )}

        <Button
          type="submit"
          variant="primary"
          loading={loading}
          disabled={submitDisabled}
          className="w-full"
        >
          {loading ? 'Registrando...' : 'Registrar alquiler'}
        </Button>
      </form>
    </Card>
  )
}

function ModeButton({
  active,
  onClick,
  children,
}: {
  active: boolean
  onClick: () => void
  children: React.ReactNode
}) {
  return (
    <button
      type="button"
      role="tab"
      aria-selected={active}
      onClick={onClick}
      className={cn(
        'flex-1 py-2 text-sm font-medium rounded-md transition-colors',
        'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-brand-500',
        active
          ? 'bg-white text-brand-700 shadow-sm'
          : 'text-slate-600 hover:text-slate-900'
      )}
    >
      {children}
    </button>
  )
}

// Formatea Date a "YYYY-MM-DDTHH:mm" en hora local para datetime-local inputs.
function isoLocalDt(d: Date): string {
  const pad = (n: number) => String(n).padStart(2, '0')
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}T${pad(d.getHours())}:${pad(d.getMinutes())}`
}
