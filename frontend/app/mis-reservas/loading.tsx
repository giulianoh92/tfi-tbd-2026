export default function Loading() {
  return (
    <div className="animate-pulse">
      <div className="h-8 w-48 bg-slate-200 rounded mb-2" />
      <div className="h-4 w-64 bg-slate-100 rounded mb-8" />
      <div className="space-y-4">
        {Array.from({ length: 3 }).map((_, i) => (
          <div key={i} className="rounded-xl border border-slate-200 bg-white p-5 space-y-3">
            <div className="flex items-center justify-between">
              <div className="h-4 w-40 bg-slate-200 rounded" />
              <div className="h-5 w-20 bg-slate-100 rounded-full" />
            </div>
            <div className="grid grid-cols-3 gap-3">
              <div className="h-3 bg-slate-100 rounded" />
              <div className="h-3 bg-slate-100 rounded" />
              <div className="h-3 bg-slate-100 rounded" />
            </div>
          </div>
        ))}
      </div>
    </div>
  )
}
