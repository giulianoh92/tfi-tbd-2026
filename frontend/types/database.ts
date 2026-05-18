/**
 * Tipos auto-generados desde el schema de Supabase.
 *
 * STUB — este archivo es un placeholder.
 *
 * Para regenerar con los tipos reales del schema local:
 *   1. Tener `supabase start` corriendo (ver scripts/dev-frontend.sh)
 *   2. Desde la raíz del repo:
 *        supabase gen types typescript --local > frontend/types/database.ts
 *
 * Para regenerar apuntando a Supabase Cloud (proyecto linkeado):
 *        supabase gen types typescript --linked > frontend/types/database.ts
 *
 * Mientras tanto, los tipos abajo son aproximaciones manuales para que
 * el PoC compile. No reflejan constraints ni relaciones exactas.
 */

export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

// ---------------------------------------------------------------------------
// Tablas principales (columnas clave para el PoC)
// ---------------------------------------------------------------------------

export interface Vehiculo {
  id_vehiculo: number
  id_sucursal_origen: number
  id_tipo: number
  id_estado: number
  marca: string
  modelo: string
  anio: number
  patente: string
  km_actuales: number
  detalle_confort: string | null
}

export interface TipoVehiculo {
  id_tipo: number
  nombre: string
  descripcion: string | null
}

export interface EstadoVehiculo {
  id_estado: number
  nombre: string
  descripcion: string | null
}

export interface ImagenVehiculo {
  id_imagen: number
  id_vehiculo: number
  url_imagen: string
  orden: number
}

export interface Tarifa {
  id_tarifa: number
  id_sucursal: number
  id_tipo: number
  precio_por_dia: number
  porcentaje_recargo: number
}

export interface TipoReserva {
  id_tipo_reserva: number
  nombre: string
  descripcion: string | null
  requiere_garantia: boolean
  antelacion_max_dias: number
}

export interface Reserva {
  id_reserva: number
  id_cliente: number
  id_vehiculo: number
  id_tipo_reserva: number
  fecha_inicio: string
  fecha_fin_prevista: string
  estado: 'pendiente' | 'concretada' | 'cancelada'
  fecha_creacion: string
}

export interface Cliente {
  id_cliente: number
  id_usuario: number | null
  nombre: string
  apellido: string
  dni: string
  telefono: string | null
  direccion: string | null
}

export interface Sucursal {
  id_sucursal: number
  nombre: string
  direccion: string | null
  telefono: string | null
}

export interface Alquiler {
  id_alquiler: number
  id_reserva: number | null
  id_cliente: number
  id_vehiculo: number
  id_tarifa: number
  id_sucursal_devolucion: number | null
  fecha_inicio: string
  fecha_fin_prevista: string
  fecha_devolucion_real: string | null
  km_inicio: number
  km_fin: number | null
  estado: 'activo' | 'cerrado'
}

export interface Factura {
  id_factura: number
  id_alquiler: number
  id_cliente: number
  numero_factura: string
  fecha_emision: string
  precio_por_dia_aplicado: number
  porcentaje_recargo_aplicado: number | null
  costo_base: number
  horas_excedidas: number | null
  recargo_excedente: number | null
  total: number
}

// ---------------------------------------------------------------------------
// Tipo genérico de Database para @supabase/ssr
// (estructura mínima que espera el client builder)
// ---------------------------------------------------------------------------

export type Database = {
  public: {
    Tables: {
      vehiculo: {
        Row: Vehiculo
        Insert: Omit<Vehiculo, 'id_vehiculo'>
        Update: Partial<Omit<Vehiculo, 'id_vehiculo'>>
      }
      tipo_vehiculo: {
        Row: TipoVehiculo
        Insert: Omit<TipoVehiculo, 'id_tipo'>
        Update: Partial<Omit<TipoVehiculo, 'id_tipo'>>
      }
      estado_vehiculo: {
        Row: EstadoVehiculo
        Insert: Omit<EstadoVehiculo, 'id_estado'>
        Update: Partial<Omit<EstadoVehiculo, 'id_estado'>>
      }
      imagen_vehiculo: {
        Row: ImagenVehiculo
        Insert: Omit<ImagenVehiculo, 'id_imagen'>
        Update: Partial<Omit<ImagenVehiculo, 'id_imagen'>>
      }
      tarifa: {
        Row: Tarifa
        Insert: Omit<Tarifa, 'id_tarifa'>
        Update: Partial<Omit<Tarifa, 'id_tarifa'>>
      }
      tipo_reserva: {
        Row: TipoReserva
        Insert: Omit<TipoReserva, 'id_tipo_reserva'>
        Update: Partial<Omit<TipoReserva, 'id_tipo_reserva'>>
      }
      reserva: {
        Row: Reserva
        Insert: Omit<Reserva, 'id_reserva' | 'fecha_creacion'>
        Update: Partial<Omit<Reserva, 'id_reserva' | 'fecha_creacion'>>
      }
      cliente: {
        Row: Cliente
        Insert: Omit<Cliente, 'id_cliente'>
        Update: Partial<Omit<Cliente, 'id_cliente'>>
      }
      sucursal: {
        Row: Sucursal
        Insert: Omit<Sucursal, 'id_sucursal'>
        Update: Partial<Omit<Sucursal, 'id_sucursal'>>
      }
      alquiler: {
        Row: Alquiler
        Insert: Omit<Alquiler, 'id_alquiler'>
        Update: Partial<Omit<Alquiler, 'id_alquiler'>>
      }
      factura: {
        Row: Factura
        Insert: Omit<Factura, 'id_factura'>
        Update: Partial<Omit<Factura, 'id_factura'>>
      }
    }
    Views: Record<string, never>
    Functions: {
      pa_finalizar_alquiler: {
        Args: {
          p_id_alquiler: number
          p_km_fin: number
          p_id_sucursal_devolucion: number
          p_estado_final_vehiculo?: string
          p_id_taller?: number | null
          p_observaciones?: string | null
        }
        Returns: void
      }
    }
    Enums: Record<string, never>
  }
}
