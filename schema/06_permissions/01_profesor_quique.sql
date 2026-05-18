-- Rol de evaluacion para el profesor Ing. Enrique "quique" Barreyro.
--
-- Permisos expandidos: lectura, escritura, ejecucion de funciones/procedures
-- y creacion de objetos nuevos en public. Puede modificar el schema a su
-- criterio; la fuente de verdad es el repo y cualquier divergencia se rehace
-- en el siguiente apply.sh (DROP SCHEMA public CASCADE + recreate).
--
-- Idempotente:
--   * El rol es cluster-level y persiste entre rebuilds; el bloque DO chequea
--     pg_roles antes de crearlo.
--   * Los GRANT y ALTER DEFAULT PRIVILEGES son seguros de reaplicar.
--
-- Cambiar la password antes de compartir credenciales reales fuera del aula.

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'quique') THEN
        CREATE ROLE quique LOGIN PASSWORD 'tbd-quique-2026';
    ELSE
        ALTER ROLE quique LOGIN PASSWORD 'tbd-quique-2026';
    END IF;
END
$$;

-- Conexion a la base actual (nombre resuelto en runtime para portabilidad
-- entre entornos: docker local, supabase, CI).
DO $$
BEGIN
    EXECUTE format('GRANT CONNECT ON DATABASE %I TO quique', current_database());
END
$$;

-- Schema public: uso + creacion de objetos nuevos.
GRANT USAGE, CREATE ON SCHEMA public TO quique;

-- Acceso total sobre los objetos existentes en public.
GRANT ALL PRIVILEGES ON ALL TABLES    IN SCHEMA public TO quique;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO quique;
GRANT EXECUTE        ON ALL FUNCTIONS IN SCHEMA public TO quique;
GRANT EXECUTE        ON ALL PROCEDURES IN SCHEMA public TO quique;

-- Default privileges: objetos que cree el rol postgres (apply.sh) en futuras
-- ejecuciones quedan accesibles para quique sin reaplicar grants manuales.
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT ALL ON TABLES    TO quique;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT ALL ON SEQUENCES TO quique;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT EXECUTE ON FUNCTIONS TO quique;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT EXECUTE ON ROUTINES  TO quique;
