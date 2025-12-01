"use client";
import { useState } from 'react';

export default function FAQ() {
  const faqs = [
    { q: 'Comment accepter Flooz ?', a: 'Contactez notre équipe pour activer Flooz.' },
    { q: 'Puis-je tester gratuitement ?', a: 'Oui, demandez une démo gratuite.' },
  ];
  const [open, setOpen] = useState<number | null>(null);

  return (
    <div className="space-y-2">
      {faqs.map((f, i) => (
        <div key={f.q} className="border rounded">
          <button className="w-full text-left p-3" onClick={() => setOpen(open === i ? null : i)}>
            {f.q}
          </button>
          {open === i && <div className="p-3 border-t">{f.a}</div>}
        </div>
      ))}
    </div>
  );
}
