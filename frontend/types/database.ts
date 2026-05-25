export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type Database = {
  // Allows to automatically instantiate createClient with right options
  // instead of createClient<Database, { PostgrestVersion: 'XX' }>(URL, KEY)
  __InternalSupabase: {
    PostgrestVersion: "14.4"
  }
  public: {
    Tables: {
      alquiler: {
        Row: {
          estado: string
          fecha_devolucion_real: string | null
          fecha_fin_prevista: string
          fecha_inicio: string
          id_alquiler: number
          id_cliente: number
          id_reserva: number | null
          id_sucursal_devolucion: number | null
          id_tarifa: number
          id_vehiculo: number
          km_fin: number | null
          km_inicio: number
        }
        Insert: {
          estado?: string
          fecha_devolucion_real?: string | null
          fecha_fin_prevista: string
          fecha_inicio: string
          id_alquiler?: number
          id_cliente: number
          id_reserva?: number | null
          id_sucursal_devolucion?: number | null
          id_tarifa: number
          id_vehiculo: number
          km_fin?: number | null
          km_inicio: number
        }
        Update: {
          estado?: string
          fecha_devolucion_real?: string | null
          fecha_fin_prevista?: string
          fecha_inicio?: string
          id_alquiler?: number
          id_cliente?: number
          id_reserva?: number | null
          id_sucursal_devolucion?: number | null
          id_tarifa?: number
          id_vehiculo?: number
          km_fin?: number | null
          km_inicio?: number
        }
        Relationships: [
          {
            foreignKeyName: "fk_alquiler_cliente"
            columns: ["id_cliente"]
            isOneToOne: false
            referencedRelation: "cliente"
            referencedColumns: ["id_cliente"]
          },
          {
            foreignKeyName: "fk_alquiler_reserva"
            columns: ["id_reserva"]
            isOneToOne: true
            referencedRelation: "reserva"
            referencedColumns: ["id_reserva"]
          },
          {
            foreignKeyName: "fk_alquiler_sucursal_devolucion"
            columns: ["id_sucursal_devolucion"]
            isOneToOne: false
            referencedRelation: "sucursal"
            referencedColumns: ["id_sucursal"]
          },
          {
            foreignKeyName: "fk_alquiler_tarifa"
            columns: ["id_tarifa"]
            isOneToOne: false
            referencedRelation: "tarifa"
            referencedColumns: ["id_tarifa"]
          },
          {
            foreignKeyName: "fk_alquiler_vehiculo"
            columns: ["id_vehiculo"]
            isOneToOne: false
            referencedRelation: "vehiculo"
            referencedColumns: ["id_vehiculo"]
          },
        ]
      }
      audit_log: {
        Row: {
          fecha_hora: string
          id_audit: number
          id_registro: string | null
          rol_sesion: string
          tabla: string
          tipo_op: string
          usuario_app: string | null
          usuario_db: string
          valores_anteriores: Json | null
          valores_nuevos: Json | null
        }
        Insert: {
          fecha_hora?: string
          id_audit?: number
          id_registro?: string | null
          rol_sesion: string
          tabla: string
          tipo_op: string
          usuario_app?: string | null
          usuario_db: string
          valores_anteriores?: Json | null
          valores_nuevos?: Json | null
        }
        Update: {
          fecha_hora?: string
          id_audit?: number
          id_registro?: string | null
          rol_sesion?: string
          tabla?: string
          tipo_op?: string
          usuario_app?: string | null
          usuario_db?: string
          valores_anteriores?: Json | null
          valores_nuevos?: Json | null
        }
        Relationships: []
      }
      cliente: {
        Row: {
          apellido: string
          auth_user_id: string | null
          direccion: string | null
          dni: string
          id_cliente: number
          id_usuario: number | null
          nombre: string
          telefono: string | null
        }
        Insert: {
          apellido: string
          auth_user_id?: string | null
          direccion?: string | null
          dni: string
          id_cliente?: number
          id_usuario?: number | null
          nombre: string
          telefono?: string | null
        }
        Update: {
          apellido?: string
          auth_user_id?: string | null
          direccion?: string | null
          dni?: string
          id_cliente?: number
          id_usuario?: number | null
          nombre?: string
          telefono?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "fk_cliente_usuario"
            columns: ["id_usuario"]
            isOneToOne: true
            referencedRelation: "usuario"
            referencedColumns: ["id_usuario"]
          },
        ]
      }
      devolucion_vencida: {
        Row: {
          fecha_deteccion: string
          fecha_fin_prevista: string
          horas_excedidas: number
          id_alquiler: number
          id_cliente: number
          id_devolucion_vencida: number
          id_vehiculo: number
          notificado: boolean
        }
        Insert: {
          fecha_deteccion?: string
          fecha_fin_prevista: string
          horas_excedidas?: number
          id_alquiler: number
          id_cliente: number
          id_devolucion_vencida?: number
          id_vehiculo: number
          notificado?: boolean
        }
        Update: {
          fecha_deteccion?: string
          fecha_fin_prevista?: string
          horas_excedidas?: number
          id_alquiler?: number
          id_cliente?: number
          id_devolucion_vencida?: number
          id_vehiculo?: number
          notificado?: boolean
        }
        Relationships: [
          {
            foreignKeyName: "fk_devolucion_vencida_alquiler"
            columns: ["id_alquiler"]
            isOneToOne: true
            referencedRelation: "alquiler"
            referencedColumns: ["id_alquiler"]
          },
          {
            foreignKeyName: "fk_devolucion_vencida_cliente"
            columns: ["id_cliente"]
            isOneToOne: false
            referencedRelation: "cliente"
            referencedColumns: ["id_cliente"]
          },
          {
            foreignKeyName: "fk_devolucion_vencida_vehiculo"
            columns: ["id_vehiculo"]
            isOneToOne: false
            referencedRelation: "vehiculo"
            referencedColumns: ["id_vehiculo"]
          },
        ]
      }
      estado_vehiculo: {
        Row: {
          descripcion: string | null
          id_estado: number
          nombre: string
        }
        Insert: {
          descripcion?: string | null
          id_estado?: number
          nombre: string
        }
        Update: {
          descripcion?: string | null
          id_estado?: number
          nombre?: string
        }
        Relationships: []
      }
      factura: {
        Row: {
          costo_base: number
          fecha_emision: string
          horas_excedidas: number
          id_alquiler: number
          id_cliente: number
          id_factura: number
          numero_factura: string
          porcentaje_recargo_aplicado: number
          precio_por_dia_aplicado: number
          recargo_excedente: number
          total: number
        }
        Insert: {
          costo_base: number
          fecha_emision?: string
          horas_excedidas?: number
          id_alquiler: number
          id_cliente: number
          id_factura?: number
          numero_factura: string
          porcentaje_recargo_aplicado: number
          precio_por_dia_aplicado: number
          recargo_excedente?: number
          total: number
        }
        Update: {
          costo_base?: number
          fecha_emision?: string
          horas_excedidas?: number
          id_alquiler?: number
          id_cliente?: number
          id_factura?: number
          numero_factura?: string
          porcentaje_recargo_aplicado?: number
          precio_por_dia_aplicado?: number
          recargo_excedente?: number
          total?: number
        }
        Relationships: [
          {
            foreignKeyName: "fk_factura_alquiler"
            columns: ["id_alquiler"]
            isOneToOne: true
            referencedRelation: "alquiler"
            referencedColumns: ["id_alquiler"]
          },
          {
            foreignKeyName: "fk_factura_cliente"
            columns: ["id_cliente"]
            isOneToOne: false
            referencedRelation: "cliente"
            referencedColumns: ["id_cliente"]
          },
        ]
      }
      garantia_reserva: {
        Row: {
          activa: boolean
          fecha_registro: string
          id_garantia: number
          id_reserva: number
          numero_tarjeta_hash: string
          tipo: string
          titular: string
          vencimiento: string
        }
        Insert: {
          activa?: boolean
          fecha_registro?: string
          id_garantia?: number
          id_reserva: number
          numero_tarjeta_hash: string
          tipo: string
          titular: string
          vencimiento: string
        }
        Update: {
          activa?: boolean
          fecha_registro?: string
          id_garantia?: number
          id_reserva?: number
          numero_tarjeta_hash?: string
          tipo?: string
          titular?: string
          vencimiento?: string
        }
        Relationships: [
          {
            foreignKeyName: "fk_garantia_reserva"
            columns: ["id_reserva"]
            isOneToOne: false
            referencedRelation: "reserva"
            referencedColumns: ["id_reserva"]
          },
        ]
      }
      historial_estado_vehiculo: {
        Row: {
          fecha_fin: string | null
          fecha_inicio: string
          id_estado: number
          id_historial: number
          id_vehiculo: number
          motivo: string | null
        }
        Insert: {
          fecha_fin?: string | null
          fecha_inicio: string
          id_estado: number
          id_historial?: number
          id_vehiculo: number
          motivo?: string | null
        }
        Update: {
          fecha_fin?: string | null
          fecha_inicio?: string
          id_estado?: number
          id_historial?: number
          id_vehiculo?: number
          motivo?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "fk_historial_estado"
            columns: ["id_estado"]
            isOneToOne: false
            referencedRelation: "estado_vehiculo"
            referencedColumns: ["id_estado"]
          },
          {
            foreignKeyName: "fk_historial_vehiculo"
            columns: ["id_vehiculo"]
            isOneToOne: false
            referencedRelation: "vehiculo"
            referencedColumns: ["id_vehiculo"]
          },
        ]
      }
      imagen_vehiculo: {
        Row: {
          id_imagen: number
          id_vehiculo: number
          orden: number
          url_imagen: string
        }
        Insert: {
          id_imagen?: number
          id_vehiculo: number
          orden: number
          url_imagen: string
        }
        Update: {
          id_imagen?: number
          id_vehiculo?: number
          orden?: number
          url_imagen?: string
        }
        Relationships: [
          {
            foreignKeyName: "fk_imagen_vehiculo_vehiculo"
            columns: ["id_vehiculo"]
            isOneToOne: false
            referencedRelation: "vehiculo"
            referencedColumns: ["id_vehiculo"]
          },
        ]
      }
      mantenimiento: {
        Row: {
          fecha_devolucion: string | null
          fecha_envio: string
          id_mantenimiento: number
          id_taller: number
          id_vehiculo: number
          observaciones: string | null
        }
        Insert: {
          fecha_devolucion?: string | null
          fecha_envio: string
          id_mantenimiento?: number
          id_taller: number
          id_vehiculo: number
          observaciones?: string | null
        }
        Update: {
          fecha_devolucion?: string | null
          fecha_envio?: string
          id_mantenimiento?: number
          id_taller?: number
          id_vehiculo?: number
          observaciones?: string | null
        }
        Relationships: [
          {
            foreignKeyName: "fk_mantenimiento_taller"
            columns: ["id_taller"]
            isOneToOne: false
            referencedRelation: "taller"
            referencedColumns: ["id_taller"]
          },
          {
            foreignKeyName: "fk_mantenimiento_vehiculo"
            columns: ["id_vehiculo"]
            isOneToOne: false
            referencedRelation: "vehiculo"
            referencedColumns: ["id_vehiculo"]
          },
        ]
      }
      reserva: {
        Row: {
          estado: string
          fecha_creacion: string
          fecha_fin_prevista: string
          fecha_inicio: string
          id_cliente: number
          id_reserva: number
          id_tipo_reserva: number
          id_vehiculo: number
        }
        Insert: {
          estado?: string
          fecha_creacion?: string
          fecha_fin_prevista: string
          fecha_inicio: string
          id_cliente: number
          id_reserva?: number
          id_tipo_reserva: number
          id_vehiculo: number
        }
        Update: {
          estado?: string
          fecha_creacion?: string
          fecha_fin_prevista?: string
          fecha_inicio?: string
          id_cliente?: number
          id_reserva?: number
          id_tipo_reserva?: number
          id_vehiculo?: number
        }
        Relationships: [
          {
            foreignKeyName: "fk_reserva_cliente"
            columns: ["id_cliente"]
            isOneToOne: false
            referencedRelation: "cliente"
            referencedColumns: ["id_cliente"]
          },
          {
            foreignKeyName: "fk_reserva_tipo"
            columns: ["id_tipo_reserva"]
            isOneToOne: false
            referencedRelation: "tipo_reserva"
            referencedColumns: ["id_tipo_reserva"]
          },
          {
            foreignKeyName: "fk_reserva_vehiculo"
            columns: ["id_vehiculo"]
            isOneToOne: false
            referencedRelation: "vehiculo"
            referencedColumns: ["id_vehiculo"]
          },
        ]
      }
      sucursal: {
        Row: {
          ciudad: string
          direccion: string
          id_sucursal: number
          nombre: string
          telefono: string | null
        }
        Insert: {
          ciudad: string
          direccion: string
          id_sucursal?: number
          nombre: string
          telefono?: string | null
        }
        Update: {
          ciudad?: string
          direccion?: string
          id_sucursal?: number
          nombre?: string
          telefono?: string | null
        }
        Relationships: []
      }
      taller: {
        Row: {
          direccion: string
          id_taller: number
          nombre: string
          telefono: string | null
        }
        Insert: {
          direccion: string
          id_taller?: number
          nombre: string
          telefono?: string | null
        }
        Update: {
          direccion?: string
          id_taller?: number
          nombre?: string
          telefono?: string | null
        }
        Relationships: []
      }
      tarifa: {
        Row: {
          id_sucursal: number
          id_tarifa: number
          id_tipo: number
          porcentaje_recargo: number
          precio_por_dia: number
        }
        Insert: {
          id_sucursal: number
          id_tarifa?: number
          id_tipo: number
          porcentaje_recargo: number
          precio_por_dia: number
        }
        Update: {
          id_sucursal?: number
          id_tarifa?: number
          id_tipo?: number
          porcentaje_recargo?: number
          precio_por_dia?: number
        }
        Relationships: [
          {
            foreignKeyName: "fk_tarifa_sucursal"
            columns: ["id_sucursal"]
            isOneToOne: false
            referencedRelation: "sucursal"
            referencedColumns: ["id_sucursal"]
          },
          {
            foreignKeyName: "fk_tarifa_tipo"
            columns: ["id_tipo"]
            isOneToOne: false
            referencedRelation: "tipo_vehiculo"
            referencedColumns: ["id_tipo"]
          },
        ]
      }
      tipo_reserva: {
        Row: {
          antelacion_max_dias: number
          descripcion: string | null
          id_tipo_reserva: number
          nombre: string
          requiere_garantia: boolean
        }
        Insert: {
          antelacion_max_dias?: number
          descripcion?: string | null
          id_tipo_reserva?: number
          nombre: string
          requiere_garantia?: boolean
        }
        Update: {
          antelacion_max_dias?: number
          descripcion?: string | null
          id_tipo_reserva?: number
          nombre?: string
          requiere_garantia?: boolean
        }
        Relationships: []
      }
      tipo_vehiculo: {
        Row: {
          descripcion: string | null
          id_tipo: number
          nombre: string
        }
        Insert: {
          descripcion?: string | null
          id_tipo?: number
          nombre: string
        }
        Update: {
          descripcion?: string | null
          id_tipo?: number
          nombre?: string
        }
        Relationships: []
      }
      ubicacion_vehiculo: {
        Row: {
          fecha_desde: string
          fecha_hasta: string | null
          id_sucursal: number
          id_ubicacion: number
          id_vehiculo: number
        }
        Insert: {
          fecha_desde: string
          fecha_hasta?: string | null
          id_sucursal: number
          id_ubicacion?: number
          id_vehiculo: number
        }
        Update: {
          fecha_desde?: string
          fecha_hasta?: string | null
          id_sucursal?: number
          id_ubicacion?: number
          id_vehiculo?: number
        }
        Relationships: [
          {
            foreignKeyName: "fk_ubicacion_vehiculo_sucursal"
            columns: ["id_sucursal"]
            isOneToOne: false
            referencedRelation: "sucursal"
            referencedColumns: ["id_sucursal"]
          },
          {
            foreignKeyName: "fk_ubicacion_vehiculo_vehiculo"
            columns: ["id_vehiculo"]
            isOneToOne: false
            referencedRelation: "vehiculo"
            referencedColumns: ["id_vehiculo"]
          },
        ]
      }
      usuario: {
        Row: {
          created_at: string
          email: string
          id_usuario: number
          username: string
        }
        Insert: {
          created_at?: string
          email: string
          id_usuario?: number
          username: string
        }
        Update: {
          created_at?: string
          email?: string
          id_usuario?: number
          username?: string
        }
        Relationships: []
      }
      vehiculo: {
        Row: {
          anio: number
          detalle_confort: string | null
          id_estado: number
          id_sucursal_origen: number
          id_tipo: number
          id_vehiculo: number
          km_actuales: number
          marca: string
          modelo: string
          patente: string
        }
        Insert: {
          anio: number
          detalle_confort?: string | null
          id_estado: number
          id_sucursal_origen: number
          id_tipo: number
          id_vehiculo?: number
          km_actuales?: number
          marca: string
          modelo: string
          patente: string
        }
        Update: {
          anio?: number
          detalle_confort?: string | null
          id_estado?: number
          id_sucursal_origen?: number
          id_tipo?: number
          id_vehiculo?: number
          km_actuales?: number
          marca?: string
          modelo?: string
          patente?: string
        }
        Relationships: [
          {
            foreignKeyName: "fk_vehiculo_estado"
            columns: ["id_estado"]
            isOneToOne: false
            referencedRelation: "estado_vehiculo"
            referencedColumns: ["id_estado"]
          },
          {
            foreignKeyName: "fk_vehiculo_sucursal"
            columns: ["id_sucursal_origen"]
            isOneToOne: false
            referencedRelation: "sucursal"
            referencedColumns: ["id_sucursal"]
          },
          {
            foreignKeyName: "fk_vehiculo_tipo"
            columns: ["id_tipo"]
            isOneToOne: false
            referencedRelation: "tipo_vehiculo"
            referencedColumns: ["id_tipo"]
          },
        ]
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      fn_auth_uid: { Args: never; Returns: string }
      fn_calcular_factura: { Args: { p_id_alquiler: number }; Returns: number }
      fn_cliente_del_usuario: { Args: never; Returns: number }
      fn_es_staff: { Args: never; Returns: boolean }
      fn_validar_cliente_activo: {
        Args: { p_id_cliente: number }
        Returns: undefined
      }
      fn_validar_periodo: {
        Args: { p_fin: string; p_inicio: string; p_tolerancia_pasado?: string }
        Returns: undefined
      }
      fn_validar_vehiculo_operativo: {
        Args: { p_id_vehiculo: number }
        Returns: undefined
      }
      pa_actualizar_vehiculo: {
        Args: {
          p_anio: number
          p_detalle_confort: string
          p_id_vehiculo: number
          p_marca: string
          p_modelo: string
        }
        Returns: Record<string, unknown>
      }
      pa_baja_vehiculo: {
        Args: { p_id_vehiculo: number; p_motivo: string }
        Returns: Record<string, unknown>
      }
      pa_cancelar_reserva: {
        Args: { p_id_reserva: number; p_motivo: string }
        Returns: Record<string, unknown>
      }
      pa_crear_vehiculo: {
        Args: {
          p_anio: number
          p_detalle_confort: string
          p_id_sucursal_origen: number
          p_id_tipo: number
          p_km_actuales: number
          p_marca: string
          p_modelo: string
          p_patente: string
        }
        Returns: Record<string, unknown>
      }
      pa_enviar_mantenimiento_programado: {
        Args: {
          p_id_taller: number
          p_id_vehiculo: number
          p_observaciones: string
        }
        Returns: Record<string, unknown>
      }
      pa_finalizar_alquiler: {
        Args: {
          p_estado_destino_vehiculo: string
          p_id_alquiler: number
          p_id_sucursal_devolucion: number
          p_id_taller: number
          p_km_fin: number
          p_observaciones: string
        }
        Returns: Record<string, unknown>
      }
      pa_registrar_alquiler: {
        Args: {
          p_fecha_fin: string
          p_fecha_inicio: string
          p_id_cliente: number
          p_id_reserva: number
          p_id_tarifa: number
          p_id_vehiculo: number
          p_km_inicio: number
        }
        Returns: Record<string, unknown>
      }
      pa_registrar_cliente_con_usuario: {
        Args: {
          p_apellido: string
          p_direccion: string
          p_dni: string
          p_email: string
          p_nombre: string
          p_telefono: string
          p_username: string
        }
        Returns: Record<string, unknown>
      }
      pa_registrar_devolucion_mantenimiento: {
        Args: { p_id_vehiculo: number; p_km_salida_taller: number }
        Returns: Record<string, unknown>
      }
      pa_registrar_reserva: {
        Args: {
          p_fecha_fin: string
          p_fecha_inicio: string
          p_id_cliente: number
          p_id_tipo_reserva: number
          p_id_vehiculo: number
        }
        Returns: Record<string, unknown>
      }
    }
    Enums: {
      [_ in never]: never
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

type DatabaseWithoutInternals = Omit<Database, "__InternalSupabase">

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] &
        DefaultSchema["Views"])
    ? (DefaultSchema["Tables"] &
        DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
        Row: infer R
      }
      ? R
      : never
    : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Insert: infer I
      }
      ? I
      : never
    : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never,
> = DefaultSchemaTableNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
    ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
        Update: infer U
      }
      ? U
      : never
    : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never = never,
> = DefaultSchemaEnumNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
    ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
    : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never = never,
> = PublicCompositeTypeNameOrOptions extends {
  schema: keyof DatabaseWithoutInternals
}
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
    ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
    : never

export const Constants = {
  public: {
    Enums: {},
  },
} as const

// -----------------------------------------------------------------------------
// Aliases ergonomicos (Row de cada tabla auditada / consultada por UI).
// No los regenera supabase gen types — mantener manual al sumar tablas nuevas.
// -----------------------------------------------------------------------------

export type AuditLog =
  Database["public"]["Tables"]["audit_log"]["Row"]
export type Cliente =
  Database["public"]["Tables"]["cliente"]["Row"]
export type Vehiculo =
  Database["public"]["Tables"]["vehiculo"]["Row"]
export type Reserva =
  Database["public"]["Tables"]["reserva"]["Row"]
export type Alquiler =
  Database["public"]["Tables"]["alquiler"]["Row"]
export type Factura =
  Database["public"]["Tables"]["factura"]["Row"]
export type DevolucionVencida =
  Database["public"]["Tables"]["devolucion_vencida"]["Row"]
export type Sucursal =
  Database["public"]["Tables"]["sucursal"]["Row"]
export type TipoVehiculo =
  Database["public"]["Tables"]["tipo_vehiculo"]["Row"]
export type TipoReserva =
  Database["public"]["Tables"]["tipo_reserva"]["Row"]
export type EstadoVehiculo =
  Database["public"]["Tables"]["estado_vehiculo"]["Row"]
export type ImagenVehiculo =
  Database["public"]["Tables"]["imagen_vehiculo"]["Row"]
export type Tarifa =
  Database["public"]["Tables"]["tarifa"]["Row"]
export type Taller =
  Database["public"]["Tables"]["taller"]["Row"]
export type Mantenimiento =
  Database["public"]["Tables"]["mantenimiento"]["Row"]
export type Usuario =
  Database["public"]["Tables"]["usuario"]["Row"]
export type HistorialEstadoVehiculo =
  Database["public"]["Tables"]["historial_estado_vehiculo"]["Row"]
export type UbicacionVehiculo =
  Database["public"]["Tables"]["ubicacion_vehiculo"]["Row"]
export type GarantiaReserva =
  Database["public"]["Tables"]["garantia_reserva"]["Row"]
