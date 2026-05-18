# Frontend — TBD TFI 2026 (PoC)

Frontend Next.js 14 del sistema de alquiler de vehículos. Se comunica directamente con Supabase (PostgREST + GoTrue) sin backend intermedio.

## Pre-requisitos

| Herramienta | Versión | Instrucciones |
|-------------|---------|---------------|
| **Docker** | 24+ | https://docs.docker.com/get-docker/ |
| **Supabase CLI** | 1.200+ | `brew install supabase/tap/supabase` |
| **bun** | 1.1+ | `curl -fsSL https://bun.sh/install \| bash` o `mise use bun@latest` |
| **Node.js** | 20+ | `mise use node@20` |

## Arrancar en desarrollo

Desde la **raíz del repo** (no desde `frontend/`):

```bash
bash scripts/dev-frontend.sh
```

El script:
1. Verifica que supabase CLI, bun y docker estén instalados.
2. Levanta el stack BaaS local (`supabase start`).
3. Aplica el schema del repo a la base local (`scripts/apply.sh`).
4. Imprime las URLs y keys, y te ofrece crear `frontend/.env.local` automáticamente.
5. Corre `bun install` y `bun dev` en `frontend/`.

La app queda disponible en `http://localhost:3000`.

### Configurar .env.local manualmente

```bash
cp frontend/env.local.example frontend/.env.local
# Completar con los valores de `supabase status`
```

Contenido:

```env
NEXT_PUBLIC_SUPABASE_URL=http://127.0.0.1:54321
NEXT_PUBLIC_SUPABASE_ANON_KEY=<anon-key de supabase status>
```

## Regenerar tipos TypeScript desde el schema

Una vez que el stack local está corriendo:

```bash
# Desde la raíz del repo
supabase gen types typescript --local > frontend/types/database.ts
```

Esto reemplaza el stub manual con los tipos exactos generados desde el schema PostgreSQL.

## Apuntar a Supabase Cloud

1. Creá un proyecto en https://supabase.com y aplicá el schema:
   ```bash
   DATABASE_URL="<connection-string-cloud>" bash scripts/apply.sh
   ```
2. Editá `frontend/.env.local`:
   ```env
   NEXT_PUBLIC_SUPABASE_URL=https://<tu-proyecto>.supabase.co
   NEXT_PUBLIC_SUPABASE_ANON_KEY=<anon-key del dashboard>
   ```
3. `bun dev` desde `frontend/`.

## Correr con Docker (standalone)

```bash
# Desde frontend/
docker build \
  --build-arg NEXT_PUBLIC_SUPABASE_URL=<url> \
  --build-arg NEXT_PUBLIC_SUPABASE_ANON_KEY=<key> \
  -t tbd-tfi-frontend .

docker run -p 3000:3000 tbd-tfi-frontend
```

> Las variables `NEXT_PUBLIC_*` se incrustran en el bundle en build time (limitación de Next.js). Si cambian URL o key, hay que rebuildar la imagen.

## Estructura del frontend

```
frontend/
├── app/
│   ├── layout.tsx                     # Layout root (Inter, Tailwind, Nav)
│   ├── page.tsx                       # Landing: grid de vehículos disponibles
│   ├── globals.css                    # Tailwind directives
│   ├── login/page.tsx                 # Login / signup (Client Component)
│   ├── mis-reservas/page.tsx          # Lista de reservas del cliente (Server Component)
│   └── reservar/[id_vehiculo]/page.tsx  # Formulario de reserva (Server + Client)
├── components/
│   ├── VehiculoCard.tsx               # Card presentacional (imagen, tarifa, CTA)
│   ├── ReservaForm.tsx                # Form datepicker + tipo_reserva (Client Component)
│   ├── AuthButton.tsx                 # SignIn/Out con session listener (Client Component)
│   └── Nav.tsx                        # Header con links (Server Component)
├── lib/
│   └── supabase/
│       ├── client.ts                  # createBrowserClient (uso en Client Components)
│       ├── server.ts                  # createServerClient con cookies HttpOnly
│       └── middleware.ts              # refresh de sesión + redirect de rutas protegidas
├── types/
│   └── database.ts                    # Stub de tipos — regenerar con supabase gen types
├── middleware.ts                      # Entry point del middleware de Next.js
├── next.config.mjs                    # standalone output + remotePatterns GitHub raw
├── tsconfig.json                      # strict, paths @/*
├── tailwind.config.ts
├── postcss.config.mjs
├── Dockerfile                         # multi-stage: deps, builder, runner
└── package.json
```

## Páginas implementadas

| Ruta | Auth | Descripción |
|------|------|-------------|
| `/` | No requerida | Grid de vehículos con imagen, tipo y tarifa |
| `/login` | — | Tabs ingresar / crear cuenta |
| `/mis-reservas` | Requerida | Lista de reservas del cliente (filtrada por RLS) |
| `/reservar/[id]` | Requerida | Form para crear reserva con validación de solapamiento |
