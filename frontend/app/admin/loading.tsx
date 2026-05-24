/**
 * Loading skeleton del panel staff — matchea el layout sidebar + main.
 */
export default function AdminLoading() {
  return (
    <div className="animate-pulse">
      <div className="mb-6 h-12 rounded-lg bg-brand-staff-bg/60" />
      <div className="flex flex-col lg:flex-row gap-6">
        <aside className="lg:w-56 lg:shrink-0 space-y-2">
          {Array.from({ length: 6 }).map((_, i) => (
            <div key={i} className="h-9 rounded-lg bg-slate-100" />
          ))}
        </aside>
        <div className="flex-1 space-y-4">
          <div className="h-4 w-48 bg-slate-100 rounded" />
          <div className="h-8 w-72 bg-slate-200 rounded" />
          <div className="h-4 w-96 bg-slate-100 rounded mb-4" />
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
            {Array.from({ length: 6 }).map((_, i) => (
              <div
                key={i}
                className="rounded-xl border border-slate-200 bg-white p-6 space-y-3"
              >
                <div className="h-3 w-24 bg-slate-200 rounded" />
                <div className="h-10 w-16 bg-slate-200 rounded" />
                <div className="h-3 w-full bg-slate-100 rounded" />
                <div className="h-3 w-2/3 bg-slate-100 rounded" />
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  )
}
