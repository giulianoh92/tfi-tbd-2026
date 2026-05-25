-- Tabla general de auditoria (R1).
--
-- Una unica tabla para todas las entidades auditadas: simplifica triggers
-- (un solo fn_audit_generic), simplifica la interfaz de consulta y permite
-- filtrar por tabla via la columna `tabla`.
--
-- TRIPLE IDENTIDAD de usuario:
--
-- El requisito academico habla de "usuario que realizo la operacion". En un
-- modelo BaaS con Supabase eso se descompone en TRES facetas, cada una con
-- distinta resistencia a falsificacion. Las guardamos todas para tener
-- forensics real ante manipulacion de datos:
--
--   1) usuario_app  = sub del JWT de Supabase (UUID logico del end-user
--      en auth.users). Es la identidad humana detras de la operacion.
--      Anti-tampering por la firma del JWT con la project key. NULL para
--      operaciones sin sesion HTTP (psql directo, pg_cron, apply.sh).
--
--   2) usuario_db   = rol Postgres EFECTIVO tras `SET ROLE` segun JWT.
--      Tipico: authenticated, anon, service_role. Tambien quique o
--      postgres en sesiones psql directas. Lleva la semantica de
--      privilegios efectivamente aplicados (RLS, GRANTs).
--      Falsificable: un atacante con acceso al motor puede `SET ROLE x`
--      o setear la GUC request.jwt.claim.role para que el trigger lea
--      otro valor.
--
--   3) rol_sesion   = `session_user` crudo, el rol con el que se ABRIO
--      fisicamente la conexion al motor. En Supabase es siempre
--      'authenticator' para trafico via PostgREST (porque el pool abre
--      conexiones con ese rol y luego hace SET ROLE por request). En
--      conexiones directas es quique / postgres / etc.
--      NO falsificable sin re-autenticarse con credenciales validas a
--      Postgres: `SET ROLE` y los GUCs del JWT no afectan a
--      session_user, que queda fijado al login.
--
-- Combinatoria forensic util:
--   * rol_sesion='authenticator' + usuario_db='authenticated'     -> flujo normal Supabase
--   * rol_sesion='authenticator' + usuario_db='postgres'/'quique' -> SET ROLE manual sospechoso
--   * rol_sesion='quique'                                         -> profesor o algun rol con login propio
--   * rol_sesion='postgres'                                       -> apply.sh / pg_cron / acceso super
--   * usuario_app vinculado a JWT.sub inexistente en auth.users   -> JWT con sub fabricado
--
-- id_registro es TEXT porque las distintas tablas auditadas tienen PKs de
-- tipos distintos (BIGINT en general, pero queda abierto a UUID/etc).
-- Se serializa con ::text desde el trigger.
CREATE TABLE IF NOT EXISTS audit_log (
    id_audit           BIGSERIAL    PRIMARY KEY,
    tabla              TEXT         NOT NULL,
    id_registro        TEXT,
    tipo_op            CHAR(1)      NOT NULL,
    -- usuario_db: rol Postgres efectivo (puede manipularse via SET ROLE
    -- o GUC del JWT). Util para entender que politica RLS se aplico.
    usuario_db         TEXT         NOT NULL,
    -- rol_sesion: rol fisico que abrio la conexion al motor (no
    -- falsificable salvo re-login). Util para detectar manipulacion
    -- directa al motor vs flujo PostgREST normal.
    rol_sesion         TEXT         NOT NULL,
    -- usuario_app: identidad logica del end-user (JWT.sub). NULL para
    -- operaciones sin contexto HTTP/Auth.
    usuario_app        UUID,
    fecha_hora         TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    valores_anteriores JSONB,
    valores_nuevos     JSONB,
    CONSTRAINT chk_audit_tipo_op CHECK (tipo_op IN ('I', 'U', 'D'))
);
