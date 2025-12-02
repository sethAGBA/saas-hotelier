"use client";

import { CalendarClock, KeyRound, SmartphoneNfc, Wallet, BarChart3, Sparkles, ShieldCheck, PlugZap, Bell, Users, Store, PieChart, WifiOff } from "lucide-react";

export default function Features() {
  const cards = [
    { title: 'Planning & réservations', desc: 'Gantt visuel, OTA sync, overbooking contrôlé et upgrades auto.', icon: CalendarClock },
    { title: 'Check-in/out', desc: 'Pré-checkin mobile, QR, clés connectées, kiosque libre-service.', icon: KeyRound },
    { title: 'Housekeeping & maintenance', desc: 'Tâches mobiles, photos avant/après, tickets urgents, offline.', icon: SmartphoneNfc },
    { title: 'Paiements & caisse', desc: 'Flooz / T-Money, CB, POS, split bill, folios multi-chambres.', icon: Wallet },
    { title: 'Revenue management', desc: 'Tarifs dynamiques, saisons, événements, coupons et packages.', icon: BarChart3 },
    { title: 'Site web & marketing', desc: 'Builder hôtel, SEO local, campagnes SMS/Email ciblées.', icon: Sparkles },
    { title: 'Sécurité & conformité', desc: 'Rôles, 2FA, journaux d’audit, sauvegardes, conformité DGT/RGPD.', icon: ShieldCheck },
    { title: 'API & intégrations', desc: 'Channel manager, paiements, exports comptables, webhooks, SDK.', icon: PlugZap },
    { title: 'Alertes & notifications', desc: 'No-show, encaissements, tickets maintenance, stocks et KPI en live.', icon: Bell },
    { title: 'CRM & fidélité', desc: 'Profil client, historique séjours, points, niveaux (Bronze/Silver/Gold), campagnes ciblées.', icon: Users },
    { title: 'POS & services', desc: 'Restaurant/bar, room service, spa, transferts, split check, folios multi-chambres.', icon: Store },
    { title: 'Reporting & BI', desc: 'RevPAR, ADR, no-show, cash/CB/Mobile Money, exports Excel/PDF, plan comptable.', icon: PieChart },
    { title: 'Offline & IoT', desc: 'Mode offline, resync, serrures connectées, thermostats, détecteurs, minibar intelligent.', icon: WifiOff },
  ];

  return (
    <section className="bg-white py-16 dark:bg-slate-950">
      <div className="max-w-6xl mx-auto px-6">
        <div className="flex flex-col gap-3 text-center">
          <p className="text-sm uppercase tracking-[0.2em] text-emerald-600 dark:text-emerald-300">Modules</p>
          <h2 className="text-3xl md:text-4xl font-semibold text-slate-900 dark:text-white">Tout-en-un pour vos équipes</h2>
          <p className="text-slate-600 dark:text-slate-300">Réception, direction, housekeeping, finance, marketing : chaque rôle a ses écrans et automatisations.</p>
        </div>
        <div className="mt-12 grid grid-cols-1 gap-6 md:grid-cols-2 lg:grid-cols-3">
          {cards.map(({ title, desc, icon: Icon }) => (
            <div
              key={title}
              className="rounded-2xl border border-slate-200/80 bg-gradient-to-br from-white to-slate-50 p-6 shadow-sm transition hover:-translate-y-1 hover:shadow-xl dark:border-slate-800 dark:from-slate-900 dark:to-slate-950"
            >
              <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-emerald-500/15 text-emerald-600 dark:text-emerald-300">
                <Icon className="h-6 w-6" />
              </div>
              <h3 className="mt-4 text-lg font-semibold text-slate-900 dark:text-white">{title}</h3>
              <p className="mt-2 text-sm text-slate-600 dark:text-slate-300">{desc}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
