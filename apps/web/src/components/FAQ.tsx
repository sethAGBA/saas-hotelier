"use client";
import { useState } from 'react';
import { ChevronDown } from 'lucide-react';

export default function FAQ() {
  const faqs = [
    { q: 'Comment accepter Flooz / T-Money ?', a: 'Nous activons les passerelles Mobile Money lors de l’onboarding. Vous recevez les fonds directement sur votre compte marchand.' },
    { q: 'Puis-je tester gratuitement ?', a: 'Oui, démo guidée + essai gratuit, sans frais d’installation. Onboarding et support sont inclus dans les plans.' },
    { q: 'Comment fonctionne le channel manager ?', a: 'Synchronisation bidirectionnelle avec Booking.com, Airbnb, Expedia : disponibilités, tarifs et réservations en temps réel.' },
    { q: 'Et si internet tombe ?', a: 'Application offline : les actions critiques sont synchronisées dès le retour de la connexion (réservations, housekeeping, encaissements différés).' },
  ];
  const [open, setOpen] = useState<number | null>(null);

  return (
    <section className="bg-white py-16 dark:bg-slate-950">
      <div className="max-w-4xl mx-auto px-6">
        <div className="flex flex-col gap-2 text-center">
          <p className="text-sm uppercase tracking-[0.2em] text-emerald-600 dark:text-emerald-300">FAQ</p>
          <h2 className="text-3xl font-semibold text-slate-900 dark:text-white">Questions fréquentes</h2>
          <p className="text-slate-600 dark:text-slate-300">Pas de frais cachés, onboarding accompagné et support local.</p>
        </div>
        <div className="mt-10 space-y-3">
          {faqs.map((f, i) => (
            <div key={f.q} className="overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm transition hover:border-emerald-200 dark:border-slate-800 dark:bg-slate-900 dark:hover:border-emerald-500/40">
              <button
                className="flex w-full items-center justify-between px-4 py-4 text-left text-base font-semibold text-slate-900 dark:text-white"
                onClick={() => setOpen(open === i ? null : i)}
                aria-expanded={open === i}
              >
                {f.q}
                <ChevronDown
                  className={`h-5 w-5 transition-transform ${open === i ? "rotate-180 text-emerald-500" : "text-slate-500"}`}
                />
              </button>
              <div
                className={`px-4 pb-4 text-sm text-slate-600 transition-all duration-200 dark:text-slate-300 ${
                  open === i ? "max-h-40 opacity-100" : "max-h-0 opacity-0"
                }`}
              >
                {f.a}
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
