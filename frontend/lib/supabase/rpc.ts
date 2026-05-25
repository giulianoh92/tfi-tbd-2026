import type { Database } from '@/types/database'

/**
 * Helper tipado para invocar Stored Procedures via `.rpc()`.
 *
 * Por que existe:
 *   En @supabase/supabase-js@2.106 la signatura `rpc<FnName, Args = never>(...)`
 *   tiene un default `Args = never` que rompe la inferencia: TS no logra
 *   inferir Args desde el literal y colapsa a `never`, lo cual hace que el
 *   segundo parametro quede tipado como `undefined`. Resultado: error TS2345
 *   "Argument of type {...} is not assignable to parameter of type undefined".
 *
 *   El cast `args as never` en el call site soluciona el problema, pero pierde
 *   type safety en el args. Este helper retiene el type-checking del args
 *   contra `Database['public']['Functions'][FnName]['Args']` y mete el cast
 *   adentro, donde queda contenido.
 *
 * Uso:
 *   const supabase = createClient()
 *   const { data, error } = await rpcCall(supabase, 'pa_cancelar_reserva', {
 *     p_id_reserva: 123,
 *     p_motivo: 'no necesito el auto',
 *   })
 *
 *   if (error) { ... }
 *   if (data?.p_estado !== 'OK') { ... }
 */

type Functions = Database['public']['Functions']
export type FnName = keyof Functions
export type FnArgs<F extends FnName> = Functions[F]['Args']
export type FnReturns<F extends FnName> = Functions[F]['Returns']

// Tipo del client: usamos `any` adrede para evitar acoplar al chain de
// generics complejos de SupabaseClient<Database, ...> que varia entre
// versiones. El type safety viene del segundo argumento `args: FnArgs<F>`,
// no del client. El cast interno a `never` ya elide la inferencia rota.
// eslint-disable-next-line @typescript-eslint/no-explicit-any
type RpcCapableClient = any

export interface RpcResult<F extends FnName> {
  data: FnReturns<F> | null
  error: { message: string; code?: string; details?: string } | null
}

/**
 * Invoca una funcion RPC con tipado estricto del args y casteo seguro del
 * literal a `never` para sortear la limitacion de inferencia.
 */
export async function rpcCall<F extends FnName>(
  client: RpcCapableClient,
  fn: F,
  args: FnArgs<F>
): Promise<RpcResult<F>> {
  // `args as never` evita TS2345 sin perder type safety: el parametro `args`
  // ya esta type-checked contra Functions[F]['Args'] arriba.
  const { data, error } = await client.rpc(fn, args as never)
  const err = error as
    | { message: string; code?: string; details?: string }
    | null
  return {
    data: (data as FnReturns<F>) ?? null,
    error: err
      ? { message: err.message, code: err.code, details: err.details }
      : null,
  }
}
