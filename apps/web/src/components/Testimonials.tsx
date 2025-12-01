"use client";
import { useState } from 'react';

export default function Testimonials() {
  const items = [
    { id: 1, author: 'Hôtel Soleil', text: 'TogoStay a transformé nos réservations.' },
    { id: 2, author: 'Lodge Lomé', text: 'Paiements Flooz parfaitement intégrés.' },
  ];
  const [idx, setIdx] = useState(0);

  return (
    <div className="p-6 border rounded">
      <p className="italic">“{items[idx].text}”</p>
      <p className="mt-3 font-semibold">— {items[idx].author}</p>
      <div className="mt-4 flex gap-2">
        <button className="px-3 py-1 border rounded" onClick={() => setIdx((idx - 1 + items.length) % items.length)}>Prev</button>
        <button className="px-3 py-1 border rounded" onClick={() => setIdx((idx + 1) % items.length)}>Next</button>
      </div>
    </div>
  );
}
