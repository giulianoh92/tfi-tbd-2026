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

// Tabla general de auditoría (R1). Una unica tabla cubre todas las entidades
// auditadas; el discriminante es la columna `tabla`. `valores_anteriores` y
// `valores_nuevos` son JSONB serializados con `to_jsonb(OLD/NEW)`.
export interface AuditLog {
  id_audit: number
  tabla: string
  id_registro: string | null
  tipo_op: 'I' | 'U' | 'D'
  usuario_db: string
  usuario_app: string | null
  fecha_hora: string
  valores_anteriores: Json | null
  valores_nuevos: Json | null
}

// Tabla historica poblada por pa_detectar_devoluciones_vencidas (Sprint 4 -
// R9) cada 6 horas via pg_cron. La UI staff la lee desde
// /admin/devoluciones-vencidas y toggle `notificado` cuando contacta al
// cliente. INSERT/DELETE estan revocados a authenticated.
export interface DevolucionVencida {
  id_devolucion_vencida: number
  id_alquiler: number
  id_vehiculo: number
  id_cliente: number
  fecha_fin_prevista: string
  fecha_deteccion: string
  horas_excedidas: number
  notificado: boolean
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
      audit_log: {
        Row: AuditLog
        // Insert/Update intencionalmente bloqueados por RLS — solo el
        // trigger fn_audit_generic (SECURITY DEFINER) puede escribir.
        // Los tipos quedan vacios para que TS rechace cualquier intento.
        Insert: never
        Update: never
      }
      devolucion_vencida: {
        Row: DevolucionVencida
        // Insert intencionalmente bloqueado: solo el job
        // pa_detectar_devoluciones_vencidas puede insertar (corre como
        // postgres y bypassea RLS). El staff solo puede actualizar el flag
        // `notificado` desde la UI.
        Insert: never
        Update: Pick<DevolucionVencida, 'notificado'>
      }
    }
    Views: Record<string, never>
    Functions: {
      // Sprint 5 (R2). Cierre de alquiler. Refactor:
      //   * Cuerpo envuelto en BEGIN ... EXCEPTION WHEN ... END.
      //   * Agregados OUT p_estado / p_mensaje / p_id_factura.
      //   * El parametro de entrada antes llamado `p_estado_final_vehiculo`
      //     se renombro a `p_estado_destino_vehiculo` para no colisionar
      //     con el OUT p_estado.
      pa_finalizar_alquiler: {
        Args: {
          p_id_alquiler: number
          p_km_fin: number
          p_id_sucursal_devolucion: number
          p_estado_destino_vehiculo?: string
          p_id_taller?: number | null
          p_observaciones?: string | null
        }
        Returns: {
          p_estado: ProcedureEstado
          p_mensaje: string
          p_id_factura: number | null
        }
      }
      // Sprint 5 (R2). Envia un vehiculo disponible a mantenimiento. El
      // trigger fn_mantenimiento_envio mirrorea estado_vehiculo='en_mantenimiento'.
      pa_enviar_mantenimiento_programado: {
        Args: {
          p_id_vehiculo: number
          p_id_taller: number
          p_observaciones: string | null
        }
        Returns: {
          p_estado: ProcedureEstado
          p_mensaje: string
        }
      }
      // Sprint 5 (R2). Cierra la orden de mantenimiento abierta del vehiculo.
      // El trigger trg_mantenimiento_devolucion restaura estado='disponible'.
      pa_registrar_devolucion_mantenimiento: {
        Args: {
          p_id_vehiculo: number
          p_km_salida_taller?: number | null
        }
        Returns: {
          p_estado: ProcedureEstado
          p_mensaje: string
        }
      }
      // Sprint 5 (R2). Alta atomica de credenciales + perfil de cliente.
      // p_id_generado devuelve el id_usuario creado.
      pa_registrar_cliente_con_usuario: {
        Args: {
          p_username: string
          p_password_hash: string
          p_email: string
          p_nombre: string
          p_apellido: string
          p_dni: string
          p_telefono: string | null
          p_direccion: string | null
        }
        Returns: {
          p_estado: ProcedureEstado
          p_mensaje: string
          p_id_generado: number | null
        }
      }
      // Sprint 2 (R7). Alta de reserva con retorno estandarizado.
      // PostgREST serializa los OUT como un unico objeto JSON.
      pa_registrar_reserva: {
        Args: {
          p_id_cliente: number
          p_id_vehiculo: number
          p_id_tipo_reserva: number
          p_fecha_inicio: string
          p_fecha_fin: string
        }
        Returns: {
          p_estado: ProcedureEstado
          p_mensaje: string
          p_id_generado: number | null
        }
      }
      // Sprint 2 (R8). Cancelacion de reserva. `p_motivo` es INOUT: entra el
      // motivo del usuario, vuelve enriquecido con timestamp + uuid.
      pa_cancelar_reserva: {
        Args: {
          p_id_reserva: number
          p_motivo: string
        }
        Returns: {
          p_estado: ProcedureEstado
          p_mensaje: string
          p_motivo: string
        }
      }
      // Sprint 3 (R3, R6). Alta de alquiler. Soporta dos modalidades:
      //   * con reserva previa: p_id_reserva != null.
      //   * walk-in:           p_id_reserva === null.
      // Los triggers de lifecycle marcan reserva→concretada y vehiculo→
      // alquilado al INSERT en alquiler.
      pa_registrar_alquiler: {
        Args: {
          p_id_reserva: number | null
          p_id_cliente: number
          p_id_vehiculo: number
          p_id_tarifa: number
          p_fecha_inicio: string
          p_fecha_fin: string
          p_km_inicio: number
        }
        Returns: {
          p_estado: ProcedureEstado
          p_mensaje: string
          p_id_generado: number | null
        }
      }
      // Sprint 3 (R3). CRUD vehiculo via SP. El estado inicial 'disponible'
      // lo resuelve el procedure desde el catalogo estado_vehiculo.
      pa_crear_vehiculo: {
        Args: {
          p_id_sucursal_origen: number
          p_id_tipo: number
          p_marca: string
          p_modelo: string
          p_anio: number
          p_patente: string
          p_km_actuales: number
          p_detalle_confort: string | null
        }
        Returns: {
          p_estado: ProcedureEstado
          p_mensaje: string
          p_id_generado: number | null
        }
      }
      pa_actualizar_vehiculo: {
        Args: {
          p_id_vehiculo: number
          p_marca: string
          p_modelo: string
          p_anio: number
          p_detalle_confort: string | null
        }
        Returns: {
          p_estado: ProcedureEstado
          p_mensaje: string
        }
      }
      // Baja "logica": transiciona vehiculo.id_estado a 'baja'. p_motivo es
      // INOUT (vuelve enriquecido con timestamp + uuid del autor).
      pa_baja_vehiculo: {
        Args: {
          p_id_vehiculo: number
          p_motivo: string
        }
        Returns: {
          p_estado: ProcedureEstado
          p_mensaje: string
          p_motivo: string
        }
      }
    }
    Enums: Record<string, never>
  }
}

// Codigos de estado estandarizados que devuelven los procedures de negocio
// (JUSTIFICACION.md §R4). El frontend los mapea a mensajes o flujos UX
// distintos segun el caso.
export type ProcedureEstado =
  | 'OK'
  | 'ERROR_VALIDACION'
  | 'ERROR_DUPLICADO'
  | 'ERROR_REFERENCIAL'
  | 'ERROR_ESTADO'
  | 'ERROR'
