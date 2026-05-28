-- Disparador AFTER INSERT en auth.users de Supabase que crea automaticamente
-- la fila correspondiente en cliente. Patron estandar de Supabase para vincular
-- identidades de Auth con el modelo de dominio.
--
-- Datos del cliente:
--   * auth_user_id = NEW.id (UUID)
--   * nombre / apellido / dni / telefono: leidos de raw_user_meta_data si la
--     aplicacion cliente los envia en el registro; sino quedan como valores
--     provisorios editables luego.
--   * El DNI provisorio usa el UUID truncado para garantizar UNIQUE entre
--     registros sin colisiones. El cliente lo completa al editar su perfil.
--
-- Si el esquema auth no existe (entorno docker postgres puro sin Supabase),
-- el CREATE TRIGGER falla silenciosamente via DO block + EXCEPTION.

CREATE OR REPLACE FUNCTION fn_handle_new_auth_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_nombre    TEXT := COALESCE(NEW.raw_user_meta_data ->> 'nombre',   'Pendiente');
    v_apellido  TEXT := COALESCE(NEW.raw_user_meta_data ->> 'apellido', 'Pendiente');
    v_dni       TEXT := COALESCE(
        NEW.raw_user_meta_data ->> 'dni',
        LEFT('TMP-' || REPLACE(NEW.id::TEXT, '-', ''), 20)
    );
    v_telefono  TEXT := NEW.raw_user_meta_data ->> 'telefono';
    v_direccion TEXT := NEW.raw_user_meta_data ->> 'direccion';
BEGIN
    INSERT INTO public.cliente (auth_user_id, nombre, apellido, dni, telefono, direccion)
    VALUES (NEW.id, v_nombre, v_apellido, v_dni, v_telefono, v_direccion)
    ON CONFLICT (auth_user_id) DO NOTHING;

    RETURN NEW;
END;
$$;

-- Registrar el disparador solo si el esquema auth existe (entorno Supabase).
-- En entornos sin auth (docker puro de la materia) la base sigue funcional;
-- el cliente se crea manualmente via datos iniciales o INSERT directo.
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_namespace WHERE nspname = 'auth') THEN
        DROP TRIGGER IF EXISTS trg_on_auth_user_created ON auth.users;
        EXECUTE 'CREATE TRIGGER trg_on_auth_user_created
                 AFTER INSERT ON auth.users
                 FOR EACH ROW
                 EXECUTE FUNCTION public.fn_handle_new_auth_user()';
    END IF;
END
$$;
