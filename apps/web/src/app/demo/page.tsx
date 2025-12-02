// app/demo/page.tsx
import DemoForm from '@/components/DemoForm';
import { Phone, CalendarClock, ShieldCheck } from 'lucide-react';

export default function Demo() {
  return (
    <main className="bg-slate-950 text-white">
      <div className="max-w-5xl mx-auto px-6 py-16">
        <div className="text-center space-y-4">
          <p className="text-sm uppercase tracking-[0.2em] text-emerald-200">Démo guidée</p>
          <h1 className="text-3xl md:text-4xl font-semibold">30 minutes avec un expert local</h1>
          <p className="text-slate-200">Un audit express de vos besoins, une démo live et un plan de mise en ligne en 30 jours.</p>
        </div>

        <div className="mt-12 grid gap-8 lg:grid-cols-[1.1fr_0.9fr]">
          <div className="rounded-3xl border border-white/10 bg-white/5 p-6 shadow-xl">
            <DemoForm />
          </div>
          <div className="rounded-3xl border border-white/10 bg-white/5 p-6 space-y-5">
            <h3 className="text-xl font-semibold">Ce que vous obtenez</h3>
            <Item icon={<CalendarClock className="h-5 w-5" />} title="Planning complet" desc="Walkthrough planning, OTA sync, check-in/out, housekeeping et paiements Flooz/T-Money." />
            <Item icon={<Phone className="h-5 w-5" />} title="Plan d’action 30 jours" desc="Paramétrage, import chambres/tarifs, formation réception & housekeeping." />
            <Item icon={<ShieldCheck className="h-5 w-5" />} title="Check sécurité & conformité" desc="TVA, facture locale, DGT/RGPD, sauvegardes et accès par rôle." />
            <div className="rounded-2xl border border-white/10 bg-white/5 p-4 text-sm text-slate-200">
              Besoin de parler tout de suite ? <a href="tel:+22890579946" className="text-emerald-200 underline">+228 90 57 99 46</a> ou WhatsApp.
            </div>
          </div>
        </div>
      </div>
    </main>
  );
}

function Item({ icon, title, desc }: { icon: React.ReactNode; title: string; desc: string }) {
  return (
    <div className="flex gap-3 rounded-2xl border border-white/5 bg-white/5 p-4">
      <div className="mt-1 flex h-10 w-10 items-center justify-center rounded-xl bg-emerald-400/15 text-emerald-200">
        {icon}
      </div>
      <div>
        <h4 className="text-base font-semibold text-white">{title}</h4>
        <p className="text-sm text-slate-200">{desc}</p>
      </div>
    </div>
  );
}
