// components/Hero.tsx (Inspiré : Headline, Sub, CTA, Trust)
"use client";

import { Button } from '@/components/ui/button';
import { Sparkles, ShieldCheck, ArrowUpRight } from 'lucide-react';
import Link from 'next/link';

export default function Hero() {
  return (
    <section className="relative overflow-hidden bg-slate-950 text-white">
      <div className="absolute inset-0 opacity-60 bg-[radial-gradient(circle_at_20%_20%,#1ec2a3,transparent_25%),radial-gradient(circle_at_80%_0%,#2b7cff,transparent_22%),radial-gradient(circle_at_60%_70%,#0ea5e9,transparent_25%)]" />
      <div className="absolute inset-x-0 top-0 h-20 bg-gradient-to-b from-slate-900/80 to-transparent" />
      <div className="relative max-w-6xl mx-auto px-6 py-20 md:py-24">
        <div className="inline-flex items-center gap-2 rounded-full bg-white/10 px-3 py-1 text-sm backdrop-blur">
          <Sparkles className="h-4 w-4 text-emerald-300" />
          <span>Adapté aux hôtels togolais — Mobile Money natif</span>
        </div>
        <div className="mt-6 grid gap-10 lg:grid-cols-[1.2fr_0.8fr] lg:items-center">
          <div>
            <h1 className="text-4xl md:text-6xl font-semibold leading-tight tracking-tight">
              HotelFlow Pro : pilotez vos réservations, paiements et opérations depuis une seule interface.
            </h1>
            <p className="mt-6 text-lg text-slate-200">
              HotelFlow Pro centralise planning, encaissements Flooz/T-Money, pricing dynamique et housekeeping pour remplir vos chambres et réduire les no-shows.
            </p>
            <div className="mt-8 flex flex-wrap items-center gap-4">
              <Button size="lg" asChild className="bg-emerald-400 text-slate-900 hover:bg-emerald-300">
                <Link href="/demo">Demander une démo gratuite</Link>
              </Button>
              <Button size="lg" variant="outline" asChild className="border-emerald-200 text-white hover:bg-white/10">
                <Link href="/pricing" className="flex items-center gap-2">
                  Voir les tarifs
                  <ArrowUpRight className="h-4 w-4" />
                </Link>
              </Button>
            </div>
            <div className="mt-6 flex flex-wrap gap-4 text-sm text-slate-200">
              <div className="flex items-center gap-2 rounded-full bg-white/10 px-3 py-2">
                <ShieldCheck className="h-4 w-4 text-emerald-300" />
                Sécurité + conformité DGT/RGPD
              </div>
              <div className="rounded-full bg-white/10 px-3 py-2">Support local 7j/7</div>
              <div className="rounded-full bg-white/10 px-3 py-2">Mise en ligne en 30 jours</div>
            </div>
          </div>
          <div className="grid gap-4">
            <div className="rounded-2xl border border-white/10 bg-white/5 p-5 shadow-2xl backdrop-blur">
              <p className="text-sm uppercase tracking-[0.12em] text-emerald-200">Occupations en direct</p>
              <div className="mt-3 grid grid-cols-3 gap-3 text-center">
                <Stat label="Taux d'occupation" value="88%" accent />
                <Stat label="ADR" value="54k FCFA" />
                <Stat label="RevPAR" value="47k FCFA" />
              </div>
              <div className="mt-5 h-2 rounded-full bg-white/10">
                <div className="h-2 w-[88%] rounded-full bg-gradient-to-r from-emerald-300 to-cyan-400" />
              </div>
            </div>
            <div className="rounded-2xl border border-white/10 bg-white/5 p-5 shadow-2xl backdrop-blur">
              <p className="text-sm uppercase tracking-[0.12em] text-emerald-200">Encaissements</p>
              <div className="mt-3 flex items-center justify-between text-lg font-semibold">
                <span>Flooz / T-Money</span>
                <span className="text-emerald-300">+34% vs. mois dernier</span>
              </div>
              <div className="mt-4 grid grid-cols-2 gap-3 text-sm">
                <Badge label="OTA sync" value="Booking · Airbnb · Expedia" />
                <Badge label="Chambres prêtes" value="22/25" />
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}

function Stat({ label, value, accent = false }: { label: string; value: string; accent?: boolean }) {
  return (
    <div className="rounded-xl border border-white/10 bg-white/5 px-3 py-4">
      <p className="text-xs text-slate-200">{label}</p>
      <p className={`text-2xl font-bold ${accent ? "text-emerald-300" : "text-white"}`}>{value}</p>
    </div>
  );
}

function Badge({ label, value }: { label: string; value: string }) {
  return (
    <div className="rounded-lg border border-white/10 bg-white/5 px-3 py-2 text-slate-200">
      <p className="text-[11px] uppercase tracking-[0.12em] text-emerald-200">{label}</p>
      <p className="mt-1 text-sm text-white">{value}</p>
    </div>
  );
}
