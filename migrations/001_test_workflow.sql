-- Migracion de prueba para verificar el CI de GitHub Actions
-- Eliminar esta tabla despues de confirmar que el CI funciona

CREATE TABLE IF NOT EXISTS test_workflow (
    id SERIAL PRIMARY KEY,
    mensaje TEXT NOT NULL DEFAULT 'CI funciona!',
    creado_en TIMESTAMP NOT NULL DEFAULT NOW()
);

INSERT INTO test_workflow (mensaje) VALUES ('Deploy automatico desde GitHub Actions');
