/**
 * Loading skeleton global.
 * Se muestra mientras los Server Components await sus queries.
 */
export default function Loading() {
  return (
    <div className="animate-pulse">
      <div className="h-9 w-72 bg-slate-200 rounded mb-2" />
      <div className="h-4 w-96 bg-slate-100 rounded mb-8" />

      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
        {Array.from({ length: 6 }).map((_, i) => (
          <div
            key={i}
            className="rounded-xl border border-slate-200 bg-white overflow-hidden"
          >
            <div className="h-48 bg-slate-100" />
            <div className="p-4 space-y-3">
              <div className="h-4 w-3/4 bg-slate-200 rounded" />
              <div className="h-3 w-1/2 bg-slate-100 rounded" />
              <div className="h-3 w-2/3 bg-slate-100 rounded" />
              <div className="flex items-center justify-between pt-2">
                <div className="h-6 w-20 bg-slate-200 rounded" />
                <div className="h-8 w-24 bg-brand-100 rounded-lg" />
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  )
}
