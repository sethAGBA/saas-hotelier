"use client";
import { useState } from 'react';
import { Quote, Star, ArrowLeft, ArrowRight } from 'lucide-react';

const items = [
  {
    id: 1,
    author: 'Hôtel Soleil',
    role: 'Lomé · 42 chambres',
    text: 'HotelFlow Pro a augmenté notre RevPAR et réduit les no-shows. Les encaissements Mobile Money sont fluides et la direction a un reporting clair.',
    kpi: '+18% RevPAR en 2 mois',
    rating: 5,
  },
  {
    id: 2,
    author: 'Lodge Lomé',
    role: 'Kpalimé · 18 chambres',
    text: 'Check-in mobile, housekeeping en temps réel, photos avant/après pour les chambres VIP : on gagne du temps et on maintient la qualité.',
    kpi: '-35% temps housekeeping',
    rating: 5,
  },
  {
    id: 3,
    author: 'Maison Kora',
    role: 'Atakpamé · 12 chambres',
    text: 'Onboarding express, site web prêt en 48h et synchronisation OTA sans surbooking. Support local réactif.',
    kpi: '+24% réservations directes',
    rating: 5,
  },
  {
    id: 4,
    author: 'Résidence Baobab',
    role: 'Lomé · 28 chambres',
    text: 'On a enfin une parité tarifaire propre et des exports comptables prêts pour le cabinet. Le channel manager évite les doublons.',
    kpi: '-60% erreurs d’inventaire',
    rating: 5,
  },
  {
    id: 5,
    author: 'Ecolodge Mono',
    role: 'Togoville · 9 chambres',
    text: 'Le mode offline et les paiements Mobile Money nous sauvent quand le réseau tombe. Check-in express sur tablette.',
    kpi: '-12 min par check-in',
    rating: 4,
  },
];

export default function Testimonials() {
  const [idx, setIdx] = useState(0);
  const current = items[idx];

  return (
    <section className="bg-slate-50 py-16 dark:bg-slate-900">
      <div className="max-w-5xl mx-auto px-6">
        <div className="flex items-center gap-3">
          <Quote className="h-8 w-8 text-emerald-500" />
          <div>
            <p className="text-sm uppercase tracking-[0.2em] text-emerald-600 dark:text-emerald-300">Ils utilisent HotelFlow Pro</p>
            <h2 className="text-3xl font-semibold text-slate-900 dark:text-white">La voix des hôteliers</h2>
          </div>
        </div>
        <div className="mt-8 rounded-3xl border border-slate-200/80 bg-white p-8 shadow-xl dark:border-slate-800 dark:bg-slate-950">
          <div className="flex flex-wrap items-center gap-3 text-sm text-slate-500 dark:text-slate-300">
            <div className="inline-flex items-center gap-1 rounded-full bg-emerald-400/15 px-3 py-1 text-emerald-700 dark:text-emerald-200">
              {current.kpi}
            </div>
            <div className="flex items-center gap-1">
              {Array.from({ length: current.rating }).map((_, i) => (
                <Star key={i} className="h-4 w-4 fill-amber-400 text-amber-400" />
              ))}
            </div>
          </div>
          <p className="mt-4 text-xl leading-relaxed text-slate-800 dark:text-slate-100">“{current.text}”</p>
          <div className="mt-4 text-sm text-slate-600 dark:text-slate-300">
            <span className="font-semibold text-slate-900 dark:text-white">{current.author}</span> — {current.role}
          </div>
          <div className="mt-6 flex items-center gap-3">
            <button
              className="inline-flex items-center gap-2 rounded-full border border-slate-200 px-4 py-2 text-sm transition hover:bg-slate-100 dark:border-slate-700 dark:hover:bg-slate-800"
              onClick={() => setIdx((idx - 1 + items.length) % items.length)}
            >
              <ArrowLeft className="h-4 w-4" /> Précédent
            </button>
            <button
              className="inline-flex items-center gap-2 rounded-full border border-slate-200 px-4 py-2 text-sm transition hover:bg-slate-100 dark:border-slate-700 dark:hover:bg-slate-800"
              onClick={() => setIdx((idx + 1) % items.length)}
            >
              Suivant <ArrowRight className="h-4 w-4" />
            </button>
            <div className="ml-auto flex items-center gap-2">
              {items.map((item, i) => (
                <span
                  key={item.id}
                  className={`h-2.5 w-2.5 rounded-full ${i === idx ? "bg-emerald-500" : "bg-slate-300 dark:bg-slate-600"}`}
                />
              ))}
            </div>
          </div>
          <div className="mt-6 grid grid-cols-1 gap-3 text-sm text-slate-600 dark:text-slate-200 md:grid-cols-3">
            <MiniStat label="Clients servis" value="120+" />
            <MiniStat label="Note moyenne" value="4.8/5" />
            <MiniStat label="Temps d’onboarding" value="30 jours" />
          </div>
        </div>
      </div>
    </section>
  );
}

function MiniStat({ label, value }: { label: string; value: string }) {
  return (
    <div className="rounded-xl border border-slate-200/80 bg-slate-50 p-3 text-center dark:border-slate-800 dark:bg-slate-900">
      <p className="text-xs uppercase tracking-[0.16em] text-emerald-600 dark:text-emerald-300">{label}</p>
      <p className="text-lg font-semibold text-slate-900 dark:text-white">{value}</p>
    </div>
  );
}
