export default function Loading() {
  return (
    <div className="animate-pulse">
      <div className="h-8 w-60 bg-slate-200 rounded mb-2" />
      <div className="h-4 w-40 bg-slate-100 rounded mb-8" />
      <div className="bg-white rounded-xl border border-slate-200 overflow-hidden">
        {Array.from({ length: 8 }).map((_, i) => (
          <div key={i} className="h-16 border-b border-slate-100 px-5 flex items-center gap-4">
            <div className="h-4 w-32 bg-slate-200 rounded" />
            <div className="h-4 w-40 bg-slate-100 rounded" />
            <div className="h-4 w-24 bg-slate-100 rounded" />
            <div className="ml-auto h-7 w-20 bg-orange-100 rounded-lg" />
          </div>
        ))}
      </div>
    </div>
  )
}
