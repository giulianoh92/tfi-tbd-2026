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
  codigo: string
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
    }
    Views: Record<string, never>
    Functions: Record<string, never>
    Enums: Record<string, never>
  }
}
