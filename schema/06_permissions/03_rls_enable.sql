-- Habilita Row Level Security en todas las tablas de dominio.
-- IMPORTANTE: por defecto el rol postgres (propietario del esquema, usado por
-- apply.sh y por el rol quique con permisos explicitos) puede operar sin
-- restricciones; RLS solo aplica a roles SIN el atributo BYPASSRLS (los roles
-- authenticator/anon/authenticated de Supabase si lo respetan).
--
-- Idempotente: ENABLE ROW LEVEL SECURITY no falla si ya esta habilitado.

ALTER TABLE usuario                      ENABLE ROW LEVEL SECURITY;
ALTER TABLE cliente                      ENABLE ROW LEVEL SECURITY;
ALTER TABLE sucursal                     ENABLE ROW LEVEL SECURITY;
ALTER TABLE taller                       ENABLE ROW LEVEL SECURITY;
ALTER TABLE tipo_vehiculo                ENABLE ROW LEVEL SECURITY;
ALTER TABLE estado_vehiculo              ENABLE ROW LEVEL SECURITY;
ALTER TABLE tipo_reserva                 ENABLE ROW LEVEL SECURITY;
ALTER TABLE vehiculo                     ENABLE ROW LEVEL SECURITY;
ALTER TABLE imagen_vehiculo              ENABLE ROW LEVEL SECURITY;
ALTER TABLE ubicacion_vehiculo           ENABLE ROW LEVEL SECURITY;
ALTER TABLE historial_estado_vehiculo    ENABLE ROW LEVEL SECURITY;
ALTER TABLE tarifa                       ENABLE ROW LEVEL SECURITY;
ALTER TABLE reserva                      ENABLE ROW LEVEL SECURITY;
ALTER TABLE garantia_reserva             ENABLE ROW LEVEL SECURITY;
ALTER TABLE alquiler                     ENABLE ROW LEVEL SECURITY;
ALTER TABLE mantenimiento                ENABLE ROW LEVEL SECURITY;
ALTER TABLE factura                      ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_log                    ENABLE ROW LEVEL SECURITY;
ALTER TABLE devolucion_vencida           ENABLE ROW LEVEL SECURITY;
ALTER TABLE resumen_mensual_sucursal     ENABLE ROW LEVEL SECURITY;
