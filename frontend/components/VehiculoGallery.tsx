'use client'

import Image from 'next/image'
import { useState } from 'react'

interface VehiculoGalleryProps {
  alt: string
  images: { url_imagen: string; orden: number }[]
}

const PLACEHOLDER_URL =
  'https://raw.githubusercontent.com/giulianoh92/tfi-tbd-2026/main/assets/vehiculos/placeholder.jpg'

export function VehiculoGallery({ alt, images }: VehiculoGalleryProps) {
  const sorted = [...images].sort((a, b) => a.orden - b.orden)
  const sources = sorted.length > 0 ? sorted : [{ url_imagen: PLACEHOLDER_URL, orden: 1 }]
  const [active, setActive] = useState(0)
  const current = sources[active]

  return (
    <div className="flex flex-col gap-3">
      <div className="relative aspect-[16/10] bg-gray-100 rounded-xl overflow-hidden">
        <Image
          src={current.url_imagen}
          alt={alt}
          fill
          className="object-cover"
          sizes="(max-width: 1024px) 100vw, 60vw"
          priority
        />
      </div>

      {sources.length > 1 && (
        <div className="grid grid-cols-5 gap-2">
          {sources.map((img, idx) => (
            <button
              key={`${img.url_imagen}-${idx}`}
              type="button"
              onClick={() => setActive(idx)}
              className={`relative aspect-[16/10] rounded-lg overflow-hidden border-2 transition-all ${
                idx === active
                  ? 'border-blue-600 ring-2 ring-blue-200'
                  : 'border-transparent hover:border-gray-300'
              }`}
              aria-label={`Ver imagen ${idx + 1}`}
            >
              <Image
                src={img.url_imagen}
                alt={`${alt} - imagen ${idx + 1}`}
                fill
                className="object-cover"
                sizes="120px"
              />
            </button>
          ))}
        </div>
      )}
    </div>
  )
}
