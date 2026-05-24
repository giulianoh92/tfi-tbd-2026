export default function Loading() {
  return (
    <div className="animate-pulse">
      <div className="h-8 w-64 bg-slate-200 rounded mb-2" />
      <div className="h-4 w-96 bg-slate-100 rounded mb-6" />
      <div className="h-32 bg-slate-100 rounded-xl mb-6" />
      <div className="bg-white rounded-xl border border-slate-200 overflow-hidden">
        {Array.from({ length: 10 }).map((_, i) => (
          <div key={i} className="h-12 border-b border-slate-100 px-4 flex items-center gap-4">
            <div className="h-3 w-32 bg-slate-100 rounded" />
            <div className="h-3 w-16 bg-slate-200 rounded" />
            <div className="h-3 w-24 bg-slate-100 rounded" />
            <div className="h-3 w-20 bg-slate-100 rounded" />
          </div>
        ))}
      </div>
    </div>
  )
}
